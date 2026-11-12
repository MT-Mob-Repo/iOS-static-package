//
//  HomeView.swift
//  MyApp
//
//  Created by mahmoud ismail on 07/10/2026.
//

import SwiftUI
import AlmatarStaticPackageSDK
public import Combine

struct HomeView: View {
    
    @StateObject private var languageManager = LanguageManager()
    @State private var showPackagesSection = false
    @State private var showPackageDetails = false
    @State private var showPayment = false

    var body: some View {
        
        VStack(spacing: 20) {
            LanguageMenuButton(
                languageManager: languageManager
            )
            Button("Open packages list") {
                showPackagesSection = true
            }
            
            Button("show confirmatino") {
                AlmatarStaticPackageSDK.shared.presentPackageBookingConfirmation(id: "6ae339325da1f0139361b8f7")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(
            \.layoutDirection,
             languageManager.language.layoutDirection
        )
        .navigationDestination(isPresented: $showPackageDetails) {
        }
        .navigationDestination(isPresented: $showPackagesSection) {
            NavigationStack {
                ScrollView {
                    AlmatarStaticPackageSDK.shared.getPackagesListView(section: PackagesSection.mock)
                        .padding(16)
                }
            }
        }
        .navigationDestination(isPresented: $showPayment) {
            Text("Payment")
        }
        .onAppear {
            
        }
        .environmentObject(languageManager)
    }
       
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English"
        case .arabic: "العربية"
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .english: .leftToRight
        case .arabic: .rightToLeft
        }
    }
    
}

final class LanguageManager: ObservableObject {
    @Published var language: AppLanguage = .english

    func setLanguage(_ language: AppLanguage) {
        self.language = language
    }
}

struct LanguageMenuButton: View {
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageManager.setLanguage(language)
                    AlmatarStaticPackageSDK.shared.setLanguage(language == .english ? .english: .arabic)
                } label: {
                    HStack {
                        Text(language.title)

                        if languageManager.language == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(languageManager.language.title)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }
}


public extension PackagesSection {
    /// Sample section for previews and testing the integration.
    static let mock = PackagesSection(
        type: "packages",
        title: "Editor's Thrill Picks",
        packages: [
            PackageSummary(
                packageId: "6af31c2e9d4e3191c8cfa852",
                name: "Falcon's Flight Adventure",
                categories: [],
                duration: "2 Days",
                description: "Experience the world's tallest, fastest, and longest roller coaster in one unforgettable day.",
                imageUrl: "https://cdn.alpha.alm6ar.com/packages/riyadh-thumb-mobile-1792662373439.jpg",
                ribbons: [PackageRibbon(text: "Top sells", color: "#E5252A", icon: "trophy")],
                tags: ["Fast Pass", "Park Hopper", "VIP Access"],
                startingPrice: 1250,
                currency: "SAR"
            ),
            PackageSummary(
                packageId: "6af31c2e9d4e3191c8cfa852",
                name: "Splash Island Getaway",
                categories: ["Family fun", "Water park"],
                duration: "4 Days",
                description: "Lazy rivers, splash pads, and family-friendly slides for every age.",
                imageUrl: "https://cdn.alpha.alm6ar.com/packages/madinah-thumb-mobile-1792662352706.jpg",
                tags: ["Water Park", "Family Zone"],
                startingPrice: 850,
                currency: "SAR"
            )
        ]
    )
}
