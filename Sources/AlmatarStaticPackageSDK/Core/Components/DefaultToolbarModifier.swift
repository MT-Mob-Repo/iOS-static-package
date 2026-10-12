//
//  DefaultToolbarModifier.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Shared navigation toolbar used across Static Package screens.
///
/// On iOS 26+ leading/trailing items use plain SF Symbols so the system liquid-glass
/// toolbar styling applies (circular back, grouped trailing capsule).
/// On iOS 16–25 items fall back to frosted circular / capsule chips.
struct DefaultToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection

    var title: String
    var subtitle: String?
    var showsLeadingButton: Bool
    /// When `true`, leading control is a close (`xmark`); otherwise a back chevron.
    var usesCloseButton: Bool
    var isTitleBold: Bool
    var trailingActions: [ToolbarAction]
    var shouldDismiss: Bool
    var onBack: (() -> Void)?

    private var visibleTrailingActions: [ToolbarAction] {
        trailingActions.filter(\.isVisible)
    }

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            // System navigation title is reliable on iOS 26 liquid glass
            // (sits beside the back button). Custom `.principal` + AppTextModifier
            // often renders blank when host fonts/assets are missing.
            .navigationTitle(hasSubtitle ? "" : title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Always emit ToolbarItems — put conditions inside the *View* builder.
                // Bare `if` in ToolbarContentBuilder yields Optional<ToolbarContent>,
                // which Swift 6 rejects on our iOS 16 deployment target.
                ToolbarItem(placement: .principal) {
                    if hasSubtitle {
                        titleAndSubtitleView
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    if showsLeadingButton {
                        Button {
                            if shouldDismiss {
                                dismiss()
                            }
                            onBack?()
                        } label: {
                            if usesCloseButton {
                                closeButtonView
                            } else {
                                backButtonView
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !visibleTrailingActions.isEmpty {
                        trailingActionsView
                    }
                }
            }
    }

    private var hasSubtitle: Bool {
        guard let subtitle else { return false }
        return !subtitle.isEmpty
    }

    // MARK: - Title

    private var titleAndSubtitleView: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: isTitleBold ? .medium : .regular))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: Typography.Size.small, weight: .regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Leading

    @ViewBuilder
    private var backButtonView: some View {
        let chevron = layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left"

        if #available(iOS 26.0, *) {
            Image(systemName: chevron)
        } else {
            Image(systemName: chevron)
                .font(.body.weight(.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .frame(width: Layout.leadingButtonSize, height: Layout.leadingButtonSize)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        }
    }

    @ViewBuilder
    private var closeButtonView: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: "xmark")
        } else {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .frame(width: Layout.leadingButtonSize, height: Layout.leadingButtonSize)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        }
    }

    // MARK: - Trailing

    @ViewBuilder
    private var trailingActionsView: some View {
        if #available(iOS 26.0, *) {
            // Plain icons so the system applies liquid-glass grouping.
            HStack(spacing: Layout.trailingIconSpacing) {
                ForEach(visibleTrailingActions) { action in
                    Button(action: action.action) {
                        Image(systemName: action.systemImage)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            HStack(spacing: Layout.trailingIconSpacing) {
                ForEach(visibleTrailingActions) { action in
                    Button(action: action.action) {
                        Image(systemName: action.systemImage)
                            .font(.body.weight(.medium))
                            .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Layout.trailingCapsuleHorizontalPadding)
            .padding(.vertical, Layout.trailingCapsuleVerticalPadding)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
        }
    }

    private enum Layout {
        static let leadingButtonSize: CGFloat = 36
        static let trailingIconSpacing: CGFloat = 16
        static let trailingCapsuleHorizontalPadding: CGFloat = 14
        static let trailingCapsuleVerticalPadding: CGFloat = 10
    }
}

extension View {
    /// Applies the shared Static Package toolbar (iOS 26 liquid glass + iOS 16–25 fallback).
    ///
    /// Pass `trailingActions` to add dynamic trailing buttons (e.g. share / favourite).
    /// Hide an action with `isVisible: false` without removing it from the array.
    func defaultToolbar(
        title: String,
        subtitle: String? = nil,
        showsLeadingButton: Bool = true,
        usesCloseButton: Bool = false,
        isTitleBold: Bool = true,
        trailingActions: [ToolbarAction] = [],
        shouldDismiss: Bool = true,
        onBack: (() -> Void)? = nil
    ) -> some View {
        modifier(
            DefaultToolbarModifier(
                title: title,
                subtitle: subtitle,
                showsLeadingButton: showsLeadingButton,
                usesCloseButton: usesCloseButton,
                isTitleBold: isTitleBold,
                trailingActions: trailingActions,
                shouldDismiss: shouldDismiss,
                onBack: onBack
            )
        )
    }
}
