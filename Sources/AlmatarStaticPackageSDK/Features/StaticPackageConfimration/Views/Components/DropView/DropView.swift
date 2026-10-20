//
//  DropView.swift
//  Almtaar
//
//  Created by Sara Galal on 26/06/2024.
//  Copyright © 2024 almatar. All rights reserved.
//

import Foundation
import SwiftUI

struct DropView: UIViewRepresentable {
    var message: String
    var state: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        showToast(message: message, isSuccess: state)
    }

    private func showToast(message: String, isSuccess: Bool) {
        DispatchQueue.main.async {
            AppToast.show(message, isSuccess: isSuccess, duration: 2)
        }
    }
}
