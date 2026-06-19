# Season Calculation Flow

```mermaid
flowchart TD
    Show[Saved show]
    Episodes[Episode / season data]
    Calculator[Next Season Calculator]

    Show --> Calculator
    Episodes --> Calculator

    Calculator --> Known{Is enough data available?}

    Known -->|No| Unknown[Display unknown / insufficient data]
    Known -->|Yes| Evaluate[Evaluate latest known season and episode dates]

    Evaluate --> Current{Does the show appear current?}

    Current -->|Likely current| CurrentStatus[Display current / no new season detected]
    Current -->|Likely has newer season| NewSeason[Display possible new season available]
    Current -->|Unclear| Unclear[Display unclear status]

    Unknown --> UI[Watchlist UI]
    CurrentStatus --> UI
    NewSeason --> UI
    Unclear --> UI
```

## Purpose

This diagram intentionally avoids pretending the app has perfect knowledge.

TV data can be incomplete, delayed, or ambiguous. The calculator should produce useful status, but the UI should be honest when the data does not support certainty.
