#!/usr/bin/env python3
"""
Generate the bundled TheTVDB ↔ TVMaze show ID mapping SQLite database.

Walks TVMaze's paginated show index (`GET /shows?page=`), extracts shows with a
usable `externals.thetvdb` id plus TVMaze `name` / `image.medium`, and writes:

  NextSeason/Resources/ShowIDMapping/tvdb_tvmaze_show_id_mapping.sqlite

Run manually before an App Store release (not part of normal Xcode builds).
The same entry point is suitable for future CI invocation.

Usage:
  ./Scripts/generate-tvdb-tvmaze-show-id-mapping-db.py
  ./Scripts/generate-tvdb-tvmaze-show-id-mapping-db.py --output /path/to/out.sqlite

Respects TVMaze rate limits with polite pacing and 429 back-off.
Derived from TVMaze data (CC BY-SA); see Resources/ShowIDMapping/ATTRIBUTION.md.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = (
    REPO_ROOT
    / "NextSeason"
    / "Resources"
    / "ShowIDMapping"
    / "tvdb_tvmaze_show_id_mapping.sqlite"
)

TVMAZE_BASE = "https://api.tvmaze.com"
USER_AGENT = "NextSeason/show-id-mapping-db-generator (manual; local-dev)"
SCHEMA_VERSION = "2"
PAGE_SIZE = 250  # TVMaze show-index ID slice
REQUEST_PAUSE_SECONDS = 0.35  # stay comfortably under ≥20 calls / 10s
MAX_RETRIES = 5


def http_get_json(url: str) -> tuple[int, Any]:
    """GET `url` and return `(status, decoded JSON or None)` without raising on HTTP errors."""
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read()
            status = getattr(response, "status", 200)
            if not body:
                return status, None
            return status, json.loads(body.decode("utf-8"))
    except urllib.error.HTTPError as error:
        body = error.read()
        payload: Any = None
        if body:
            try:
                payload = json.loads(body.decode("utf-8"))
            except json.JSONDecodeError:
                payload = None
        return error.code, payload


def fetch_shows_page(page: int) -> list[dict[str, Any]] | None:
    """Return shows for the page, or None when the index is exhausted (HTTP 404)."""
    url = f"{TVMAZE_BASE}/shows?page={page}"
    for attempt in range(MAX_RETRIES):
        status, payload = http_get_json(url)
        if status == 404:
            return None
        if status == 429:
            sleep_for = 2.0 * (attempt + 1)
            print(f"rate limited on page {page}; sleeping {sleep_for:.1f}s", file=sys.stderr)
            time.sleep(sleep_for)
            continue
        if status != 200 or not isinstance(payload, list):
            raise RuntimeError(f"Unexpected response for page {page}: HTTP {status}")
        return payload
    raise RuntimeError(f"Gave up on page {page} after repeated 429 responses")


def create_schema(connection: sqlite3.Connection) -> None:
    """Creates empty `meta` / `mappings` tables matching the on-device schema."""
    connection.executescript(
        """
        PRAGMA journal_mode = OFF;
        PRAGMA synchronous = OFF;

        CREATE TABLE meta (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
        );

        CREATE TABLE mappings (
            tvdb_id INTEGER PRIMARY KEY NOT NULL,
            tvmaze_id INTEGER NOT NULL,
            name TEXT,
            poster_medium_url TEXT
        );

        CREATE INDEX idx_mappings_tvmaze_id ON mappings(tvmaze_id);
        """
    )


def set_meta(connection: sqlite3.Connection, key: str, value: str) -> None:
    """Inserts or replaces a single meta key/value pair."""
    connection.execute(
        "INSERT INTO meta(key, value) VALUES(?, ?) "
        "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        (key, value),
    )


def generate(output_path: Path) -> None:
    """Walks the TVMaze show index and atomically writes the SQLite snapshot."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = output_path.with_suffix(output_path.suffix + ".tmp")
    if temp_path.exists():
        temp_path.unlink()

    # tvdb_id → (tvmaze_id, name, poster_medium_url)
    mappings: dict[int, tuple[int, str | None, str | None]] = {}
    highest_tvmaze_id = 0
    shows_seen = 0
    page = 0

    connection = sqlite3.connect(temp_path)
    try:
        create_schema(connection)

        while True:
            shows = fetch_shows_page(page)
            if shows is None:
                break

            shows_seen += len(shows)
            for show in shows:
                tvmaze_id = int(show["id"])
                if tvmaze_id > highest_tvmaze_id:
                    highest_tvmaze_id = tvmaze_id

                externals = show.get("externals") or {}
                tvdb_raw = externals.get("thetvdb")
                if tvdb_raw is None:
                    continue
                try:
                    tvdb_id = int(tvdb_raw)
                except (TypeError, ValueError):
                    continue
                if tvdb_id <= 0:
                    continue
                # Deterministic: lowest TVMaze id wins on rare conflicts.
                existing = mappings.get(tvdb_id)
                if existing is None or tvmaze_id < existing[0]:
                    raw_name = show.get("name")
                    name = raw_name.strip() if isinstance(raw_name, str) else None
                    if name == "":
                        name = None
                    image = show.get("image") or {}
                    poster = image.get("medium") if isinstance(image, dict) else None
                    if isinstance(poster, str):
                        poster = poster.strip() or None
                    else:
                        poster = None
                    mappings[tvdb_id] = (tvmaze_id, name, poster)

            if page % 25 == 0:
                print(
                    f"page {page}: shows_seen={shows_seen} mappings={len(mappings)} "
                    f"highest_id={highest_tvmaze_id}",
                    flush=True,
                )

            page += 1
            time.sleep(REQUEST_PAUSE_SECONDS)

        rows = sorted(mappings.items(), key=lambda pair: pair[0])
        connection.executemany(
            "INSERT INTO mappings(tvdb_id, tvmaze_id, name, poster_medium_url) "
            "VALUES(?, ?, ?, ?)",
            [
                (tvdb_id, tvmaze_id, name, poster)
                for tvdb_id, (tvmaze_id, name, poster) in rows
            ],
        )

        generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        set_meta(connection, "schema_version", SCHEMA_VERSION)
        set_meta(connection, "generated_at", generated_at)
        set_meta(connection, "highest_tvmaze_id", str(highest_tvmaze_id))
        set_meta(connection, "mapping_count", str(len(rows)))
        set_meta(connection, "source", "TVMaze")
        set_meta(connection, "license", "CC BY-SA")
        # Bundled snapshot has not been incrementally synced on-device yet.
        set_meta(connection, "last_successful_sync_at", "")

        connection.commit()
    finally:
        connection.close()

    os.replace(temp_path, output_path)
    size_kb = output_path.stat().st_size / 1024
    print(
        f"Wrote {output_path} ({size_kb:.1f} KiB) "
        f"mappings={len(mappings)} highest_tvmaze_id={highest_tvmaze_id}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the bundled TVDB↔TVMaze show ID mapping SQLite database."
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output SQLite path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()
    generate(args.output.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
