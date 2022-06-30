//
//  ClearentConstants.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentConstants {
    // use a class from same package to identify the package
    public class var bundle: Bundle {
        return Bundle(for: FlowDataProvider.self)
    }

    // MARK: - Colors

    public enum Color {
        public static let backgroundPrimary01 = UIColor(hexString: "#E5E5E5")
        public static let backgroundPrimary02 = UIColor(hexString: "#000000")
        public static let backgroundSecondary01 = UIColor(hexString: "#FFFFFF")
        public static let backgroundSecondary02 = UIColor(hexString: "#E1E2E8")
        public static let backgroundSecondary03 = UIColor(hexString: "#EEEFF3")
        public static let accent01 = UIColor(hexString: "#2FAC10")
        public static let accent02 = UIColor(hexString: "#F4C15F")
        public static let accent03 = UIColor(hexString: "#F44E27")
        
        public static let base01 = UIColor(hexString: "#272431")
        public static let base02 = UIColor(hexString: "#6A6D7D")
        public static let base03 = UIColor(hexString: "#000000")
        public static let base04 = UIColor(hexString: "#999BA8")
        public static let base05 = UIColor(hexString: "#B9B9B9")
        
        public static let warning = UIColor(hexString: "#C2210F")
    }

    // MARK: - Fonts

    public enum Font {
        private static let sfProDisplayBold = "SFProDisplay-Bold"
        private static let sfProTextBold = "SFProText-Bold"
        private static let sfProTextMedium = "SFProText-Medium"

        public static let proDisplayBoldExtraLarge = UIFont(name: sfProDisplayBold, size: 32)
        public static let proDisplayBoldLarge = UIFont(name: sfProDisplayBold, size: 20) ?? UIFont.systemFont(ofSize: 20)
        
        public static let proTextBoldNormal = UIFont(name: sfProTextBold, size: 14)
        public static let proTextLarge = UIFont(name: sfProTextMedium, size: 16)
        public static let proTextNormal = UIFont(name: sfProTextMedium, size: 14)
        public static let proTextSmall = UIFont(name: sfProTextMedium, size: 12)
        public static let proTextExtraSmall = UIFont(name: sfProTextMedium, size: 10)
    }

    // MARK: Assets

    public enum IconName {
        // Reader Battery Status
        static let batteryFull = "full"
        static let batteryHigh = "high"
        static let batteryMediumHigh = "mediumHigh"
        static let batteryMedium = "medium"
        static let batteryMediumLow = "mediumLow"
        static let batteryLow = "low"

        // Reader Signal Status
        static let goodSignal = "goodSignal"
        static let mediumSignal = "mediumSignal"
        static let weakSignal = "weakSignal"
        static let signalIdle = "noSignal"

        // User Interaction
        static let pressButtonOnReader = "pressButtonOnReader"
        static let cardInteraction = "cardInteraction"
        static let decreaseTip = "decreaseTipButton"
        static let increaseTip = "increaseTipButton"

        // Information
        static let error = "error"
        static let warning = "warning"
        static let success = "success"

        // Pairing
        static let rightArrow = "right-arrow"
        static let reader = "reader"
        static let bubbleTail = "bubbleTail"

        // Readers List
        static let expanded = "expanded"
        static let collapsed = "collapsed"
        static let pairingSuccessful = "pairingSuccessful"
        static let details = "details"

        // Reader details
        static let navigationArrow = "left-arrow"
        static let editButton = "smallEditButton"
    }

    public enum Size {
        public static let defaultButtonBorderWidth = 1.0
    }
    
    public enum Tips {
        public static let defaultTipPercentages = [15.0, 18.0, 20.0]
        public static let customTipAdjustFactor: Double = 1.0
        public static let defaultCustomTipValue: Double = 5.0
    }
}
