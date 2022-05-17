//
//  ClearentConstants.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

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
        public static let backgroundSecondary04 = UIColor(hexString: "#E1E2E8")
        public static let accent01 = UIColor(hexString: "#2FAC10")
        public static let accent02 = UIColor(hexString: "#F44E27")
        public static let accent03 = UIColor(hexString: "#F4C15F")
        
        public static let base01 = UIColor(hexString: "#272431")
        public static let base02 = UIColor(hexString: "#6A6D7D")
        public static let base03 = UIColor(hexString: "#000000")
        public static let base04 = UIColor(hexString: "#FFFFFF")
        
        public static let warning = UIColor(hexString: "#C2210F")
    }

    // MARK: - Fonts

    public enum Font {
        private static let sfProBold = "SFProText-Bold"
        private static let sfProRegular = "SFProText-Regular"
        private static let sfProMedium = "SFProText-Medium"
        
        public static let regularExtraLarge = UIFont(name: sfProRegular, size: 32)
        static let regularMedium = UIFont(name: sfProRegular, size: 14)
        static let regularSmall = UIFont(name: sfProRegular, size: 10)
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

        // Information
        static let error = "error"
        static let warning = "warning"
        static let success = "success"

        // Pairing
        static let rightArrow = "right-arrow"
        static let reader = "reader"
        
        //Readers List
        static let expanded = "expanded"
        static let collapsed = "collapsed"
        static let pairingSuccessful = "pairingSuccessful"
    }
    
   public enum Size {
        public static let primaryButtonBorderWidth = 1.0
    }
}
