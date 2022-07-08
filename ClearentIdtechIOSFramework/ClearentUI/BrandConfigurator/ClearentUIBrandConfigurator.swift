//
//  BrandConfigurator.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 01.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

public class ClearentUIBrandConfigurator {
    public static var shared = ClearentUIBrandConfigurator()
    
    public var colorPalette: ClearentUIColors = ClearentColorsDefaultPalette()
    public var fonts: ClearentUIFonts = ClearentDefaultFonts()
}
