//
//  AlmatarFonts.swift
//  MyApp
//
//  Created by mahmoud ismail on 11/10/2026.
//


//
//  AlmatarFonts.swift
//  AlmatarSDK
//
//  Created by mahmoud ismail on 29/10/2024.
//

import UIKit

struct AlmatarFonts {

    private static var fontsRegistered = false

    struct AlmatarFont {
        let name: String
        let extensionType: String
        let bundle: Bundle

        init(name: String, extensionType: String, bundle: Bundle = .almatarFontsBundle) {
            self.name = name
            self.extensionType = extensionType
            self.bundle = bundle
        }
    }

    let fonts: [AlmatarFont] = [
        AlmatarFont(name: "regular_font", extensionType: "ttf"),
        AlmatarFont(name: "light_font", extensionType: "ttf"),
        AlmatarFont(name: "medium-font", extensionType: "ttf"),
        AlmatarFont(name: "semibold_font", extensionType: "ttf"),
        AlmatarFont(name: "bold_font", extensionType: "ttf"),
//        AlmatarFont(name: "sar_font", extensionType: "otf", bundle: .almatarBundle)
    ]

    static func register() {
        guard !fontsRegistered else { return }

        AlmatarFonts().fonts.forEach { font in
            guard let fontUrl = font.bundle.url(forResource: font.name, withExtension: font.extensionType) else {
                return
            }
            registerFont(from: fontUrl)
        }
        UIFont.overrideInitialize()
        fontsRegistered = true
    }

    private static func registerFont(from url: URL) {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
            return
        }
        guard let font = CGFont(fontDataProvider) else {
            return
        }
        var error: Unmanaged<CFError>?
        let registrationResult = CTFontManagerRegisterGraphicsFont(font, &error)

        if !registrationResult {
            if let errorRef = error?.takeRetainedValue() {
                let errorCode = CFErrorGetCode(errorRef)
                // Error code 305 means the font is already registered, which is fine
                if errorCode == 305 {
                } else {
                }
            } else {
            }
        }
    }
}
