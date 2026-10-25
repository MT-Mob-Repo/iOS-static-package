//
//  ConfirmationPopup.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Card asking the user to confirm an action, e.g. "Remove visitor".
/// Show it centered over the whole screen with `.popup(item:content:)`.
struct ConfirmationPopup<Illustration: View>: View {
    let title: String
    /// Supports Markdown bold, e.g. "If you remove **Visitor 2**, ...".
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    /// Shows the confirm button in the danger style.
    let isDestructive: Bool
    let onConfirm: () -> Void
    let illustration: Illustration

    @Environment(\.dismissPopup) private var dismiss

    init(
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.illustration = illustration()
    }

    var body: some View {
        VStack(spacing: Spacing.medium) {
            header

            VStack(spacing: Spacing.medium) {
                illustration
                    .accessibilityHidden(true)

                Text(attributedMessage)
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.large)
            .frame(maxWidth: .infinity)
            .mediumSheetContainerBackground()
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxLarge))

            HStack(spacing: Spacing.small) {
                AppButton(
                    cancelTitle,
                    style: .tertiary,
                    size: .medium,
                    fullWidth: true,
                    cornerRadiusOverride: CornerRadius.round
                ) {
                    dismiss()
                }

                confirmButton
            }
            // As in the design, Cancel stays on the left and the action on the right in both languages.
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(Spacing.medium)
        .popupCardBackground()
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .padding(.horizontal, ConfirmationPopupLayout.closeButtonSize + Spacing.small)

            Button {
                dismiss()
            } label: {
                Image(systemName: ConfirmationPopupLayout.closeIcon)
                    .font(.system(size: ConfirmationPopupLayout.closeIconSize, weight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                    .frame(width: ConfirmationPopupLayout.closeButtonSize, height: ConfirmationPopupLayout.closeButtonSize)
                    .background(AlmatarColors.surfaceCard)
                    .applyEffectToButton(cornerRadius: CornerRadius.round, borderColor: nil)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizedKey.close.localized())
            .frame(maxWidth: .infinity, alignment: .leading)
            // As in the design, the close button stays on the left in both languages.
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    // MARK: - Message

    /// The message with the theme font; `**bold**` parts use the bold weight explicitly,
    /// because a custom font does not pick up Markdown emphasis on its own.
    private var attributedMessage: AttributedString {
        var text = (try? AttributedString(markdown: message)) ?? AttributedString(message)
        let regular = AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular).font
        let bold = AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.bold).font
        for run in text.runs {
            let isBold = run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
            text[run.range].font = isBold ? bold : regular
        }
        return text
    }

    // MARK: - Confirm

    @ViewBuilder
    private var confirmButton: some View {
        if isDestructive {
            // The design system's destructive button style is not final yet, so this one follows
            // the medium button metrics with the danger tokens.
            Button {
                onConfirm()
                dismiss()
            } label: {
                Text(confirmTitle)
                    .modifier(ButtonSize.medium.font)
                    .foregroundStyle(AlmatarColors.textComplementaryRed)
                    .padding(.horizontal, ButtonSize.medium.horizontalPadding)
                    .padding(.vertical, ButtonSize.medium.verticalPadding)
                    .frame(maxWidth: .infinity)
                    .background(AlmatarColors.surfaceComplementaryRed)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        } else {
            AppButton(
                confirmTitle,
                style: .primary,
                size: .medium,
                fullWidth: true,
                cornerRadiusOverride: CornerRadius.round
            ) {
                onConfirm()
                dismiss()
            }
        }
    }
}

private extension View {
    /// Glass card on iOS 26; a white card with a soft shadow on earlier versions.
    @ViewBuilder
    func popupCardBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.huge))
        } else {
            self
                .background(AlmatarColors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.huge))
                .shadow(
                    color: ConfirmationPopupLayout.shadowColor,
                    radius: ConfirmationPopupLayout.shadowRadius,
                    y: ConfirmationPopupLayout.shadowYOffset
                )
        }
    }
}

/// Static constants cannot live inside the generic popup types.
private enum ConfirmationPopupLayout {
    static let closeButtonSize: CGFloat = 44
    static let closeIconSize: CGFloat = 16
    static let closeIcon = "xmark"
    static let shadowColor = Color.black.opacity(0.12)
    static let shadowRadius: CGFloat = 24
    static let shadowYOffset: CGFloat = 8
}
