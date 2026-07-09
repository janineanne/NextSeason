//
//  DiagnosticsDocumentationCopy.swift
//  NextSeason
//

import Foundation

/// In-app help text for the beta Diagnostics screen.
enum DiagnosticsDocumentationCopy {
    static let overview = """
        Diagnostics are available only in Debug and TestFlight builds. Use this screen to \
        validate background refresh, notifications, and launch stability during beta testing.

        **Background** fields show what happened the last time iOS ran a background refresh \
        task while the app was not in use. They are saved across app launches.

        **Foreground** fields show the result of the last **Force Refresh Now** tap in this \
        session only. Opening the app or returning from the background does not update them.
        """

    static let appSection = """
        **Version** and **Build channel** identify the build you are running.

        **Current theme** shows the active app icon and color theme.

        **Notifications enabled** reflects whether the app can deliver alerts on this device \
        (system permission granted).
        """

    static let betaValidationBackgroundSection = """
        These fields reflect **real watchlist polling** against TVMaze during a background \
        refresh task—not simulated data. All three are **saved across app launches**.

        **Last background refresh** is when iOS last woke the app to check tracked shows in \
        the background. Opening Diagnostics or using the app in the foreground does not \
        update this timestamp.

        **Next refresh window** is the earliest time the next background refresh is \
        scheduled. Production builds use a 12-hour cadence; accelerated soak-test builds \
        may use 10 minutes (see launch flags in developer docs).

        **Last background fetch result** summarizes that background run—for example, \
        how many shows were checked, whether TVMaze reported changes, or if an error occurred.

        **Last background notification decision** records what the notification pipeline \
        decided after that background run—for example, whether an alert was sent, held for \
        debounce, or skipped because nothing changed.
        """

    static let betaValidationForegroundSection = """
        These fields update only when you tap **Force Refresh Now** in Beta actions. They \
        reflect a **manual** refresh using live TVMaze data and your real watchlist. They \
        are **not saved**—they reset when the app is terminated.

        Automatic refreshes when you open or return to the app do not update these fields \
        (even though the app may skip network work if a refresh ran within the last \
        15 minutes).

        **Last foreground refresh** is when that manual refresh completed.

        **Last foreground fetch result** and **Last foreground notification decision** \
        summarize the outcome the same way as the background fields above.
        """

    static let betaValidationSimulationSection = """
        **Last simulation** appears after you run a beta action that uses fake data. It \
        summarizes that run only and never reflects your real watchlist.

        Simulated updates use fake data only and never modify your tracked shows.
        """

    static let betaActionsSection = """
        **Force Refresh Now** runs an immediate watchlist refresh using live TVMaze data. \
        When it finishes, check the **Last foreground refresh** fields above for the result.

        The notification test actions below require **Notifications enabled** (alert permission). \
        They are disabled until permission is granted.

        **Send Test Notification** delivers a sample “new season” alert using the first \
        tracked watchlist show, without going through the refresh pipeline. Useful for \
        confirming that notifications appear on this device.

        **Schedule Pipeline Test Notification** seeds a fake new-season update for that \
        same watchlist show, runs it through the real refresh and notification decision \
        path, and schedules delivery in 5–10 seconds so you can background the app and \
        confirm the alert arrives. Track at least one show first.

        **Run Simulated Update Scenario** is a two-step exercise: tap once for baseline fake \
        data (step 1), then tap again for updated fake data (step 2) to exercise debounce \
        and date-backed notification logic. Your real watchlist is not affected.
        """

    static let launchInvestigationSection = """
        **Previous launch** flags when the prior session did not reach a normal background \
        transition—for example, a crash or force quit. It does not replace TestFlight crash \
        reports; it only gives testers a quick signal and context to share.

        **Current launch started** and **Last graceful background** help correlate timing \
        with unexpected termination.

        When a prior launch ended unexpectedly, additional timestamps and breadcrumbs from \
        that session are shown. **Breadcrumbs** are lightweight event markers recorded during \
        the current session (and the prior session when relevant) to help reproduce issues.
        """

    static let usageSection = """
        Local counters for how you have used the app in this install. They are included in \
        the shareable report and are not sent automatically.
        """

    static let shareReportSection = """
        **Share Report** and **Copy Report** export a text summary of the fields above, \
        usage counters, and recent breadcrumbs.

        Background refresh fields are always included. Foreground refresh fields are included \
        only if you used **Force Refresh Now** during this session. **Last simulation** is \
        included when present.

        Nothing is sent automatically. Share this report only if you choose to—for example, \
        when filing beta feedback.
        """
}
