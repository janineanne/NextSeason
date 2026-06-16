//
//  ShowDetailView.swift
//  NextSeason
//

import SwiftUI

/// Show detail: artwork, metadata, the derived next-season status, and a
/// formatted summary.
struct ShowDetailView: View {
    @State private var viewModel: ShowDetailViewModel

    init(show: Show, service: any TVMazeService = TVMazeClient()) {
        _viewModel = State(initialValue: ShowDetailViewModel(show: show, service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                nextSeasonSection
                aboutSection
                attribution
            }
            .padding()
        }
        .navigationTitle(viewModel.displayShow.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            poster
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayShow.name)
                    .font(.title2.bold())
                Label(viewModel.displayShow.status.displayLabel, systemImage: "tv")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let network = viewModel.displayShow.network {
                    Text(network)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !viewModel.displayShow.genres.isEmpty {
                    Text(viewModel.displayShow.genres.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var poster: some View {
        AsyncImage(url: viewModel.displayShow.posterMediumURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty, .failure:
                Rectangle()
                    .fill(.quaternary)
                    .overlay { Image(systemName: "tv").foregroundStyle(.secondary) }
            @unknown default:
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: 100, height: 150)
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var nextSeasonSection: some View {
        GroupBox("Next Season") {
            switch viewModel.loadState {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Checking next season…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .loaded:
                if let status = viewModel.nextSeasonStatus {
                    Label(status.headline, systemImage: status.systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        let html = viewModel.displayShow.summaryHTML
        let hasSummary = SummaryFormatter.hasDisplayableContent(html)
        if hasSummary || viewModel.displayShow.tvMazeURL != nil {
            VStack(alignment: .leading, spacing: 8) {
                if let html, hasSummary {
                    Text("About")
                        .font(.headline)
                    Text(SummaryFormatter.attributedString(from: html))
                        .font(.body)
                }
                if let url = viewModel.displayShow.tvMazeURL {
                    Link(destination: url) {
                        Label("View on TVMaze", systemImage: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attribution: some View {
        Text("Data provided by TVMaze")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)
    }
}

#Preview("With summary") {
    NavigationStack {
        ShowDetailView(show: .preview, service: PreviewTVMazeService(stub: .preview))
    }
}

#Preview("Missing summary") {
    NavigationStack {
        ShowDetailView(
            show: .previewMissingSummary,
            service: PreviewTVMazeService(stub: .previewMissingSummary)
        )
    }
}
