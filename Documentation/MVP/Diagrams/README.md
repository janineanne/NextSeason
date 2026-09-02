# NextSeason TV Architecture Diagrams

This folder contains Mermaid diagrams documenting the architecture and major workflows of the NextSeason TV application.

These diagrams are intended to complement the source code and README by providing a high-level overview of how the application is organized and how its major components interact.

## Do not change these diagrams (or this file)

These diagrams document the application architecture at the MVP milestone. They are historical artifacts and should not be updated to reflect subsequent implementation changes. Changes should be limited to corrections that make the diagrams more accurately represent the tagged MVP.

## Diagrams

### 1. App Architecture
Shows the major layers of the application, including Views, ViewModels, Services, Persistence, and external dependencies.

Highlights:
- MVVM architecture
- Dependency relationships
- Separation of concerns

---

### 2. Navigation & Screens
Shows the primary user navigation through the application.

Includes:
- Search
- Watchlist
- Show Details
- Settings/About
- Diagnostics

---

### 3. Watchlist Refresh & Notifications
Illustrates how watchlisted shows are refreshed and how notification scheduling is coordinated.

Shows:
- Background refresh
- Manual refresh
- Change detection
- Notification scheduling

---

### 4. Data & Persistence
Documents how application data flows between the network layer, persistence layer, and UI.

Includes:
- TVMaze API
- Repository layer
- Local storage
- ViewModels

---

### 5. Search Flow
Sequence diagram showing the lifecycle of a search request.

Covers:
- User input
- Debouncing
- Network request
- Result processing
- Error handling

---

### 6. Show Detail & Tracking
Shows the interactions involved when viewing a show and adding or removing it from the watchlist.

Includes:
- Loading details
- Persistence updates
- UI refresh

---

### 7. Beta Diagnostics & Testing
Documents the diagnostic tools included specifically for beta testing.

Includes:
- Version information
- Build metadata
- Notification diagnostics
- Refresh diagnostics

---

### 8. Background Refresh Scheduling
Illustrates the background task lifecycle.

Shows:
- BGTaskScheduler
- Refresh timing
- API fetch
- Notification generation
- Next task scheduling

---

### 9. Analytics & Diagnostics
Documents the lightweight analytics and logging architecture used by the application.

Highlights:
- Privacy-first design
- Local logging
- Diagnostic information
- No third-party analytics

---

## Why Mermaid?

Mermaid diagrams are stored as plain Markdown, making them easy to review, version-control, and update alongside the source code. Git diffs clearly show architectural changes over time, and the diagrams can be rendered directly by GitHub and many Markdown editors.

