//
//  BookingConfirmationHeaderView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Success badge, title, subtitle and the copyable booking reference.
struct BookingConfirmationHeaderView: View {
    private enum Layout {
        static let badgeSize: CGFloat = 72
        static let badgeHaloSize: CGFloat = 84
        static let badgeIconSize: CGFloat = 32
        static let badgeIcon = "checkmark"
        static let haloOpacity: Double = 0.12
        // TODO: Replace with the design-system success color once available.
        static let successTint = AlmatarColors.iconComplementaryGreen
        static let copyIcon = "doc.on.doc"
        static let copiedIcon = "checkmark"
        static let copyIconSize: CGFloat = 14
        static let borderWidth: CGFloat = 1
        static let copiedFeedbackDuration: UInt64 = 1_500_000_000
    }

    let title: String
    let subtitle: String
    let bookingIdTitle: String
    let bookingId: String
    let copyAccessibilityLabel: String
    let onCopy: () -> Void

    @State private var isCopied = false

    var body: some View {
        VStack(spacing: Spacing.xLarge) {
            successBadge
                .padding(.bottom, Spacing.xSmall)

            VStack(spacing: Spacing.medium) {
                VStack(spacing: Spacing.xSmall) {
                    Text(title)
                        .modifier(AppTextModifier(size: Typography.Size.xLarge, fontWeight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                bookingIdChip
                    .padding(.top, Spacing.xSmall)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.medium)
        .padding(.top, Spacing.xLarge)
        .confirmationCard()
    }

    private var successBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.88, blue: 0.59),
                            Color(red: 0.43, green: 0.88, blue: 0.59).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            CheckmarkShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.88, green: 1.0, blue: 0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth:  Layout.badgeHaloSize * 0.115,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(
                    width: Layout.badgeHaloSize * 0.52,
                    height: Layout.badgeHaloSize * 0.40
                )
        }
        .frame(width: Layout.badgeHaloSize, height: Layout.badgeHaloSize)
    }

    private struct CheckmarkShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()

            path.move(
                to: CGPoint(
                    x: rect.width * 0.12,
                    y: rect.height * 0.48
                )
            )

            path.addLine(
                to: CGPoint(
                    x: rect.width * 0.40,
                    y: rect.height * 0.78
                )
            )

            path.addLine(
                to: CGPoint(
                    x: rect.width * 0.91,
                    y: rect.height * 0.18
                )
            )

            return path
        }
    }

    private var bookingIdChip: some View {
        HStack(spacing: Spacing.xSmall) {
            Text(bookingIdTitle)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            Text(bookingId)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Button {
                onCopy()
                showCopiedFeedback()
            } label: {
                Image(systemName: isCopied ? Layout.copiedIcon : Layout.copyIcon)
                    .font(.system(size: Layout.copyIconSize, weight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copyAccessibilityLabel)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(Capsule())
    }

    @MainActor
    private func showCopiedFeedback() {
        withAnimation { isCopied = true }
        Task {
            try? await Task.sleep(nanoseconds: Layout.copiedFeedbackDuration)
            withAnimation { isCopied = false }
        }
    }
}
