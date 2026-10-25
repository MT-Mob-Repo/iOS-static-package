//
//  View+ReadHeight.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

extension View {
    /// Reports the view's height now and whenever it changes, e.g. to size a sheet to its content.
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onChange(proxy.size.height) }
                    .onChange(of: proxy.size.height) { onChange($0) }
            }
        )
    }
}
