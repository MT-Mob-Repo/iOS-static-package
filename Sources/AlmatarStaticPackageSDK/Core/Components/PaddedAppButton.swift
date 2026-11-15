//
//  PaddedAppButton.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// The design system's `AppButton`, with its padding set by the caller.
///
/// `AppButton` takes its padding from `ButtonSize` and its button style is internal to the design system,
/// so this repeats its look and behavior: the same colors, font, corner radius, glass effect, press effect,
/// loading spinner and disabled state.
struct PaddedAppButton: View {
    let title: String
    let icon: Image?
    let style: ButtonStyleType
    let size: ButtonSize
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let isLoading: Bool
    let isDisabled: Bool
    let fullWidth: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    /// - Parameters:
    ///   - horizontalPadding: Defaults to the padding `AppButton` uses for `size`.
    ///   - verticalPadding: Defaults to the padding `AppButton` uses for `size`.
    init(
        _ title: String,
        icon: Image? = nil,
        style: ButtonStyleType = .primary,
        size: ButtonSize = .medium,
        horizontalPadding: CGFloat? = nil,
        verticalPadding: CGFloat? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.horizontalPadding = horizontalPadding ?? size.horizontalPadding
        self.verticalPadding = verticalPadding ?? size.verticalPadding
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xSmall) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(PaddedButtonStyle.spinnerScale)
                } else {
                    Text(title)
                        .modifier(size.font)
                        .fontWeight(Typography.Weight.semibold)

                    if let icon {
                        icon.modifier(size.font)
                    }
                }
            }
        }
        .focused($isFocused)
        .disabled(isDisabled)
        .buttonStyle(PaddedButtonStyle(
            isFocused: isFocused,
            style: style,
            size: size,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            fullWidth: fullWidth
        ))
        // As in `AppButton`: a loading button keeps its look but ignores taps.
        .allowsHitTesting(!isLoading)
    }
}

/// `AppButton`'s button style, with the padding passed in.
private struct PaddedButtonStyle: ButtonStyle {
    static let spinnerScale: CGFloat = 0.8
    private static let pressedScale: CGFloat = 0.98

    let isFocused: Bool
    let style: ButtonStyleType
    let size: ButtonSize
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let fullWidth: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .foregroundStyle(isEnabled ? style.textColor : style.textDisabledColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .applyEffectToButton(cornerRadius: size.cornerRadius, borderColor: borderColor)
            .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
            .animation(.spring(), value: isFocused)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return style.disabledBackgroundColor() }
        return isPressed ? style.pressedColor : style.backgroundColor
    }

    private var borderColor: Color {
        (isEnabled ? style.borderColor : style.disabledBorderColor) ?? .clear
    }
}
