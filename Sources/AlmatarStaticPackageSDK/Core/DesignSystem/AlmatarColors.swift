//
//  AlmatarColors.swift
//  AlmatarStaticPackageSDK
//

import Foundation
import SwiftUI

/// Almatar design system colors, loaded from the host app's `AlmatarColors.xcassets`.
struct AlmatarColors {

    static let surfacePrimaryBase = Color.app("SurfacePrimaryBase")
    static let surfacePrimaryHover = Color.app("SurfacePrimaryHover")
    static let surfacePrimaryPressed = Color.app("SurfacePrimaryPressed")
    static let surfacePrimaryDisabled = Color.app("SurfacePrimaryDisabled")
    static let surfaceComplementaryYellow = Color.app("SurfaceComplementaryYellow")
    static let surfaceComplementaryRed = Color.app("SurfaceComplementaryRed")
    static let surfaceComplementaryGreen = Color.app("SurfaceComplementaryGreen")
    static let surfaceComplementaryBlue = Color.app("SurfaceComplementaryBlue")
    static let surfaceBrandSecondary = Color.app("SurfaceBrandSecondary")
    static let surfaceDangerDark = Color.app("SurfaceDangerDark")
    
    static let borderPrimary = Color.app("BorderPrimary")
    static let borderPrimaryDisabled = Color.app("BorderPrimaryDisabled")
    static let borderWarning = Color.app("BorderWarning")

    static let textPrimaryInteractive = Color.app("TextPrimaryInteractive")
    static let textOnSurfacePrimary = Color.app("TextOnSurfacePrimary")
    static let textOnSurfacePrimaryDisabled = Color.app("TextOnSurfacePrimaryDisabled")

    static let iconPrimaryInteractive = Color.app("IconPrimaryInteractive")
    static let iconOnSurfacePrimary = Color.app("IconOnSurfacePrimary")
    static let iconOnSurfacePrimaryDisabled = Color.app("IconOnSurfacePrimaryDisabled")

    static let surfaceSecondaryBase = Color.app("SurfaceSecondaryBase")
    static let surfaceSecondaryHover = Color.app("SurfaceSecondaryHover")
    static let surfaceSecondaryPressed = Color.app("SurfaceSecondaryPressed")
    static let surfaceSecondarySelected = Color.app("SurfaceSecondarySelected")
    static let surfaceSecondaryRangeSelected = Color.app("SurfaceSecondaryRangeSelected")
    static let surfaceSecondaryDisabled = Color.app("SurfaceSecondaryDisabled")

    static let borderSecondary = Color.app("BorderSecondary")
    static let borderSecondaryDisabled = Color.app("BorderSecondaryDisabled")

    static let textSecondaryInteractive = Color.app("TextSecondaryInteractive")
    static let textOnSurfaceSecondary = Color.app("TextOnSurfaceSecondary")
    static let textOnSurfaceSecondaryDisabled = Color.app("TextOnSurfaceSecondaryDisabled")

    static let iconOnSurfaceSecondary = Color.app("IconOnSurfaceSecondary")
    static let iconOnSurfaceSecondaryDisabled = Color.app("IconOnSurfaceSecondaryDisabled")

    static let surfaceTertiaryBase = Color.app("SurfaceTertiaryBase")
    static let surfaceTertiaryHover = Color.app("SurfaceTertiaryHover")
    static let surfaceTertiaryPressed = Color.app("SurfaceTertiaryPressed")
    static let surfaceTertiaryDisabled = Color.app("SurfaceTertiaryDisabled")

    static let borderTertiary = Color.app("BorderTertiary")
    static let borderTertiaryDisabled = Color.app("BorderTertiaryDisabled")

    static let textTertiaryInteractive = Color.app("TextTertiaryInteractive")
    static let textOnSurfaceTertiary = Color.app("TextOnSurfaceTertiary")
    static let textOnSurfaceTertiaryDisabled = Color.app("TextOnSurfaceTertiaryDisabled")
    static let textComplementaryYellow = Color.app("TextComplementaryYellow")
    static let textComplementaryRed = Color.app("TextComplementaryRed")
    static let textComplementaryGreen = Color.app("TextComplementaryGreen")
    static let textComplementaryBlue = Color.app("TextComplementaryBlue")
    
    static let iconTertiaryInteractive = Color.app("IconTertiaryInteractive")
    static let iconOnSurfaceTertirary = Color.app("IconOnSurfaceTertirary")
    static let iconOnSurfaceTertiraryDisabled = Color.app("IconOnSurfaceTertiraryDisabled")
    static let iconComplementaryYellow = Color.app("IconComplementaryYellow")
    static let iconComplementaryGreen = Color.app("IconComplementaryGreen")
    static let iconComplementaryBlue = Color.app("IconComplementaryBlue")

    // MARK: - Neutral / Background
    static let backgroundPrimary = Color.app("BackgroundPrimary")
    static let backgroundSecondary = Color.app("BackgroundSecondaryDefault")

    static let surfaceCard = Color.app("SurfaceCard")
    static let surfaceCardSecondary = Color.app("SurfaceCardSecondary")
    static let surfaceLine = Color.app("SurfaceLine")

    static let surfaceInputBase = Color.app("SurfaceInputBase")
    static let surfaceInputDisabled = Color.app("SurfaceInputDisabled")
    static let surfaceInputActive = Color.app("SurfaceInputActive")

    static let borderDefaultCard = Color.app("BorderDefaultCard")
    static let borderInputActive = Color.app("BorderInputActive")

    static let textHighlightStatic = Color.app("TextHighlightStatic")
    static let textPrimaryStatic = Color.app("TextPrimaryStatic")
    static let textSecondaryStatic = Color.app("TextSecondaryStatic")
    static let textDisabled = Color.app("TextDisabled")

    static let iconHighlightStatic = Color.app("IconHighlightStatic")
    static let iconPrimaryStatic = Color.app("IconPrimaryStatic")
    static let iconSecondaryStatic = Color.app("IconSecondaryStatic")
    static let iconDisabled = Color.app("IconDisabled")
    static let iconInfo = Color.app("IconInfo")
    static let iconStar = Color.app("IconStar")
    
    static let surfaceInfo = Color.app("SurfaceInfo")
    static let borderInfo = Color.app("BorderInfo")
    static let textInfo = Color.app("TextInfo")
    static let longing = Color.app("Longing")
    
    static let surfaceSuccessDark = Color.app("SurfaceSuccessDark")
    static let surfaceSuccessLight = Color.app("Surface-success-light")
}

extension Color {
    /// Loads a color from the host app bundle.
    static func app(_ name: String) -> Color {
        Color(name, bundle: .main)
    }
}
