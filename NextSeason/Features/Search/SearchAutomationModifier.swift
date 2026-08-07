//
//  SearchAutomationModifier.swift
//  NextSeason
//

import SwiftUI

/// Reads automation environment hooks (set in `ContentView`) and bridges them to
/// `SearchViewModel` state. Feature views apply this modifier; they do not wire
/// the coordinator themselves.
///
/// Guards with `ProfileFlowConfiguration.isEnabled` so normal launches never
/// bump settlement tokens even though `ContentView` always installs the hooks.
struct SearchAutomationModifier: ViewModifier {
    @Environment(\.automationSearchQuery) private var automationSearchQuery
    @Environment(\.onAutomationSearchSettled) private var onAutomationSearchSettled
    @Bindable var viewModel: SearchViewModel

    func body(content: Content) -> some View {
        content
            .onChange(of: automationSearchQuery.wrappedValue) { _, query in
                guard let query, !query.isEmpty else { return }
                viewModel.query = query
                automationSearchQuery.wrappedValue = nil
            }
            .onChange(of: viewModel.state) { _, state in
                guard ProfileFlowConfiguration.isEnabled else { return }
                switch state {
                case .results, .empty, .failed:
                    onAutomationSearchSettled?()
                default:
                    break
                }
            }
    }
}

extension View {
    /// Connects search UI to optional automation hooks supplied via environment.
    func automationSearchHooks(viewModel: SearchViewModel) -> some View {
        modifier(SearchAutomationModifier(viewModel: viewModel))
    }
}
