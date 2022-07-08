//
//  ClearentColorsDefaultPalette.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 06.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentColorsDefaultPalette: ClearentUIColors {
    
    init() {}
    
    var loadingViewFillColor: UIColor { return UIColor(hexString: "#272431") }
    
    var enabledBackgroundColor: UIColor { return UIColor(hexString: "#2FAC10") }
    
    var disabledBackgroundColor: UIColor { UIColor(hexString: "#272431") }
    
    var enabledTextColor: UIColor { UIColor(hexString: "#FFFFFF") }
    
    var disabledTextColor: UIColor { UIColor(hexString: "#FFFFFF") }
    
    var buttonBorderColor: UIColor { return UIColor(hexString: "E1E2E8") }
    
    var highlightedBackgroundColor: UIColor { return UIColor(hexString: "#F44E27") }
    
    var highlightedTextColor: UIColor { return UIColor(hexString: "#FFFFFF") }
    
    var defaultTextColor: UIColor { return UIColor(hexString: "#000000") }
    
    var titleLabelColor: UIColor { return UIColor(hexString: "#272431") }
    
    var subtitleLabelColor: UIColor { return UIColor(hexString: "#6A6D7D") }
    
    var readerNameColor: UIColor { return UIColor(hexString: "1B181F") }
    
    var readerStatusLabelColor: UIColor { return UIColor(hexString: "#6A6D7D") }
    
    var readerNameLabelColor: UIColor { return UIColor(hexString: "1B181F") }
    
    var readerStatusConnectedIconColor: UIColor { return UIColor(hexString: "2FAC10") }
    
    var readerStatusNotConnectedIconColor: UIColor { return UIColor(hexString: "F4C15F") }
    
    var readersCellBackgroundColor: UIColor { return UIColor(hexString: "EEEFF3") }
    
    var checkboxSelectedBorderColor: UIColor { return UIColor(hexString: "272431") }
    
    var checkboxUnselectedBorderColor: UIColor { return UIColor(hexString: "999BA8") }
    
    var percentageLabelColor: UIColor { return UIColor(hexString: "272431") }
    
    var tipLabelColor: UIColor { return UIColor(hexString: "272431") }
    
    var tipAdjustmentTintColor: UIColor { return UIColor(hexString: "272431") }
    
    var infoLabelColor: UIColor { return UIColor(hexString: "1B181F") }
    
    var navigationBarTintColor: UIColor { return UIColor(hexString: "000000") }
    
    var screenTitleColor: UIColor { return UIColor(hexString: "000000") }
    
    var signatureDescriptionMessageColor: UIColor { return UIColor(hexString: "272431") }
}
