//
//  Toast.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

// A toast requested deep in the view tree (e.g. inside a scroll view) is passed up through a
// preference and drawn by `toastHost()` at the bottom of the area it is applied to,
// then hides itself after a few seconds.

/// A short message shown at the bottom of the screen, e.g. "Saad Alotaibi removed.".
struct ToastMessage: Identifiable, Equatable {
    enum Style {
        case success
    }

    let id = UUID()
    let text: String
    var style: Style = .success
}

extension View {
    /// Shows `item` as a toast in the nearest `toastHost()`, then clears it after a few seconds.
    func toast(item: Binding<ToastMessage?>) -> some View {
        preference(
            key: ToastPreferenceKey.self,
            value: item.wrappedValue.map { message in
                ToastPresentation(message: message) {
                    // Only clear the toast it was shown for, not a newer one.
                    if item.wrappedValue?.id == message.id {
                        item.wrappedValue = nil
                    }
                }
            }
        )
    }

    /// Draws toasts requested by child views at the bottom of this view.
    func toastHost() -> some View {
        overlayPreferenceValue(ToastPreferenceKey.self, alignment: .bottom) { presentation in
            ToastOverlay(presentation: presentation)
        }
    }
}

// MARK: - View

struct ToastView: View {
    private enum Layout {
        static let iconSize: CGFloat = 20
        static let successIcon = "checkmark.circle"
        static let borderWidth: CGFloat = 1
        static let shadowColor = Color.black.opacity(0.12)
        static let shadowRadius: CGFloat = 12
        static let shadowYOffset: CGFloat = 4
    }

    let message: ToastMessage

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: Layout.successIcon)
                .font(.system(size: Layout.iconSize, weight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.iconComplementaryGreen)
                .accessibilityHidden(true)

            Text(message.text)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
        .shadow(color: Layout.shadowColor, radius: Layout.shadowRadius, y: Layout.shadowYOffset)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Host

private struct ToastPresentation: Equatable {
    let message: ToastMessage
    let dismiss: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.message == rhs.message }
}

private struct ToastPreferenceKey: PreferenceKey {
    static let defaultValue: ToastPresentation? = nil

    /// The last toast requested in the tree wins.
    static func reduce(value: inout ToastPresentation?, nextValue: () -> ToastPresentation?) {
        value = nextValue() ?? value
    }
}

private struct ToastOverlay: View {
    private enum Layout {
        /// How long a toast stays on screen.
        static let displayDuration: UInt64 = 3_000_000_000
        static let animationDuration: Double = 0.25
    }

    let presentation: ToastPresentation?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let presentation {
                ToastView(message: presentation.message)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.small)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(presentation.message.id)
                    .task(id: presentation.message.id) {
                        try? await Task.sleep(nanoseconds: Layout.displayDuration)
                        guard !Task.isCancelled else { return }
                        withAnimation(.easeIn(duration: Layout.animationDuration)) { presentation.dismiss() }
                    }
            }
        }
        .animation(.easeOut(duration: Layout.animationDuration), value: presentation?.message.id)
    }
}
