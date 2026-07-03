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
        """

    static let appSection = """
        **Version** and **Build channel** identify the build you are running.

        **Current theme** shows the active app icon and color theme.

        **Notifications enabled** reflects whether the app can deliver alerts on this device \
        (system permission granted).
        """

    static let betaValidationSection = """
        These fields reflect **real watchlist polling** against TVMaze—not simulated data.

        **Last refresh** is when the app last checked tracked shows for updates.

        **Next refresh window** is when the next background refresh is scheduled. Production \
        builds use a 12-hour cadence; accelerated soak-test builds may use 10 minutes.

        **Last fetch result** summarizes the outcome of the most recent refresh (success, \
        skipped, error, and so on).

        **Last notification decision** records what the notification pipeline decided after \
        the last refresh—for example, whether an alert was sent, suppressed by debounce, or \
        skipped because nothing changed.

        **Last simulation** appears after you run a beta action that uses fake data; it \
        summarizes that run.

        Simulated updates use fake data only and never modify your tracked shows.
        """

    static let betaActionsSection = """
        **Force Refresh Now** runs an immediate watchlist refresh using live TVMaze data.

        **Send Test Notification** delivers a sample “new season” alert right away, without \
        going through the refresh pipeline. Useful for checking that notifications appear \
        on this device. Will send blank notification if watchlist is empty.

        **Schedule Pipeline Test Notification** seeds a fake new-season update, runs it \
        through the real refresh and notification decision path, and schedules delivery in \
        5–10 seconds so you can background the app and confirm the alert arrives.

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

        Nothing is sent automatically. Share this report only if you choose to—for example, \
        when filing beta feedback.
        """
}
