//
//  Int+Extension.swift
//  AlmatarStaticPackageSDK
//
//  Created by Samar Mostafa on 08/11/2026.
//

import UIKit

extension Int {
    // Check Network Request Status
    func formatWithForceEnDisplay() -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
