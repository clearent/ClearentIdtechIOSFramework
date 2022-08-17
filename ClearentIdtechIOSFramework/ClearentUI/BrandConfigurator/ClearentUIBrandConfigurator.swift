//
//  BrandConfigurator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 01.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public class ClearentUIBrandConfigurator {
    public static var shared = ClearentUIBrandConfigurator()

    /// Offers the possibility to customize the colors used in UI components.
    public var colorPalette: ClearentUIColors = ClearentColorsDefaultPalette()

    /// Offers the possibility to customize the fonts used in UI components.
    public var fonts: ClearentUIFonts = ClearentDefaultFonts()

    /// Offers the possibility to customize the strings displayed in UI components. Set this variable with an array of key/value objects that represent the localization keys to be overridden and the corresponding desired texts
    /// If this is not set, the default values will be used for all texts.
    public var overriddenLocalizedStrings: [String: String]?
}
