//
//  func.swift
//  MyApp
//
//  Created by mahmoud ismail on 11/10/2026.
//


//
//  UIFont+Extension.swift
//  Almtaar
//
//  Created by Bassant Ashraf on 9/22/18.
//  Copyright © 2018 Moustafa Mohamed. All rights reserved.
//

import UIKit

extension UIFontDescriptor.AttributeName {
    static let nsctFontUIUsage =
    UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
}

extension UIFont {
    // swiftlint:disable force_unwrapping
    static var isOverrided: Bool = false
    
    private static func appFont(named key: String, size: CGFloat, fallbackWeight: UIFont.Weight = .regular) -> UIFont {
        let localizedFontName = key.localizedFont
        if let font = UIFont(name: localizedFontName, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size, weight: fallbackWeight)
    }
    
    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
        return appFont(named: "regular_font", size: size, fallbackWeight: .regular)
    }
    
    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return appFont(named: "bold_font", size: size, fallbackWeight: .bold)
    }
    
    @objc class func myItalicSystemFont(ofSize size: CGFloat) -> UIFont {
        return appFont(named: "light_font", size: size, fallbackWeight: .light)
    }
    
    @objc class func mySemiBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return appFont(named: "semibold_font", size: size, fallbackWeight: .semibold)
    }
    
    @objc class func myMediumBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return appFont(named: "medium-font", size: size, fallbackWeight: .medium)
    }
    
    @objc class func currencyFont(ofSize size: CGFloat) -> UIFont? {
        return UIFont(name: "sarRegular", size: size)
    }
    
    @objc convenience init(myCoder aDecoder: NSCoder) {
        if let fontDescriptor = aDecoder.decodeObject(forKey: "UIFontDescriptor") as? UIFontDescriptor {
            if let fontAttribute = fontDescriptor.fontAttributes[UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")] as? String {
                var fontName = ""
                switch fontAttribute {
                case "CTFontRegularUsage":
                    fontName = "regular_font".localizedFont
                case "CTFontDemiUsage":
                    fontName = "semibold_font".localizedFont
                case "CTFontBoldUsage", "CTFontEmphasizedUsage":
                    fontName = "bold_font".localizedFont
                case "CTFontObliqueUsage":
                    fontName = "light_font".localizedFont
                case "CTFontMediumUsage":
                    fontName = "medium-font".localizedFont
                default:
                    fontName = "regular_font".localizedFont
                }
                if let customFont = UIFont(name: fontName, size: fontDescriptor.pointSize) {
                    self.init(descriptor: customFont.fontDescriptor, size: fontDescriptor.pointSize)
                } else {
                    // Font not loaded or PostScript name mismatch — avoid force-unwrap crash
                    self.init(myCoder: aDecoder)
                }
            } else {
                self.init(myCoder: aDecoder)
            }
        } else {
            self.init(myCoder: aDecoder)
        }
    }
    
    class func overrideInitialize() {
        if self == UIFont.self, !isOverrided {
            isOverrided = true
            
            let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:)))
            let mySystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:)))
            method_exchangeImplementations(systemFontMethod!, mySystemFontMethod!)
            
            let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:)))
            let myBoldSystemFontMethod = class_getClassMethod(self, #selector(myBoldSystemFont(ofSize:)))
            method_exchangeImplementations(boldSystemFontMethod!, myBoldSystemFontMethod!)
            
            let italicSystemFontMethod = class_getClassMethod(self, #selector(italicSystemFont(ofSize:)))
            let myItalicSystemFontMethod = class_getClassMethod(self, #selector(myItalicSystemFont(ofSize:)))
            method_exchangeImplementations(italicSystemFontMethod!, myItalicSystemFontMethod!)
            
            let semiBoldSystemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:weight:)))
            let mySemiBoldSystemFontMethod = class_getClassMethod(self, #selector(mySemiBoldSystemFont(ofSize:)))
            method_exchangeImplementations(semiBoldSystemFontMethod!, mySemiBoldSystemFontMethod!)
            
            let mediumSystemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:weight:)))
            let myMediumSystemFontMethod = class_getClassMethod(self, #selector(myMediumBoldSystemFont(ofSize:)))
            method_exchangeImplementations(mediumSystemFontMethod!, myMediumSystemFontMethod!)
            
            
//            let sarFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:weight:)))
//            let mySARFontMethod = class_getClassMethod(self, #selector(currencyFont(ofSize:)))
//            method_exchangeImplementations(sarFontMethod!, mySARFontMethod!)
            
            
            let initCoderMethod = class_getInstanceMethod(self, #selector(UIFontDescriptor.init(coder:))) // Trick to get over the lack of UIFont.init(coder:))
            let myInitCoderMethod = class_getInstanceMethod(self, #selector(UIFont.init(myCoder:)))
            method_exchangeImplementations(initCoderMethod!, myInitCoderMethod!)
        }
    }
    // swiftlint:enable force_unwrapping
    
    func printFontsAdded() {
       
    }
    
}
