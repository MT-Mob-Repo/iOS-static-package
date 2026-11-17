//
//  SampleLandingPageDetailView.swift
//  MyApp
//
//  Opened when a landing page is tapped: calls `fetchLandingPage(id:)` and shows each of the
//  page's "packages" sections with the SDK's `getPackagesListView(section:)`.
//

import SwiftUI
import AlmatarStaticPackageSDK

struct SampleLandingPageDetailView: View {

    let pageId: String
    let title: String?

    @State private var page: LandingPage?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        content
            .navigationTitle(page?.title ?? title ?? "Landing page")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let page {
            let sections = page.packagesSections.filter { !$0.packages.isEmpty }
            if sections.isEmpty {
                Text("This landing page has no packages")
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                            AlmatarStaticPackageSDK.shared.getPackagesListView(section: section)
                        }
                    }
                    .padding(16)
                }
                .refreshable { await load() }
            }
        } else if let errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage).multilineTextAlignment(.center)
                Button("Retry") { Task { await load() } }
            }
            .padding(16)
        } else {
            ProgressView()
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            page = try await AlmatarStaticPackageSDK.shared.fetchLandingPage(id: pageId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
