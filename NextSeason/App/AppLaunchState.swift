//
//  AppLaunchState.swift
//  NextSeason
//

import Foundation
import UserNotifications
import os

/// Result of app bootstrap: a working composition root, or a blocking
/// persistence recovery flow when `ModelContainer` cannot be created.
enum AppLaunchState {
    case ready(AppCompositionRoot)
    case recovery(RecoveryContext)

    /// User-facing recovery payload after a persistence open failure.
    struct RecoveryContext {
        /// Most recent `ModelContainer` / composition failure.
        let error: any Error
        /// First launch failure, when a later retry failed with a different error.
        let originalError: (any Error)?
        /// Failure from `PersistentStoreReset`, if the user chose Reset Local Data
        /// and the store files could not be removed.
        let resetError: (any Error)?
        /// True after the on-disk watchlist store was successfully removed.
        /// The previous watchlist can no longer be restored.
        let didResetStore: Bool

        init(
            error: any Error,
            originalError: (any Error)? = nil,
            resetError: (any Error)? = nil,
            didResetStore: Bool = false
        ) {
            self.error = error
            self.originalError = originalError
            self.resetError = resetError
            self.didResetStore = didResetStore
        }

        /// Shareable diagnostics for this failure. Includes the current and
        /// original SwiftData errors plus any reset failure; these are for
        /// TestFlight triage, not on-screen copy.
        ///
        /// Notification authorization is not queried during recovery (the
        /// flow stays synchronous), so the report records that status as
        /// unavailable rather than as disabled.
        func diagnosticsReport() -> String {
            AnalyticsDiagnosticsReport.formatted(
                counters: AnalyticsCountersStore().snapshot(),
                notificationsEnabled: nil,
                persistenceFailure: String(describing: error),
                originalPersistenceFailure: originalError.map { String(describing: $0) },
                persistenceResetFailure: resetError.map { String(describing: $0) },
                localStoreWasReset: didResetStore
            )
        }
    }

    /// Attempts composition. On failure, logs diagnostics and returns
    /// `.recovery` instead of crashing.
    static func bootstrap(
        makeRoot: () throws -> AppCompositionRoot = { try AppCompositionRoot() }
    ) -> AppLaunchState {
        do {
            let root = try makeRoot()
            configureRuntime(root)
            return .ready(root)
        } catch {
            AppDiagnosticsLogger.logModelContainerInitFailure(error)
            AppDiagnosticsLogger.breadcrumb("persistence_recovery_presented")
            AppDiagnosticsLogger.persistBreadcrumbsNow()
            return .recovery(RecoveryContext(error: error))
        }
    }

    /// Deletes the on-disk watchlist store (after the user confirmed),
    /// clears scheduled notifications, and retries bootstrap.
    mutating func resetLocalData(
        removeStore: () throws -> Void = {
            try PersistentStoreReset.removeProductionStore()
        },
        clearNotifications: () -> Void = {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        },
        makeRoot: () throws -> AppCompositionRoot = { try AppCompositionRoot() }
    ) {
        guard case .recovery(let previous) = self else { return }

        AppDiagnosticsLogger.breadcrumb("persistence_store_reset_started")
        AppDiagnosticsLogger.persistBreadcrumbsNow()

        do {
            if !UITestingConfiguration.isEnabled {
                try removeStore()
                clearNotifications()
            }
            AppDiagnosticsLogger.breadcrumb("persistence_store_reset_succeeded")
            AppDiagnosticsLogger.persistBreadcrumbsNow()

            switch Self.bootstrap(makeRoot: makeRoot) {
            case .ready(let root):
                self = .ready(root)
            case .recovery(let fresh):
                self = .recovery(
                    RecoveryContext(
                        error: fresh.error,
                        originalError: previous.originalError ?? previous.error,
                        didResetStore: true
                    )
                )
            }
        } catch {
            AppDiagnosticsLogger.breadcrumb("persistence_store_reset_failed")
            AppDiagnosticsLogger.persistBreadcrumbsNow()
            AppDiagnosticsLogger.logger(for: .persistence).error(
                "persistence_store_reset_failed error=\(String(describing: error), privacy: .public)"
            )
            self = .recovery(
                RecoveryContext(
                    error: previous.error,
                    originalError: previous.originalError,
                    resetError: error,
                    didResetStore: previous.didResetStore
                )
            )
        }
    }

    private static func configureRuntime(_ root: AppCompositionRoot) {
        if !UITestingConfiguration.isEnabled {
            root.configureNonUITestRuntime()
        } else {
            #if DEBUG
                FirstRunPreferences.resetSearchResultsHintForTesting()
                FirstRunPreferences.resetFirstSearchCompletedForTesting()
            #endif
        }
    }
}
