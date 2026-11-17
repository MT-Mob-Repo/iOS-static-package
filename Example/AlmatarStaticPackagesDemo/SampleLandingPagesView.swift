//
//  SampleLandingPagesView.swift
//  MyApp
//
//  Calls `fetchLandingPages()` and lists the landing pages: the hero page as a banner on top,
//  then a card for every other page. Tapping a page opens its packages.
//

import SwiftUI
import AlmatarStaticPackageSDK

struct SampleLandingPagesView: View {

    @State private var pages: [LandingPage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPage: LandingPage?

    private var heroPage: LandingPage? { pages.first(where: \.isHero) }
    private var otherPages: [LandingPage] { pages.filter { !$0.isHero } }

    var body: some View {
        content
            .navigationTitle("Landing pages")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .navigationDestination(isPresented: isShowingDetail) {
                if let selectedPage {
                    SampleLandingPageDetailView(pageId: selectedPage.id, title: selectedPage.title)
                }
            }
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { selectedPage != nil },
            set: { if !$0 { selectedPage = nil } }
        )
    }

    @ViewBuilder
    private var content: some View {
        if pages.isEmpty && isLoading {
            ProgressView()
        } else if pages.isEmpty, let errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage).multilineTextAlignment(.center)
                Button("Retry") { Task { await load() } }
            }
            .padding(16)
        } else if pages.isEmpty {
            Text("No landing pages").foregroundStyle(.secondary)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let heroPage {
                        Button { selectedPage = heroPage } label: { HeroBanner(page: heroPage) }
                            .buttonStyle(.plain)
                    }

                    Text("\(otherPages.count) landing pages")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(otherPages) { page in
                        Button { selectedPage = page } label: { LandingPageCard(page: page) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .refreshable { await load() }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            pages = try await AlmatarStaticPackageSDK.shared.fetchLandingPages()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Rows

private struct HeroBanner: View {
    let page: LandingPage

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: page.heroImageURL)
                .frame(height: 200)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                Text("HERO")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.85), in: Capsule())
                    .foregroundStyle(.black)
                Text(page.title ?? "")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            .padding(12)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct LandingPageCard: View {
    let page: LandingPage

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: page.imageURL)
                .frame(width: 96, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(page.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(2)
                if let description = page.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let slug = page.slug {
                    Text(slug)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct RemoteImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color(.tertiarySystemFill)
                    .overlay {
                        if phase.error != nil || url == nil {
                            Image(systemName: "photo").foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }
}
