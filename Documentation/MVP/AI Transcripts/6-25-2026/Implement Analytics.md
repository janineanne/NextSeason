# Analytics section implementation

## User

Please implement the Analytics section from Release Readiness.md

## User

I'm seeing analytics events in the Xcode console, but nothing in Console.app.

## User

Ok, that's working but I can't get actor_name_tapped to happen. Where am I supposed to tap for Severance?

## User

How about if you add some bold text that says "Tap here for Actor Name Analytic" randomly in the summary for each show?

## Assistant

Adding a deterministic per-show bold tap target inserted into each summary so actor-name analytics are easy to test.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":235,"limit":30}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SummaryFormatterTests.swift","offset":1,"limit":30}
```

## Assistant

Inserting a per-show bold analytics tap target into summaries via `SummaryFormatter`, placed deterministically from each show's ID.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Done. Each show’s **About** section now includes a bold, tappable line:

**Tap here for Actor Name Analytics**

It’s placed in one of three spots based on the show ID (stable for that show, varies across shows):

- **Start** of the summary  
- **Middle** (at a nearby word boundary)  
- **End** of the summary  

For **Severance** specifically, it’s at the **end** of the About paragraph — scroll to About and tap that bold phrase at the bottom.

You should see `actor_name_tapped show_id=44933` in Console.app. Remove this beta helper before portfolio release if you don’t want it visible to reviewers.

## User

That works. Please add a note in the Portfolio Readiness section of Release Readiness.md to remove that after beta.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Release Readiness.md","offset":500}
```

### Tool Edit File V2

## Assistant

Added a Portfolio Readiness checklist item to remove the beta analytics tap target (`SummaryFormatter.analyticsTapTargetMarkdown`) before linking the app from your resume.

## User

How are these analytics going to be useful to us, since they only live on the user's device?

## Assistant

The honest answer: **as implemented today, they’re mainly useful to you while developing and debugging—not for learning what beta users collectively do.**

## What you get right now

The current `AnalyticsService` writes structured events to **Apple’s unified logging** on each device (`os.Logger`). That helps when:

- **You** run the app from Xcode or watch Console.app on a device/simulator you control
- You verify that instrumentation fires at the right moments (search, track, notification tap, etc.)
- You debug flows without sprinkling `print` everywhere

The `AnalyticsTracking` abstraction also means call sites stay stable when you add a real backend later.

## What you *don’t* get

Those logs **do not automatically leave the device**. So you **cannot** today answer Release Readiness-style questions like:

- How many beta users search vs. track on first session?
- Which flows fail most often?
- Do people open show detail from search or watchlist?

Unless a tester manually exports logs (Console.app, sysdiagnose, etc.), **you never see their events**. For a 5–10 person beta, that’s a real gap relative to the doc’s goal of “collect enough anonymous usage data during beta testing.”

## How they’re still useful in beta

1. **Validate instrumentation** before paying for or integrating a remote provider  
2. **Reproduce issues** when *you* or a tester reports a problem and can capture logs  
3. **Pair with other beta channels** you already planned:
   - TestFlight crash reports
   - Google Form feedback (“What were you trying to do?”)
   - Direct observation during validation tasks

So: useful for **engineering confidence**, not yet for **product analytics at scale**.

## What would make them useful across beta users

You’d add a second implementation of `AnalyticsTracking` that sends the same `AnalyticsEvent` payloads to something centralized, for example:

- **TelemetryDeck**, **Firebase Analytics**, **Mixpanel**, etc. (privacy-friendly, no PII—you already avoid query text)
- A **minimal backend** you own (event name + parameters only)
- **MetricKit** / App Store Connect analytics (limited, not custom events)

The event design you have (query length, not query text; show IDs; error categories) is already aligned with that swap.

## Practical recommendation

- **During internal testing / your own beta runs:** local logs are fine.  
- **Before or during the 5–10 user beta:** if you want aggregate behavior data, plug in a remote `AnalyticsTracking` implementation—or accept that **feedback form + TestFlight** are your primary data sources and treat local analytics as dev tooling only.

If you want, I can outline a minimal remote provider behind `AnalyticsTracking` (still no search text, still no third-party dependency unless you pick one).

## User

Not necessary now, but please add this to the analytics section of Post-MVP Roadmap.md.

### Tool Read File V2

```
{}
```

### Tool Glob File Search

```
{"globPattern":"**/Roadmap.md"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Product Analytics","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","caseInsensitive":false,"multiline":false,"toolCallId":"tool_b407b4cf-7546-4040-a310-7fafda46621","offset":0}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Post-MVP","globPattern":"**/*"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Post-MVP/Post-MVP Roadmap.md","offset":190}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Post-MVP/Post-MVP Roadmap.md","offset":1,"limit":35}
```

### Tool Edit File V2

## Assistant

Added to the **Product Analytics** section of `Documentation/Post-MVP/Post-MVP Roadmap.md`:

- **MVP State (Local Logging Only)** — what device-only `os.Logger` analytics are good for and what they can’t tell you across beta users  
- **Post-MVP: Remote Collection** — swapping in a remote `AnalyticsTracking` provider, example options, and privacy constraints  
- A cross-reference to remove the beta tap target before portfolio release  

The existing **Future Investigation** questions are unchanged below that.
