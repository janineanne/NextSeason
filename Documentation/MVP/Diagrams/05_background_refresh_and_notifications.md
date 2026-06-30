# Background Refresh and Notification Flow

```mermaid
sequenceDiagram
    participant iOS as iOS / BGTaskScheduler
    participant Scheduler as RefreshScheduler
    participant Refresh as WatchlistRefreshService
    participant Repo as WatchlistRepository
    participant API as TVMazeClient actor
    participant Detector as StatusChangeDetector
    participant Notifications as NotificationService
    participant Center as UNUserNotificationCenter
    participant Analytics as AnalyticsService
    participant Nav as AppNavigationCoordinator

    Scheduler->>iOS: register BGAppRefreshTask
    Scheduler->>iOS: scheduleNextRefresh()

    iOS->>Scheduler: launch background refresh task
    Scheduler->>Scheduler: scheduleNextRefresh() immediately
    Scheduler->>Refresh: refreshAll()

    Refresh->>Repo: all()
    Repo-->>Refresh: tracked shows

    alt Watchlist empty
        Refresh-->>Scheduler: complete successfully
    else Watchlist has shows
        Refresh->>API: updatedShows(since: oldestCheck)
        API-->>Refresh: [showID: updatedAt]

        loop Each tracked show with newer TVMaze update
            Refresh->>API: show(id, bypassCache: true)
            API-->>Refresh: refreshed Show
            Refresh->>Detector: evaluate(tracked, newStatus)
            Detector-->>Refresh: updated tracked show + optional notification
            Refresh->>Repo: updateAfterRefresh(tracked)

            alt Meaningful season-status change
                Refresh->>Notifications: deliver(notification)
                Notifications->>Center: schedule local notification
                Notifications->>Analytics: notificationReminderScheduled
            end
        end
    end

    Scheduler-->>iOS: setTaskCompleted(success)

    alt User taps notification
        Center->>Nav: queueShowNavigation(showID)
        Nav->>Repo: all() to find tracked show
        alt Show is still tracked
            Nav->>Nav: select Watchlist tab + push tracked show detail
        else Show not tracked locally
            Nav->>API: show(id)
            Nav->>Nav: select Search tab + push show detail
        end
        Nav->>Analytics: appOpenedFromNotification(showID)
    end
```

## Notes

Background refresh is best-effort. iOS controls when and whether the refresh task runs. The app schedules the next refresh when handling the current task and guards task completion so `setTaskCompleted` is called at most once.
