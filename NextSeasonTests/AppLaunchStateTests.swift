//
//  AppLaunchStateTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct AppLaunchStateTests {
    @Test("Bootstrap presents recovery when composition fails")
    func bootstrapPresentsRecoveryOnFailure() {
        let state = AppLaunchState.bootstrap {
            throw StubLaunchError(message: "container failed")
        }

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery after composition failure")
            return
        }
        #expect(String(describing: context.error).contains("container failed"))
        #expect(context.resetError == nil)
        #expect(context.didResetStore == false)
        #expect(context.originalError == nil)
        let report = context.diagnosticsReport()
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("container failed"))
        #expect(report.contains("Persistence reset failure:") == false)
        #expect(report.contains("Local watchlist store reset: succeeded") == false)
        #expect(report.contains("Notifications enabled: Unavailable"))
        #expect(report.contains("Notifications enabled: false") == false)
        #expect(report.contains("Notifications enabled: true") == false)
    }

    @Test("Reset failure stays in recovery and is included in diagnostics")
    func resetFailureStaysInRecovery() throws {
        var state = AppLaunchState.bootstrap {
            throw StubLaunchError(message: "container failed")
        }

        state.resetLocalData(
            removeStore: { throw StubLaunchError(message: "disk full") },
            clearNotifications: {},
            makeRoot: { throw StubLaunchError(message: "should not retry") }
        )

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery after a failed reset")
            return
        }
        #expect(context.didResetStore == false)
        #expect(String(describing: context.error).contains("container failed"))
        let resetError = try #require(context.resetError)
        #expect(String(describing: resetError).contains("disk full"))
        let report = context.diagnosticsReport()
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("container failed"))
        #expect(report.contains("Persistence reset failure:"))
        #expect(report.contains("disk full"))
        #expect(report.contains("Local watchlist store reset: succeeded") == false)
    }

    @Test("Successful store removal with another open failure stays in recovery")
    func resetThenStillFailingStaysInRecovery() throws {
        var state = AppLaunchState.bootstrap {
            throw StubLaunchError(message: "first")
        }

        state.resetLocalData(
            removeStore: {},
            clearNotifications: {},
            makeRoot: { throw StubLaunchError(message: "second") }
        )

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery when the store still will not open")
            return
        }
        #expect(context.didResetStore)
        #expect(context.resetError == nil)
        #expect(String(describing: context.error).contains("second"))
        let originalError = try #require(context.originalError)
        #expect(String(describing: originalError).contains("first"))
        let report = context.diagnosticsReport()
        #expect(report.contains("Original persistence failure:"))
        #expect(report.contains("first"))
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("second"))
        #expect(report.contains("Local watchlist store reset: succeeded"))
        #expect(report.contains("Persistence reset failure:") == false)
    }

    @Test("Reset runs store removal and notification clearing before retrying composition")
    func resetOrchestratesRemovalThenNotificationsThenComposition() {
        var steps: [String] = []
        var state = AppLaunchState.bootstrap {
            throw StubLaunchError(message: "first")
        }

        state.resetLocalData(
            removeStore: { steps.append("removeStore") },
            clearNotifications: { steps.append("clearNotifications") },
            makeRoot: {
                steps.append("makeRoot")
                throw StubLaunchError(message: "second")
            }
        )

        #expect(steps == ["removeStore", "clearNotifications", "makeRoot"])
        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery when composition still fails")
            return
        }
        #expect(context.didResetStore)
    }
}

private struct StubLaunchError: Error, LocalizedError, CustomStringConvertible {
    let message: String
    var description: String { message }
    var errorDescription: String? { message }
}
