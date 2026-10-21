//
//  File.swift
//  AlmatarStaticPackageSDK
//
//  Created by mahmoud ismail on 20/10/2026.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
