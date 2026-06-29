#!/usr/bin/env python3
"""
analyze-performance-traces.py
NextSeason

Parses xctrace .trace files from profile-performance-suite.sh and emits JSON + markdown.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET

NS = {"t": "http://www.apple.com/Instruments/TraceToc"}


@dataclass
class FlowMetrics:
    name: str
    runs: int = 0
    wall_clock_ms: list[float] = field(default_factory=list)
    ttff_ms: list[float] = field(default_factory=list)
    peak_memory_mb: list[float] = field(default_factory=list)
    idle_memory_mb: list[float] = field(default_factory=list)
    baseline_memory_mb: list[float] = field(default_factory=list)
    hangs_over_100ms: list[int] = field(default_factory=list)
    leaks: list[int] = field(default_factory=list)
    top_cpu: Counter = field(default_factory=Counter)
    retained_types: Counter = field(default_factory=Counter)
    network_requests: list[dict[str, Any]] = field(default_factory=list)
    console_issues: list[str] = field(default_factory=list)

    def pass_fail(self) -> str:
        if any(l > 0 for l in self.leaks):
            return "FAIL"
        if self.retained_types and any(
            t for t in self.retained_types if "ViewModel" in t or "View" in t
        ):
            return "WARN"
        if self.peak_memory_mb and max(self.peak_memory_mb) > 250:
            return "WARN"
        if any(h > 0 for h in self.hangs_over_100ms):
            return "WARN"
        return "PASS"


def export_trace(trace: Path, xpath: str | None = None, har: bool = False) -> str:
    cmd = ["xcrun", "xctrace", "export", "--input", str(trace)]
    if har:
        cmd.append("--har")
    elif xpath:
        cmd.extend(["--xpath", xpath])
    else:
        cmd.append("--toc")
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        return ""


def export_table(trace: Path, schema: str) -> str:
    return export_trace(
        trace,
        f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]',
    )


def parse_durations(xml: str) -> dict[str, int]:
    return {
        m.group(1): int(m.group(3))
        for m in re.finditer(
            r'<duration id="(\d+)" fmt="([^"]*)"[^>]*>(\d+)</duration>', xml
        )
    }


def parse_ttff(lifecycle_xml: str) -> float | None:
    for row in re.findall(r"<row>(.*?)</row>", lifecycle_xml, re.S):
        if "Initial Frame Rendering" not in row:
            continue
        start = re.search(r"<start-time[^>]*>(\d+)</start-time>", row)
        dur = re.search(r'<duration id="\d+" fmt="[^"]*"[^>]*>(\d+)</duration>', row)
        if start and dur:
            return (int(start.group(1)) + int(dur.group(1))) / 1e6
    return None


def parse_signpost_intervals(signpost_xml: str) -> dict[str, list[float]]:
    """Returns signpost name -> list of durations in ms (Begin/End pairs)."""
    intervals: dict[str, list[float]] = defaultdict(list)
    if not signpost_xml:
        return intervals

    open_starts: dict[str, dict[str, int]] = defaultdict(dict)

    for row in re.findall(r"<row>(.*?)</row>", signpost_xml, re.S):
        if "NextSeason" not in row and "PointsOfInterest" not in row:
            continue
        name_m = re.search(r'<signpost-name[^>]*fmt="([^"]*)"', row)
        type_m = re.search(r'<event-type[^>]*fmt="([^"]*)"', row)
        time_m = re.search(r"<event-time[^>]*>(\d+)</event-time>", row)
        id_m = re.search(r"<os-signpost-identifier[^>]*>(\d+)</os-signpost-identifier>", row)
        if not name_m or not type_m or not time_m:
            continue
        name = name_m.group(1)
        event_type = type_m.group(1)
        t = int(time_m.group(1))
        signpost_id = id_m.group(1) if id_m else name

        if event_type == "Begin":
            open_starts[name][signpost_id] = t
        elif event_type == "End" and signpost_id in open_starts[name]:
            start = open_starts[name].pop(signpost_id)
            intervals[name].append((t - start) / 1e6)

    return intervals


def parse_memory_samples(trace: Path) -> tuple[float | None, float | None, float | None]:
    """Returns baseline_mb, peak_mb, idle_mb from Activity Monitor live samples."""
    xml = export_table(trace, "activity-monitor-process-live")
    samples: list[tuple[int, float]] = []

    if xml:
        sizes = {
            m.group(1): int(m.group(2))
            for m in re.finditer(
                r'<size-in-bytes id="(\d+)" fmt="[^"]*"[^>]*>(\d+)</size-in-bytes>', xml
            )
        }
        process_id = None
        proc_m = re.search(r'<process id="(\d+)" fmt="NextSeason[^"]*"', xml)
        if proc_m:
            process_id = proc_m.group(1)

        def row_footprint(row: str) -> float | None:
            vals: list[int] = []
            for m in re.finditer(r"<size-in-bytes[^>]*/>", row):
                tag = m.group(0)
                inline = re.search(r">(\d+)<", tag)
                ref = re.search(r'ref="(\d+)"', tag)
                if inline:
                    vals.append(int(inline.group(1)))
                elif ref and ref.group(1) in sizes:
                    vals.append(sizes[ref.group(1)])
            return vals[0] / (1024 * 1024) if vals else None

        for row in re.findall(r"<row>(.*?)</row>", xml, re.S):
            if process_id and f'<process ref="{process_id}"/>' not in row and "NextSeason" not in row:
                continue
            time_m = re.search(r"<start-time[^>]*>(\d+)</start-time>", row)
            footprint = row_footprint(row)
            if footprint is None or footprint < 1.0:
                continue
            t = int(time_m.group(1)) if time_m else len(samples)
            samples.append((t, footprint))

    if not samples:
        for schema in ("global-daily-footprint", "physical-footprint", "memory-statistics"):
            alt = export_table(trace, schema)
            if not alt:
                continue
            for row in re.findall(r"<row>(.*?)</row>", alt, re.S):
                val_m = re.search(r"<size-in-bytes[^>]*>(\d+)</size-in-bytes>", row)
                if val_m:
                    samples.append((len(samples), int(val_m.group(1)) / (1024 * 1024)))

    if not samples:
        return None, None, None

    samples.sort(key=lambda x: x[0])
    values = [v for _, v in samples]
    return values[0], max(values), values[-1]


def parse_roi_duration(signpost_xml: str, signpost_name: str) -> float | None:
    if not signpost_xml or not signpost_name:
        return None
    for row in re.findall(r"<row>(.*?)</row>", signpost_xml, re.S):
        if signpost_name not in row or "NextSeason" not in row:
            continue
        name_m = re.search(r'<signpost-name[^>]*fmt="([^"]*)"', row)
        dur_m = re.search(r'<duration id="\d+" fmt="[^"]*"[^>]*>(\d+)</duration>', row)
        if name_m and name_m.group(1) == signpost_name and dur_m:
            return int(dur_m.group(1)) / 1e6
    return None


def parse_hangs(trace: Path, threshold_ms: float = 100) -> int:
    count = 0
    for schema in ("potential-hangs", "hang-risks", "hitches"):
        xml = export_table(trace, schema)
        dur_map = parse_durations(xml)
        for row in re.findall(r"<row>(.*?)</row>", xml, re.S):
            if "NextSeason" not in row:
                continue
            ref = re.search(r'<duration ref="(\d+)"/>', row)
            inline = re.search(r'<duration id="\d+" fmt="[^"]*"[^>]*>(\d+)</duration>', row)
            ns = None
            if ref:
                ns = dur_map.get(ref.group(1))
            elif inline:
                ns = int(inline.group(1))
            if ns and ns / 1e6 >= threshold_ms:
                count += 1
    return count


def parse_leaks(trace: Path) -> int:
    xml = export_table(trace, "leaks")
    if not xml:
        xml = export_table(trace, "leak")
    rows = re.findall(r"<row>(.*?)</row>", xml, re.S)
    return len(rows)


def parse_retained_view_models(trace: Path) -> Counter:
    """Heuristic: count live allocations matching View/ViewModel type names."""
    counts: Counter = Counter()
    for schema in ("live-allocations", "all-allocations", "malloc-type-summary"):
        xml = export_table(trace, schema)
        if not xml:
            continue
        for pattern in (
            r"SearchViewModel",
            r"ShowDetailViewModel",
            r"WatchlistViewModel",
            r"ShowDetailView",
            r"SearchView",
        ):
            matches = len(re.findall(pattern, xml))
            if matches:
                counts[pattern] += matches
    return counts


def parse_cpu(trace: Path, flow_start_ns: int | None = None, flow_end_ns: int | None = None) -> Counter:
    xml = export_table(trace, "time-profile")
    if not xml:
        return Counter()

    weights = {
        m.group(1): int(m.group(2))
        for m in re.finditer(r'<weight id="(\d+)" fmt="[^"]*"[^>]*>(\d+)</weight>', xml)
    }
    symbols: Counter = Counter()

    for row in re.findall(r"<row>(.*?)</row>", xml, re.S):
        inline = re.search(r'<weight id="\d+" fmt="[^"]*"[^>]*>(\d+)</weight>', row)
        ref = re.search(r'<weight ref="(\d+)"/>', row)
        if inline:
            w = int(inline.group(1))
        elif ref:
            w = weights.get(ref.group(1), 1_000_000)
        else:
            continue

        if flow_start_ns is not None and flow_end_ns is not None:
            tm = re.search(r"<sample-time[^>]*>(\d+)</sample-time>", row)
            if tm:
                t = int(tm.group(1))
                if not (flow_start_ns <= t <= flow_end_ns):
                    continue

        frames = re.findall(r'<frame id="\d+" name="([^"]*)"', row)
        sym = next((f for f in frames if not f.startswith("0x")), frames[0] if frames else None)
        if sym:
            symbols[sym] += w / 1e6

    return symbols


def parse_network_har(har_path: Path) -> list[dict[str, Any]]:
    candidates: list[Path] = []
    if har_path.is_dir():
        candidates = sorted(har_path.glob("*.har"))
    elif har_path.exists():
        candidates = [har_path]

    requests: list[dict[str, Any]] = []
    for path in candidates:
        try:
            data = json.loads(path.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        entries = data.get("log", {}).get("entries", [])
        for entry in entries:
            req = entry.get("request", {})
            url = req.get("url", "")
            if "tvmaze" not in url.lower():
                continue
            requests.append(
                {
                    "method": req.get("method"),
                    "url": url,
                    "status": entry.get("response", {}).get("status"),
                }
            )
    return requests


def parse_console_log(log_path: Path) -> list[str]:
    if not log_path.exists():
        return []
    issues = []
    patterns = (
        r"error:",
        r"fault:",
        r"warning:",
        r"Swift\.Task",
        r"data race",
        r"Main actor",
        r"runtime warning",
        r"non_fatal",
        r"possible_abrupt",
    )
    for line in log_path.read_text(errors="replace").splitlines():
        lower = line.lower()
        if any(re.search(p, lower) for p in patterns):
            issues.append(line.strip()[:200])
    return issues[:50]


def flow_signpost_name(flow: str) -> str:
    mapping = {
        "launch": "",
        "launch-with-data": "flow.launchWithData",
        "search": "flow.search",
        "searchEmpty": "flow.searchEmpty",
        "showDetails": "flow.showDetails",
        "viewWishlist": "flow.viewWishlist",
        "addToWishlist": "flow.addToWishlist",
        "removeFromWishlist": "flow.removeFromWishlist",
        "stressSearchDetailsBack": "flow.stressSearchDetailsBack",
        "stressAddRemoveWishlist": "flow.stressAddRemoveWishlist",
        "stressSearchEmpty": "flow.stressSearchEmpty",
    }
    return mapping.get(flow, f"flow.{flow}")


def analyze_run(trace: Path, flow: str, log_path: Path | None, har_path: Path | None) -> dict[str, Any]:
    lifecycle = export_table(trace, "life-cycle-period")
    ttff = parse_ttff(lifecycle)
    signposts = parse_signpost_intervals(export_table(trace, "os-signpost"))
    roi_xml = export_table(trace, "region-of-interest")
    sp_name = flow_signpost_name(flow)
    wall_ms = parse_roi_duration(roi_xml, sp_name)
    if wall_ms is None and sp_name and sp_name in signposts:
        wall_ms = signposts[sp_name][0]
    elif flow == "launch" and ttff:
        wall_ms = ttff

    baseline, peak, idle = parse_memory_samples(trace)
    hangs = parse_hangs(trace)
    leaks = parse_leaks(trace)
    retained = parse_retained_view_models(trace)

    flow_start = int(ttff * 1e6) if ttff else None
    flow_end = int((ttff + 15) * 1e6) if ttff else None
    cpu = parse_cpu(trace, flow_start, flow_end)

    network = parse_network_har(har_path) if har_path else []
    console = parse_console_log(log_path) if log_path else []

    near_baseline = None
    if baseline and idle:
        near_baseline = abs(idle - baseline) <= max(5.0, baseline * 0.1)

    return {
        "trace": str(trace),
        "wall_clock_ms": wall_ms,
        "ttff_ms": ttff,
        "baseline_memory_mb": baseline,
        "peak_memory_mb": peak,
        "idle_memory_mb": idle,
        "memory_near_baseline": near_baseline,
        "hangs_over_100ms": hangs,
        "leaks": leaks,
        "retained_types": dict(retained),
        "top_cpu_ms": cpu.most_common(10),
        "network_requests": network,
        "console_issues": console,
        "signposts": {k: v for k, v in signposts.items() if v},
    }


def aggregate_flow(name: str, runs: list[dict[str, Any]]) -> FlowMetrics:
    m = FlowMetrics(name=name, runs=len(runs))
    for run in runs:
        if run.get("wall_clock_ms") is not None:
            m.wall_clock_ms.append(run["wall_clock_ms"])
        if run.get("ttff_ms") is not None:
            m.ttff_ms.append(run["ttff_ms"])
        if run.get("peak_memory_mb") is not None:
            m.peak_memory_mb.append(run["peak_memory_mb"])
        if run.get("idle_memory_mb") is not None:
            m.idle_memory_mb.append(run["idle_memory_mb"])
        if run.get("baseline_memory_mb") is not None:
            m.baseline_memory_mb.append(run["baseline_memory_mb"])
        m.hangs_over_100ms.append(run.get("hangs_over_100ms", 0))
        m.leaks.append(run.get("leaks", 0))
        for sym, ms in run.get("top_cpu_ms", []):
            m.top_cpu[sym] += ms
        for typ, count in run.get("retained_types", {}).items():
            m.retained_types[typ] = max(m.retained_types.get(typ, 0), count)
        if run.get("network_requests"):
            m.network_requests.extend(run["network_requests"])
        m.console_issues.extend(run.get("console_issues", []))
    return m


def avg(values: list[float]) -> float | None:
    return statistics.mean(values) if values else None


def fmt_ms(v: float | None) -> str:
    return f"{v:.0f} ms" if v is not None else "—"


def fmt_mb(v: float | None) -> str:
    return f"{v:.1f} MB" if v is not None else "—"


def render_markdown(session: Path, flows: dict[str, FlowMetrics], raw: dict[str, Any]) -> str:
    lines = [
        "# NextSeason Performance Report",
        "",
        f"Session: `{session.name}`",
        "",
        "## Flow Summary",
        "",
        "| Flow | Pass/Fail | Avg wall-clock | Avg TTFF | Peak mem | Idle mem | Near baseline | Hangs >100ms | Leaks |",
        "|---|---|---:|---:|---:|---:|---|---:|---:|",
    ]

    for name, m in flows.items():
        lines.append(
            f"| {name} | **{m.pass_fail()}** | {fmt_ms(avg(m.wall_clock_ms))} | "
            f"{fmt_ms(avg(m.ttff_ms))} | {fmt_mb(max(m.peak_memory_mb) if m.peak_memory_mb else None)} | "
            f"{fmt_mb(avg(m.idle_memory_mb))} | "
            f"{'Yes' if m.baseline_memory_mb and m.idle_memory_mb and avg(m.idle_memory_mb) and avg(m.baseline_memory_mb) and abs(avg(m.idle_memory_mb) - avg(m.baseline_memory_mb)) <= max(5, avg(m.baseline_memory_mb) * 0.1) else '—'} | "
            f"{sum(m.hangs_over_100ms)} | {sum(m.leaks)} |"
        )

    lines.extend(["", "## Retained View / ViewModel (heuristic)", ""])
    any_retained = False
    for name, m in flows.items():
        if m.retained_types:
            any_retained = True
            lines.append(f"- **{name}**: {dict(m.retained_types)}")
    if not any_retained:
        lines.append("- No suspicious View/ViewModel retention detected in allocation summaries.")

    lines.extend(["", "## Top CPU (aggregated)", ""])
    for name, m in flows.items():
        if not m.top_cpu:
            continue
        lines.append(f"### {name}")
        for sym, ms in m.top_cpu.most_common(6):
            lines.append(f"- {ms:.0f} ms — `{sym[:100]}`")
        lines.append("")

    lines.extend(["", "## Network (duplicate check)", ""])
    for name, m in flows.items():
        if not m.network_requests:
            continue
        urls = [r["url"] for r in m.network_requests]
        dupes = {u: c for u, c in Counter(urls).items() if c > 1}
        lines.append(f"### {name} — {len(urls)} requests")
        if dupes:
            lines.append("- **Duplicate URLs:**")
            for u, c in sorted(dupes.items(), key=lambda x: -x[1])[:8]:
                lines.append(f"  - {c}× {u}")
        else:
            lines.append("- No duplicate URLs in captured HAR.")
        lines.append("")

    lines.extend(["", "## Console warnings / errors", ""])
    all_issues = sorted(set(issue for m in flows.values() for issue in m.console_issues))
    if all_issues:
        for issue in all_issues[:30]:
            lines.append(f"- `{issue}`")
    else:
        lines.append("- None captured during profiling runs.")

    lines.extend(["", "## Beta readiness (performance/resources)", ""])
    fails = [n for n, m in flows.items() if m.pass_fail() == "FAIL"]
    warns = [n for n, m in flows.items() if m.pass_fail() == "WARN"]
    if fails:
        lines.append(f"- **Not ready** — failures in: {', '.join(fails)}")
    elif warns:
        lines.append(f"- **Proceed with caution** — warnings in: {', '.join(warns)}")
    else:
        lines.append("- **Safe for beta** from a performance/resource perspective based on this session.")

    lines.extend(["", "## Artifacts", ""])
    lines.append(f"- Raw traces: `{session}/traces/`")
    lines.append(f"- JSON: `{session}/report.json`")
    lines.append("- `.trace` files are gitignored; do not commit.")

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze NextSeason Instruments traces")
    parser.add_argument("session_dir", type=Path, help="Session directory from profile-performance-suite.sh")
    args = parser.parse_args()

    session = args.session_dir.resolve()
    manifest_path = session / "manifest.json"
    if not manifest_path.exists():
        print(f"error: missing {manifest_path}", file=sys.stderr)
        return 1

    manifest = json.loads(manifest_path.read_text())
    raw_results: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for entry in manifest["runs"]:
        flow = entry["flow"]
        trace = session / entry["trace"]
        log_path = session / entry["log"] if entry.get("log") else None
        har_path = session / entry["har"] if entry.get("har") else None
        if har_path and not har_path.exists():
            alt = session / "har" / flow.replace("network-", "")
            if alt.is_dir():
                har_path = alt
        if not trace.exists():
            print(f"warning: missing trace {trace}", file=sys.stderr)
            continue
        raw_results[flow].append(analyze_run(trace, flow, log_path, har_path))

    flows = {name: aggregate_flow(name, runs) for name, runs in raw_results.items()}

    report = {
        "session": session.name,
        "flows": {
            name: {
                "pass_fail": m.pass_fail(),
                "runs": m.runs,
                "avg_wall_clock_ms": avg(m.wall_clock_ms),
                "avg_ttff_ms": avg(m.ttff_ms),
                "peak_memory_mb_max": max(m.peak_memory_mb) if m.peak_memory_mb else None,
                "avg_idle_memory_mb": avg(m.idle_memory_mb),
                "hangs_over_100ms_total": sum(m.hangs_over_100ms),
                "leaks_total": sum(m.leaks),
                "retained_types": dict(m.retained_types),
                "top_cpu_ms": m.top_cpu.most_common(10),
                "network_request_count": len(m.network_requests),
                "console_issue_count": len(set(m.console_issues)),
                "raw_runs": raw_results[name],
            }
            for name, m in flows.items()
        },
    }

    (session / "report.json").write_text(json.dumps(report, indent=2))
    md = render_markdown(session, flows, report)
    (session / "report.md").write_text(md)
    print(md)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
