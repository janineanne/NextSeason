//
//  SearchProfileFlowModifier.swift
//  NextSeason
//

import SwiftUI

/// Instruments profile-flow hooks: inject a search query and signal when results settle.
struct SearchProfileFlowModifier: ViewModifier {
    @Binding var profileFlowSearchQuery: String?
    @Bindable var viewModel: SearchViewModel
    let onProfileFlowSearchSettled: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onChange(of: profileFlowSearchQuery) { _, query in
                guard let query, !query.isEmpty else { return }
                viewModel.query = query
                profileFlowSearchQuery = nil
            }
            .onChange(of: viewModel.state) { _, state in
                guard ProfileFlowConfiguration.isEnabled else { return }
                switch state {
                case .results, .empty, .failed:
                    onProfileFlowSearchSettled?()
                default:
                    break
                }
            }
    }
}

extension View {
    func searchProfileFlow(
        profileFlowSearchQuery: Binding<String?>,
        viewModel: SearchViewModel,
        onProfileFlowSearchSettled: (() -> Void)?
    ) -> some View {
        modifier(
            SearchProfileFlowModifier(
                profileFlowSearchQuery: profileFlowSearchQuery,
                viewModel: viewModel,
                onProfileFlowSearchSettled: onProfileFlowSearchSettled
            )
        )
    }
}
