//
//  PopupPresenter.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import UIKit

// Popups are drawn in a transparent window above the app's window, like system alerts.
// The current screen stays in place underneath, and the popup covers everything on it,
// including the navigation bar, centered on the full screen.

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

    /// Popups live in their own window, so the layout direction is passed on explicitly.
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var presenter = PopupWindowPresenter()

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
        presenter.show(
            popup(item)
                .environment(\.dismissPopup, DismissPopupAction { binding.wrappedValue = nil })
                .environment(\.layoutDirection, layoutDirection)
        )
    }
}

// MARK: - Window

/// Owns the overlay window of one popup.
@MainActor
private final class PopupWindowPresenter {
    private var window: UIWindow?
    private let state = PopupVisibility()

    func show<Popup: View>(_ popup: Popup) {
        guard let scene = Self.activeScene else { return }
        window?.isHidden = true

        let host = UIHostingController(rootView: PopupContainer(state: state, popup: popup))
        host.view.backgroundColor = .clear

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert
        window.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window

        state.isVisible = false
        DispatchQueue.main.async { [weak self] in
            withAnimation(.easeOut(duration: PopupLayout.animationDuration)) {
                self?.state.isVisible = true
            }
        }
    }

    /// Fades the popup out, then removes its window.
    func hide() {
        guard let window else { return }
        self.window = nil
        withAnimation(.easeIn(duration: PopupLayout.animationDuration)) {
            state.isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + PopupLayout.animationDuration) {
            window.isHidden = true
        }
    }

    private static var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

private final class PopupVisibility: ObservableObject {
    @Published var isVisible = false
}

private struct PopupContainer<Popup: View>: View {
    @ObservedObject var state: PopupVisibility
    let popup: Popup

    var body: some View {
        ZStack {
            // Dark blur, kept see-through so the screen behind stays readable.
            Rectangle()
                .fill(.ultraThinMaterial)
//                .fill(.black)
//                .environment(\.colorScheme, .dark)
                .opacity(PopupLayout.backdropOpacity)
                .ignoresSafeArea()

            popup
                .scaleEffect(state.isVisible ? 1 : PopupLayout.appearScale)
                .opacity(state.isVisible ? 1 : 0)
        }
        .opacity(state.isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum PopupLayout {
    static let backdropOpacity: Double = 0.6
    static let appearScale: CGFloat = 0.95
    static let animationDuration: Double = 0.2
}
