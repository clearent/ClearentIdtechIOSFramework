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
    
    public var colorPalette: ClearentUIColors = ClearentColorsDefaultPalette()
    public var fonts: ClearentUIFonts = ClearentDefaultFonts()
    
    /// Offers the posibility to customize strings displayed in the UI. Set this variable with an array of key/value objects that represent the localization keys to be overriden and the desired text
    /// If this is not set, the default value will be used for all texts.
    public var overridenLocalizedStrings: [String: String]?
}
