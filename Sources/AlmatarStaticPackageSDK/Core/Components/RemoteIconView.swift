//
//  RemoteIconView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

/// Shows an icon from a remote URL, or from a local symbol when the value is not a URL.
/// Icon keys sent by the API (e.g. "group", "thrill") are mapped to SF Symbols by `PackageIcon`.
struct RemoteIconView: View {
    private enum Constants {
        static let httpScheme = "http"
    }

    let icon: String
    let size: CGFloat
    var tint: Color? = nil

    var body: some View {
        Group {
            if let url = remoteURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
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
        .modifier(OptionalForegroundStyle(tint: tint))
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var remoteURL: URL? {
        guard icon.lowercased().hasPrefix(Constants.httpScheme) else { return nil }
        return URL(string: icon)
    }
}

private struct OptionalForegroundStyle: ViewModifier {
    let tint: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let tint {
            content.foregroundStyle(tint)
        } else {
            content
        }
    }
}
