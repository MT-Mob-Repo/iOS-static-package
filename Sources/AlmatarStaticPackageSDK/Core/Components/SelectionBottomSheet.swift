//
//  SelectionBottomSheet.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// A group of choices in `SelectionBottomSheet`, e.g. the dates of one month.
struct SelectionSheetSection<Item: Identifiable & Hashable>: Identifiable {
    let id: String
    /// e.g. "July 2026"; `nil` hides the section header.
    let title: String?
    /// Trailing header text, e.g. "2 Available".
    let caption: String?
    let items: [Item]
}

/// Static constants cannot live inside the generic `SelectionBottomSheet`.
private enum SelectionSheetLayout {
    static let closeButtonSize: CGFloat = 40
    static let closeIconSize: CGFloat = 16
    static let closeIcon = "xmark"
    static let borderWidth: CGFloat = 1
    static let selectedBorderWidth: CGFloat = 1.5
    static let placeholderHeight: CGFloat = 300
}


/// Bottom sheet with a title, a close button and a list of selectable cards, optionally grouped.
///
/// - With `confirmTitle`, tapping a card only highlights it and the footer button confirms.
/// - Without it, tapping a card selects it and closes the sheet.
///
/// Present it with `.sheet`; the content of each card comes from `row`.
/// The sheet sizes itself to its content and scrolls once the content is taller than the screen.
struct SelectionBottomSheet<Item: Identifiable & Hashable, Row: View>: View {
    let title: String
    let sections: [SelectionSheetSection<Item>]
    let confirmTitle: String?
    let onSelect: (Item) -> Void
    let row: (Item, Bool) -> Row

    @State private var selection: Item?
    @State private var headerHeight: CGFloat = .zero
    @State private var listHeight: CGFloat = .zero
    @State private var footerHeight: CGFloat = .zero
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        sections: [SelectionSheetSection<Item>],
        selected: Item?,
        confirmTitle: String? = nil,
        onSelect: @escaping (Item) -> Void,
        @ViewBuilder row: @escaping (_ item: Item, _ isSelected: Bool) -> Row
    ) {
        self.title = title
        self.sections = sections
        self.confirmTitle = confirmTitle
        self.onSelect = onSelect
        self.row = row
        _selection = State(initialValue: selected)
    }

    var body: some View {
        VStack(spacing: Spacing.zero) {
            header
                .readHeight { headerHeight = $0 }

            ScrollViewReader { proxy in
                ScrollView {
                    // A plain VStack, not a lazy one, so the measured height covers every row.
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        ForEach(sections) { sectionView($0) }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.xxxSmall)
                    .padding(.bottom, Spacing.medium)
                    .readHeight { listHeight = $0 }
                }
                .onAppear {
                    if let selection { proxy.scrollTo(selection.id, anchor: .center) }
                }
            }

            if let confirmTitle {
                footer(confirmTitle)
                    .readHeight { footerHeight = $0 }
            }
        }
        .background(AlmatarColors.surfaceCard.ignoresSafeArea())
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
    }

    /// Header, list and footer together; the system caps the sheet at full screen height.
    private var contentHeight: CGFloat {
        let total = headerHeight + listHeight + footerHeight
        // Until measured, open at a sensible height instead of a zero-height sheet.
        return total > .zero ? total : SelectionSheetLayout.placeholderHeight
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.small) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Image(systemName: SelectionSheetLayout.closeIcon)
                    .font(.system(size: SelectionSheetLayout.closeIconSize, weight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                    .frame(width: SelectionSheetLayout.closeButtonSize, height: SelectionSheetLayout.closeButtonSize)
                    .background(AlmatarColors.surfaceCardSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizedKey.close.localized())
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.large)
        .padding(.bottom, Spacing.medium)
    }

    // MARK: - Sections

    private func sectionView(_ section: SelectionSheetSection<Item>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if section.title != nil || section.caption != nil {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    if let title = section.title {
                        Text(title)
                            .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.regular))
                            .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    }
                    Spacer(minLength: Spacing.zero)
                    if let caption = section.caption {
                        Text(caption)
                            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                            .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    }
                }
                .padding(.top, Spacing.xSmall)
            }

            ForEach(section.items) { itemCard($0) }
        }
    }

    private func itemCard(_ item: Item) -> some View {
        let isSelected = item == selection

        return Button {
            select(item)
        } label: {
            row(item, isSelected)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? AlmatarColors.surfaceSecondaryBase : AlmatarColors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .stroke(
                            isSelected ? AlmatarColors.borderPrimary : AlmatarColors.borderDefaultCard,
                            lineWidth: isSelected ? SelectionSheetLayout.selectedBorderWidth : SelectionSheetLayout.borderWidth
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        }
        .buttonStyle(.plain)
        .id(item.id)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Footer

    private func footer(_ confirmTitle: String) -> some View {
        VStack(spacing: Spacing.zero) {
            Rectangle()
                .fill(AlmatarColors.borderDefaultCard)
                .frame(height: SelectionSheetLayout.borderWidth)

            PrimaryButton(confirmTitle, isDisabled: selection == nil, addPadding: false) {
                guard let selection else { return }
                onSelect(selection)
                dismiss()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.medium)
        }
    }

    private func select(_ item: Item) {
        selection = item
        // Without a confirm button the tap is the confirmation.
        guard confirmTitle == nil else { return }
        onSelect(item)
        dismiss()
    }
}
