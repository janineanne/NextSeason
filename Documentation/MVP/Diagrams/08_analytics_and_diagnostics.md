# Analytics and Diagnostics

```mermaid
flowchart TD
    subgraph Producers[Event Producers]
        AppLaunch[App launch]
        Search[Search flow]
        Detail[Show detail]
        Watchlist[Watchlist actions]
        Notifications[Notification flow]
        Theme[Theme switcher]
        Errors[Non-fatal errors]
    end

    subgraph Analytics[Analytics Layer]
        Protocol[AnalyticsTracking protocol]
        Service[AnalyticsService]
        Counters[AnalyticsCounters]
        Logger[os.Logger]
    end

    subgraph Diagnostics[Diagnostics]
        Report[AnalyticsDiagnosticsReport]
        Screen[DiagnosticsView]
        AppLogs[AppDiagnosticsLogger]
        MetricKit[MetricKitDiagnosticsSubscriber]
    end

    AppLaunch --> Protocol
    Search --> Protocol
    Detail --> Protocol
    Watchlist --> Protocol
    Notifications --> Protocol
    Theme --> Protocol
    Errors --> Protocol

    Protocol --> Service
    Service --> Counters
    Service --> Logger
    Counters --> Report
    Report --> Screen

    Errors --> AppLogs
    AppLaunch --> MetricKit
    MetricKit --> AppLogs
```

## Notes

The MVP uses local structured logging and local aggregate counters. It intentionally avoids collecting search text, show titles, user identifiers, or other PII. Remote analytics can be added post-MVP by implementing the same `AnalyticsTracking` protocol.
