# About screen notifications button

## User

Let's add a button to the About screen which tells the user whether Notifications are enabled or disabled and takes them to the appropriate place in Settings to change it.

## Assistant

I'll find the About screen and how notifications are handled in the app so we can add a status button that opens the right Settings page.

Adding a Notifications row to the About screen: show enabled/disabled status, refresh when the app becomes active, and route taps to the system prompt or Settings as appropriate.

Added a **Notifications** row to the About screen in `AppAboutView.swift`.

**What it shows**
- Status on the right: **Enabled** or **Disabled**
- Icon: `bell.fill` when enabled, `bell.slash` when disabled
- Footer text that explains what tapping does

**What happens on tap**
- **Not yet asked** → system permission prompt (`requestAuthorizationIfNeeded()`)
- **Denied or already enabled** → opens the app’s page in Settings (`openNotificationSettings()`)

**Status refresh**
- On appear
- When the app returns to the foreground (e.g. after visiting Settings)

**What to test**
1. Open About (info button on Search or Watchlist in Debug/TestFlight).
2. With notifications off, confirm the row shows **Disabled** and opens Settings or the permission prompt.
3. Enable notifications, return to the app, and confirm the row updates to **Enabled**.
4. Tap again and confirm it opens Settings to manage notifications.
