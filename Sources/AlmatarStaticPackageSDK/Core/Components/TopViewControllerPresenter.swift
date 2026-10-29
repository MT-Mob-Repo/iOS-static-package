//
//  TopViewControllerPresenter.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import UIKit

/// Presents SwiftUI screens full screen from the app's top-most view controller,
/// so they appear above everything regardless of how the host app shows the SDK screens.
@MainActor
enum TopViewControllerPresenter {
    /// Presents `view` full screen and returns its controller, or `nil` when there is no window.
    @discardableResult
    static func present<Content: View>(_ view: Content, animated: Bool = true) -> UIViewController? {
        guard let presenter = topViewController else { return nil }
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen
        presenter.present(controller, animated: animated)
        return controller
    }

    /// Dismisses `controller` (and anything it presented), then runs `completion`.
    static func dismiss(_ controller: UIViewController?, animated: Bool = true, completion: @escaping () -> Void) {
        guard let controller, controller.presentingViewController != nil else {
            completion()
            return
        }
        controller.dismiss(animated: animated, completion: completion)
    }

    /// The controller currently on top: the key window's root, then whatever it presents.
    static var topViewController: UIViewController? {
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }

    private static var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
    }
}
