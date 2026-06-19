# User Stories

## Epic: Show Discovery

### US-001 Search for a Show

As a user,
I want to search for a TV show by name,
so that I can add it to my watchlist.

#### Acceptance Criteria

- User can enter text into a search field.
- Search results appear within a reasonable time.
- Results include:
  - Show title
  - Poster image (if available)
  - Show status
- User can select a show from results.

---

### US-002 View Show Details

As a user,
I want to view details about a show,
so that I can determine whether it is the correct show.

#### Acceptance Criteria

- User can open a show detail screen.
- Screen displays:
  - Title
  - Description
  - Poster
  - Status
  - Most recent season information
- User can add the show to their watchlist.

---

## Epic: Watchlist Management

### US-003 Add Show to Watchlist

As a user,
I want to add a show to my watchlist,
so that I can track future seasons.

#### Acceptance Criteria

- User can add a show from search results.
- User can add a show from show details.
- Added show immediately appears in watchlist.
- Duplicate additions are prevented.

---

### US-004 Remove Show from Watchlist

As a user,
I want to remove a show from my watchlist,
so that I stop receiving notifications.

#### Acceptance Criteria

- User can remove a tracked show.
- Removed shows no longer receive updates.
- Removed shows no longer generate notifications.

---

### US-005 View Watchlist

As a user,
I want to see all tracked shows,
so that I know what I am monitoring.

#### Acceptance Criteria

- Watchlist displays all tracked shows.
- Watchlist displays current status.
- User can tap a show for details.

---

## Epic: Season Tracking

### US-006 View Season Status

As a user,
I want to see the current status of a show,
so that I know whether a new season is expected.

#### Acceptance Criteria

- Show displays status:
  - Running
  - Returning
  - Ended
  - Unknown
- Last known season is visible.
- Next season information is shown when available.

---

## Epic: Notifications

### US-007 Receive Notification

As a user,
I want to receive a notification when a new season becomes available,
so that I do not miss it.

#### Acceptance Criteria

- App requests notification permission.
- Notification identifies the show.
- Tapping notification opens the app.

---

### US-008 Manage Notification Permission

As a user,
I want to control notifications,
so that the app respects my preferences.

#### Acceptance Criteria

- App handles denied permission gracefully.
- App explains why notifications are useful.
- User can continue using the app without notifications.
