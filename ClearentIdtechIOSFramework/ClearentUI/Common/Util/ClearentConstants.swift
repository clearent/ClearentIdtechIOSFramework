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
        public static let backgroundPrimary02 = UIColor(hexString: "#000000")
        public static let backgroundSecondary01 = UIColor(hexString: "#FFFFFF")
        public static let backgroundSecondary02 = UIColor(hexString: "#E1E2E8")
        public static let backgroundSecondary03 = UIColor(hexString: "#EEEFF3")
        
        public static let accent01 = UIColor(hexString: "#2FAC10")
        
        public static let base01 = UIColor(hexString: "#272431")
        public static let base02 = UIColor(hexString: "#6A6D7D")
        public static let base03 = UIColor(hexString: "#000000")
        public static let base05 = UIColor(hexString: "#CBCBCB")

        public static let warning = UIColor(hexString: "#C2210F")
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
        public static let modalStackViewMargin = 32.0
    }
    
    public enum Tips {
        public static let defaultTipPercentages = [15, 18, 20]
        public static let minCustomTipValue: Double = 0.01
    }
    
    public enum Amount {
        public static let maxNoOfCharacters = 11
    }
}
