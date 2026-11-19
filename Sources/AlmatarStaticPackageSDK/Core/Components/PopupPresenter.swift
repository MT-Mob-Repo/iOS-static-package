//
//  PopupPresenter.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import UIKit

// Popups are presented modally over the full screen from the app's top-most view controller,
// the same way UIKit shows custom alerts (`.overFullScreen`). The current screen stays in place
// underneath, and the popup covers everything on it, including the navigation bar.
//
// Using the host app's own presentation stack (rather than an extra `UIWindow`) means the popup:
// - inherits the host window's traits, including the light/dark style the host app forces;
// - is modal for VoiceOver, so the screen underneath is not read out;
// - is closed with the screen that presented it, and works with any number of scenes.

extension View {
    /// Shows the popup built by `content`, centered over the whole screen, while `item` is set.
    /// Inside the popup, `@Environment(\.dismissPopup)` closes it.
    func popup<Item: Identifiable, Popup: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Popup
    ) -> some View {
        modifier(PopupModifier(item: item, popup: content))
    }
}

/// Closes the popup it is injected into.
struct DismissPopupAction {
    fileprivate let action: () -> Void

    func callAsFunction() {
        action()
    }
}

extension EnvironmentValues {
    var dismissPopup: DismissPopupAction {
        get { self[DismissPopupKey.self] }
        set { self[DismissPopupKey.self] = newValue }
    }
}

private struct DismissPopupKey: EnvironmentKey {
    static let defaultValue = DismissPopupAction {}
}

// MARK: - Modifier

private struct PopupModifier<Item: Identifiable, Popup: View>: ViewModifier {
    @Binding var item: Item?
    let popup: (Item) -> Popup

    /// The popup is presented outside this view tree, so the layout direction is passed on explicitly.
    @Environment(\.layoutDirection) private var layoutDirection
    @StateObject private var presenter = PopupControllerPresenter()

    func body(content: Content) -> some View {
        content
            .onAppear { update() }
            .onChange(of: item?.id) { _ in update() }
            .onDisappear { presenter.hide() }
    }

    private func update() {
        guard let item else {
            presenter.hide()
            return
        }
        let binding = $item
        presenter.show(AnyView(
            popup(item)
                .environment(\.dismissPopup, DismissPopupAction { binding.wrappedValue = nil })
                .environment(\.layoutDirection, layoutDirection)
        ))
    }
}

// MARK: - Presentation

/// Owns the controller of one popup.
@MainActor
private final class PopupControllerPresenter: ObservableObject {
    private weak var controller: UIViewController?
    private let state = PopupState()
    /// Increases on every show/hide, so a delayed dismissal never closes a popup shown after it.
    private var generation = 0

    func show(_ popup: AnyView) {
        generation += 1
        state.popup = popup

        // Already on screen (or fading out): show the new content in the same controller.
        if controller?.presentingViewController != nil {
            setVisible(true)
            return
        }

        guard let presenter = TopViewControllerPresenter.topViewController else { return }
        let host = UIHostingController(rootView: PopupContainer(state: state))
        host.modalPresentationStyle = .overFullScreen
        host.view.backgroundColor = .clear
        // Matches the host app's theme when it set it on the SDK; otherwise the presenting
        // window's style is inherited.
        host.overrideUserInterfaceStyle = AlmatarStaticPackageSDK.shared.configuration.theme.userInterfaceStyle
        controller = host

        state.isVisible = false
        // Presented without UIKit's animation; the popup fades and scales in by itself.
        presenter.present(host, animated: false) { [weak self] in
            self?.setVisible(true)
        }
    }

    /// Fades the popup out, then dismisses its controller.
    func hide() {
        guard let controller else { return }
        generation += 1
        let current = generation
        setVisible(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + PopupLayout.animationDuration) { [weak self] in
            guard let self, self.generation == current else { return }
            self.controller = nil
            if controller.presentingViewController != nil {
                controller.dismiss(animated: false)
            }
        }
    }

    private func setVisible(_ isVisible: Bool) {
        withAnimation(isVisible
            ? .easeOut(duration: PopupLayout.animationDuration)
            : .easeIn(duration: PopupLayout.animationDuration)
        ) {
            state.isVisible = isVisible
        }
    }
}

@MainActor
private final class PopupState: ObservableObject {
    @Published var isVisible = false
    @Published var popup = AnyView(EmptyView())
}

private struct PopupContainer: View {
    @ObservedObject var state: PopupState

    var body: some View {
        ZStack {
            // Dark tint, kept see-through so the screen behind stays readable.
            Rectangle()
                .fill(.black)
                .opacity(PopupLayout.backdropOpacity)
                .ignoresSafeArea()

            state.popup
                .scaleEffect(state.isVisible ? 1 : PopupLayout.appearScale)
                .opacity(state.isVisible ? 1 : 0)
        }
        .opacity(state.isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum PopupLayout {
    static let backdropOpacity: Double = 0.1
    static let appearScale: CGFloat = 0.95
    static let animationDuration: Double = 0.2
}
