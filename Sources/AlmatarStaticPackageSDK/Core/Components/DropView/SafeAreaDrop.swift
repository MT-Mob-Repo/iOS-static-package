//
//  SafeAreaDrop.swift
//  Almtaar
//
//  Copyright © 2026 almatar. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Shared entry point

enum AppToast {
    /// iOS 16 and below: SwiftyDrop. iOS 17+: SafeAreaDrop (respects safeAreaInsets.top).
    static func show(_ message: String, isSuccess: Bool, duration: Double = 4.0) {
        let toastState = isSuccess ? CustomToast.success : CustomToast.warning
        SafeAreaDrop.down(message, state: toastState, duration: duration)
    }
}

enum CustomToast: ToastStatable {
    case success
    case warning
    var backgroundColor: UIColor? {
        switch self {
        case .success: return UIColor(red: 66, green: 178, blue: 83)
        case .warning: return UIColor(red: 245, green: 166, blue: 35)
        }
    }
    var font: UIFont? {
        return UIFont.systemFont(ofSize: 12, weight: .semibold)
    }
    var textColor: UIColor? {
        return UIColor.white
    }
    var blurEffect: UIBlurEffect? {
        return nil
    }
    var textAlignment: NSTextAlignment? {
        return .center
    }
}

// MARK: - Safe-area aware toast (iOS 17+)

protocol ToastStatable {
    var backgroundColor: UIColor? { get }
    var blurEffect: UIBlurEffect? { get }
    var font: UIFont? { get }
    var textColor: UIColor? { get }
    var textAlignment: NSTextAlignment? { get }
}

/// Top banner toast that respects `safeAreaInsets.top` (Notch / Dynamic Island).
final class SafeAreaDrop: UIView {
    private static let presetDuration: TimeInterval = 4.0

    private var statusLabel: UILabel!
    private let statusTopMargin: CGFloat = 10.0
    private let statusBottomMargin: CGFloat = 10.0
    private var topConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var duration: TimeInterval = SafeAreaDrop.presetDuration
    private var upTimer: Timer?
    private var startTop: CGFloat?
    private var action: (() -> Void)?

    private var safeAreaTopInset: CGFloat {
        if let inset = SafeAreaDrop.keyWindow?.safeAreaInsets.top, inset > 0 {
            return inset
        }
        return SafeAreaDrop.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height
            ?? UIApplication.shared.statusBarFrame.height
    }

    private var minimumHeight: CGFloat { safeAreaTopInset + 44.0 }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    convenience init(duration: Double) {
        self.init(frame: .zero)
        self.duration = duration
        scheduleUpTimer(duration)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    deinit {
        stopUpTimer()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        stopUpTimer()
        removeFromSuperview()
    }

    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        updateHeight()
    }

    private func up() {
        scheduleUpTimer(0.0)
    }

    @objc private func upFromTimer(_ timer: Timer) {
        if let interval = timer.userInfo as? Double {
            SafeAreaDrop.up(self, interval: interval)
        }
    }

    private func scheduleUpTimer(_ after: Double, interval: Double = 0.25) {
        stopUpTimer()
        upTimer = Timer.scheduledTimer(
            timeInterval: after,
            target: self,
            selector: #selector(upFromTimer(_:)),
            userInfo: interval,
            repeats: false
        )
    }

    private func stopUpTimer() {
        upTimer?.invalidate()
        upTimer = nil
    }

    private func updateHeight() {
        var height: CGFloat = 0
        height += safeAreaTopInset
        height += statusTopMargin
        height += statusLabel.frame.size.height
        height += statusBottomMargin
        heightConstraint?.constant = max(height, minimumHeight)
        layoutIfNeeded()
    }

    class func down(_ status: String, state: ToastStatable, duration: Double = 4.0, action: (() -> Void)? = nil) {
        show(status, state: state, duration: duration, action: action)
    }

    private class func show(_ status: String, state: ToastStatable, duration: Double, action: (() -> Void)?) {
        upAll()
        guard let window = keyWindow else { return }

        let drop = SafeAreaDrop(duration: duration)
        window.addSubview(drop)

        let heightConstraint = NSLayoutConstraint(
            item: drop,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: 100.0
        )
        drop.addConstraint(heightConstraint)
        drop.heightConstraint = heightConstraint

        let topConstraint = NSLayoutConstraint(
            item: drop,
            attribute: .top,
            relatedBy: .equal,
            toItem: window,
            attribute: .top,
            multiplier: 1.0,
            constant: -heightConstraint.constant
        )
        drop.topConstraint = topConstraint

        window.addConstraints([
            topConstraint,
            NSLayoutConstraint(item: drop, attribute: .left, relatedBy: .equal, toItem: window, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: drop, attribute: .right, relatedBy: .equal, toItem: window, attribute: .right, multiplier: 1.0, constant: 0)
        ])

        drop.setup(status, state: state)
        drop.action = action
        drop.updateHeight()

        guard let superview = drop.superview else { return }
        superview.layoutIfNeeded()

        topConstraint.constant = 0
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: { superview.layoutIfNeeded() },
            completion: nil
        )
    }

    private class func up(_ drop: SafeAreaDrop, interval: TimeInterval) {
        guard let heightConstant = drop.heightConstraint?.constant else { return }
        drop.topConstraint?.constant = -heightConstant
        guard let superview = drop.superview else { return }

        UIView.animate(
            withDuration: interval,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn],
            animations: { superview.layoutIfNeeded() },
            completion: { _ in drop.removeFromSuperview() }
        )
    }

    class func upAll() {
        guard let window = keyWindow else { return }
        window.subviews.compactMap { $0 as? SafeAreaDrop }.forEach { $0.up() }
    }

    private func setup(_ status: String, state: ToastStatable) {
        translatesAutoresizingMaskIntoConstraints = false
        var labelParentView: UIView = self

        let backgroundView = UIView(frame: .zero)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = state.backgroundColor
        addSubview(backgroundView)
        addConstraints([
            NSLayoutConstraint(item: backgroundView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: -UIScreen.main.bounds.height),
            NSLayoutConstraint(item: backgroundView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])

        if let blurEffect = state.blurEffect {
            let visualEffectView = UIVisualEffectView(effect: blurEffect)
            visualEffectView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(visualEffectView)
            addConstraints([
                NSLayoutConstraint(item: visualEffectView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: visualEffectView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: -UIScreen.main.bounds.height),
                NSLayoutConstraint(item: visualEffectView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: visualEffectView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])

            let vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
            vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
            visualEffectView.contentView.addSubview(vibrancyEffectView)
            visualEffectView.contentView.addConstraints([
                NSLayoutConstraint(item: vibrancyEffectView, attribute: .left, relatedBy: .equal, toItem: visualEffectView.contentView, attribute: .leftMargin, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: vibrancyEffectView, attribute: .top, relatedBy: .equal, toItem: visualEffectView.contentView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: vibrancyEffectView, attribute: .right, relatedBy: .equal, toItem: visualEffectView.contentView, attribute: .rightMargin, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: vibrancyEffectView, attribute: .bottom, relatedBy: .equal, toItem: visualEffectView.contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
            labelParentView = vibrancyEffectView.contentView
        }

        let statusLabel = UILabel(frame: .zero)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.numberOfLines = 0
        statusLabel.font = state.font ?? .systemFont(ofSize: 17)
        statusLabel.textAlignment = state.textAlignment ?? .center
        statusLabel.text = status
        statusLabel.textColor = state.textColor ?? .white
        labelParentView.addSubview(statusLabel)
        labelParentView.addConstraints([
            NSLayoutConstraint(item: statusLabel, attribute: .left, relatedBy: .equal, toItem: labelParentView, attribute: .leftMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusLabel, attribute: .right, relatedBy: .equal, toItem: labelParentView, attribute: .rightMargin, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusLabel, attribute: .bottom, relatedBy: .equal, toItem: labelParentView, attribute: .bottom, multiplier: 1.0, constant: -statusBottomMargin)
        ])
        self.statusLabel = statusLabel

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        layoutIfNeeded()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(up(_:))))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))
    }

    @objc private func up(_ sender: AnyObject) {
        action?()
        up()
    }

    @objc private func pan(_ sender: AnyObject) {
        guard let pan = sender as? UIPanGestureRecognizer else { return }
        switch pan.state {
        case .began:
            stopUpTimer()
            guard let topConstant = topConstraint?.constant else { return }
            startTop = topConstant
        case .changed:
            guard let window, let startTop else { break }
            let translation = pan.translation(in: window)
            let top = startTop + translation.y
            topConstraint?.constant = top > 0 ? top * 0.2 : top
        case .ended:
            startTop = nil
            guard let topConstraint else { return }
            if topConstraint.constant < 0 {
                scheduleUpTimer(0.0, interval: 0.1)
            } else {
                scheduleUpTimer(duration)
                guard let superview else { return }
                topConstraint.constant = 0
                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [.allowUserInteraction, .curveEaseOut],
                    animations: { superview.layoutIfNeeded() },
                    completion: nil
                )
            }
        case .failed, .cancelled:
            startTop = nil
            scheduleUpTimer(2.0)
        case .possible:
            break
        @unknown default:
            break
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
    
    /// Converts this `UIColor` instance to a 1x1 `UIImage` instance and returns it.
    ///
    /// - Returns: `self` as a 1x1 `UIImage`.
    func toImage() -> UIImage {
        //
        UIGraphicsBeginImageContext(CGSize(width: 0.5, height: 0.5))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    func lighter(by percentage: CGFloat) -> UIColor? {
        adjust(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat) -> UIColor? {
        adjust(by: abs(percentage) * -1)
    }
    
    private func adjust(by percentage: CGFloat) -> UIColor? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return .init(red: min(red + percentage / 100, 1.0),
                         green: min(green + percentage / 100, 1.0),
                         blue: min(blue + percentage / 100, 1.0),
                         alpha: alpha)
        }
        
        return nil
    }
}
