# SwiftData error recovery strategy

## User

We currently call fatalError if ModelContainer creation fails during app startup. Is there a practical recovery strategy for a SwiftData app, or is Apple’s recommended approach to crash because this indicates an unrecoverable configuration error? If you recommend changing it, please explain the tradeoffs before modifying the co

## Assistant

I'll locate where `ModelContainer` is created and how failures are handled, then compare that to SwiftData best practices before recommending any change.

For NextSeason today, **`fatalError` on `ModelContainer` init failure is a reasonable default** — and it matches what Apple’s SwiftData samples effectively do (often via `try!` in `@main`). Apple doesn’t publish a formal “you must crash” guideline, but the framework assumes a working container at launch; there’s no built-in degraded mode.

Your current setup:

```36:55:NextSeason/NextSeasonApp.swift
		do {
			let repository: any WatchlistRepository
			if UITestingConfiguration.isEnabled {
				let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
				modelContainer = try ModelContainer(
					for: TrackedShowEntity.self,
					configurations: configuration
				)
				repository = InMemoryWatchlistRepository()
			} else {
				let container = try ModelContainer(for: TrackedShowEntity.self)
				modelContainer = container
				repository = SwiftDataWatchlistRepository(context: ModelContext(container))
			}
			watchlistRepository = repository
			refreshService = WatchlistRefreshService(repository: repository, analytics: analyticsService)
			watchlistUndoRemoval = WatchlistUndoRemoval(repository: repository, analytics: analyticsService)
		} catch {
			fatalError("Failed to create ModelContainer: \(error)")
		}
```

## What actually fails here?

| Failure type | Typical cause | Recoverable without a code fix? |
|---|---|---|
| **Configuration / programmer error** | Wrong model types, invalid `ModelConfiguration`, schema definition bug | No — crashes every launch until you ship a fix |
| **Migration failure** | Schema change that lightweight migration can’t handle (you have no `VersionedSchema` / `MigrationPlan` yet) | Sometimes — destructive reset or a proper migration plan |
| **Store / environment** | Corrupted SQLite file, disk full, rare sandbox issues | Sometimes — retry, delete store, or show an error UI |

Most production incidents that *look* like “SwiftData broke” are migration or store corruption — not the first category.

## Recovery strategies (and tradeoffs)

### 1. Keep `fatalError` (status quo)

**Pros:** Simple; fail-fast surfaces bugs in development; no half-working app state; matches Apple sample style.

**Cons:** Users see a crash loop with no explanation if the store is bad; no chance to preserve data; crash reports may lack context unless you log first.

**Best for:** MVP, pre-release, when persistence schema is still stable.

---

### 2. Log, then crash (small improvement)

Record the error via `AppDiagnosticsLogger` / `Logger` / MetricKit **before** `fatalError`.

**Pros:** Tiny diff; better crash triage in TestFlight.

**Cons:** Still crashes for users.

---

### 3. Destructive recovery (delete store → retry once)

On failure, remove the default store URL and call `ModelContainer(for:)` again.

**Pros:** Fixes corruption and some migration failures; user gets a working app.

**Cons:** **Silent data loss** (watchlist + notification state); risky if you misclassify a programmer error; App Review / user trust concerns if not disclosed.

**Fit for NextSeason:** Defensible in principle — watchlist items can be re-added from TVMaze — but only if you treat it as a last resort, not the default path.

---

### 4. User-facing error screen (“Reset local data”)

Refactor startup so the app can launch without a container: show a blocking view with reset / contact support / retry.

**Pros:** Honest UX; user chooses data loss; works for disk-full and corruption.

**Cons:** Meaningful architecture work (`modelContainer` is a non-optional `let`; `.modelContainer()` on `WindowGroup`; repository wiring); background refresh and notifications need guardrails; more tests.

---

### 5. In-memory fallback

Reuse the UI-test pattern: `ModelConfiguration(isStoredInMemoryOnly: true)` + `InMemoryWatchlistRepository`.

**Pros:** App stays usable for search/browse.

**Cons:** Watchlist doesn’t survive relaunch; confusing if you don’t banner it; background refresh/notifications behave differently.

---

### 6. Prevent failures upstream (best long-term)

Add explicit **`VersionedSchema` + `SchemaMigrationPlan`** before schema changes ship. That’s the real fix for migration-related crashes — recovery is a safety net, not the primary strategy.

## Recommendation for NextSeason

**Don’t replace `fatalError` yet** for the MVP/portfolio stage. The app is built around persistence at the root; without a container, most of the product doesn’t work meaningfully.

If you want to improve without a large refactor:

1. **Log the error** before crashing (TestFlight/debuggability).
2. **Add a migration plan** before the next `TrackedShowEntity` schema change — that prevents the most likely real-world failure mode.
3. **Consider destructive recovery or a reset screen later** (pre–App Store or post-MVP), when schema changes are expected and you want to avoid crash loops for corrupted stores.

The `WatchlistRepository+Environment` `fatalError` is a different case — that’s a **development wiring mistake**, not a runtime persistence failure. Crashing there is appropriate.

---

I didn’t change any code since you asked for tradeoffs first. If you want to move forward, sensible options are:

- **Minimal:** log + `fatalError`
- **Medium:** log + one-shot store delete on migration/corruption errors only
- **Full:** blocking error UI with explicit reset

Which direction do you prefer?

## User

Go ahead with option 1

## Assistant

I'll add error logging via `AppDiagnosticsLogger` before the existing `fatalError` on `ModelContainer` init failure.

Adding a persistence fault log and persisting breadcrumbs before the existing `fatalError`, so TestFlight crash investigation has context.

Done. On `ModelContainer` init failure, the app now logs before it crashes:

1. **Breadcrumb** — `model_container_init_failed` (included in diagnostics export and the next launch’s abrupt-termination trail)
2. **`persistBreadcrumbsNow()`** — writes breadcrumbs to disk so they survive the crash
3. **OSLog fault** — `model_container_init_failed` on the `persistence` category, with the error description

Behavior is unchanged: it still calls `fatalError`. You just get better signal in Console (`subsystem:com.TrialByFyre.NextSeason category:persistence`) and in the in-app diagnostics view if the user relaunches after a crash loop.

**What to test:** No functional test needed unless you want to verify logging — a normal launch should behave as before. To confirm the log path, you could temporarily throw in the `ModelContainer` init block and check Console for the fault line.
