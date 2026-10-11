//
//  RemoteIconView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

/// Shows an icon from a remote URL, or from an SF Symbol name when the value is not a URL.
struct RemoteIconView: View {
    private enum Constants {
        static let httpScheme = "http"
    }

    let icon: String
    let size: CGFloat
    let tint: Color

    var body: some View {
        Group {
            if let url = remoteURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                } placeholder: {
                    Color.clear
                }
            } else {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
            }
        }
        .foregroundStyle(tint)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var remoteURL: URL? {
        guard icon.lowercased().hasPrefix(Constants.httpScheme) else { return nil }
        return URL(string: icon)
    }
}
