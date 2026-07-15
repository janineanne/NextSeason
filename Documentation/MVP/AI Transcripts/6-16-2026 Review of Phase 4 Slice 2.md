> From: https://chatgpt.com/c/6a31d123-8314-83e8-9fe1-ebe60eefb061

# you asked

message time: 2026-06-16 15:41:56

This is the project after Cursor/Claude has implemented the rest of Phase 2.  Please review it.

---

# chatgpt response

I’ll review the zip as a code review: first map what changed, then inspect the Phase 2-related files, then call out concrete issues by severity without modifying anything.

I’ve got the project unpacked and the Phase 2 surface area is clear: search, detail, watchlist persistence, refresh/notifications, and tests. I’m checking now for correctness issues rather than style nits.

Reviewed. Overall: **this is solid work**. The architecture is still clean, the view models are testable, SwiftData is properly behind a repository, and the notification/refresh pieces are reasonably scoped.

I found **one important issue**:

**High priority — background refresh can miss updates.**  
`WatchlistRefreshService.refreshAll()` asks TVMaze for only `.day` updates, but background refresh is best-effort and may not run every 12 hours. If iOS delays refresh for more than a day, the app could miss a TVMaze update entirely.

Relevant code:

```swift
updates = try await tvMaze.updatedShows(since: .day)
```

I’d change this to `.week` at minimum, or choose the window based on the oldest `lastCheckedAt`.

Other smaller notes:

**Medium — notification authorization is requested only after adding a show.**  
That’s fine for MVP, but there’s no user-visible explanation before the system prompt. Later, you may want an onboarding-style explanation.

**Medium — detail view reloads every time its task runs.**  
`ShowDetailView` creates the VM once, but still calls `load()` every `.task` execution. Not disastrous, just potentially extra network traffic.

**Low — `deliver()` only accepts `.authorized`.**  
`requestAuthorizationIfNeeded()` treats `.provisional` and `.ephemeral` as allowed, but `deliver()` silently skips them. Probably not relevant unless you use provisional notifications.

**Low — I couldn’t run an actual Xcode build here.**  
This environment doesn’t have `xcodebuild`, so this is a static review. Nothing obvious jumped out as a compile problem.

My recommendation: **fix the `.day` update-window issue before merging.** Everything else can reasonably wait.

---
Powered by [AI Exporter](https://saveai.net)