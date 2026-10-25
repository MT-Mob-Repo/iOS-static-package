//
//  TextPriceConvertible.swift
//  AlmatarStaticPackageSDK
//
//  Created by mahmoud ismail on 21/10/2026.
//

import SwiftUI
import AlmatarSystemDesignSDK

protocol TextPriceConvertible {
    func asText() -> Text
}

extension Text: TextPriceConvertible {
    func asText() -> Text {
        return self
    }
}

struct SUITextPrice: View, TextPriceConvertible {
    var text: String
    var modifier = AppTextModifier(size: 16, fontWeight: .regular)
    
    var body: some View {
        asText()
    }
    
    func asText() -> Text {
        Text(AttributedString(text.getNewPriceFormat(fontName: modifier.fontName, fontSize: modifier.size)))
            .font(modifier.font)
    }
}
