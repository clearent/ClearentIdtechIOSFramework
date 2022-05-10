//
//  ClearentConstants.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentConstants {
    // use a class from same package to identify the package
    class var bundle: Bundle {
        return Bundle(for: FlowDataProvider.self)
    }

    // MARK: - Colors

    enum Color {
        static let backgroundPrimary = UIColor(hexString: "#E5E5E5")
        static let backgroundSecondary01 = UIColor(hexString: "#FFFFFF")
        static let backgroundSecondary02 = UIColor(hexString: "#E1E2E8")
        static let backgroundSecondary03 = UIColor(hexString: "#EEEFF3")
        static let accent01 = UIColor(hexString: "#2FAC10")
        static let base01 = UIColor(hexString: "#272431")
        static let base02 = UIColor(hexString: "#6A6D7D")
        static let base03 = UIColor(hexString: "#000000")
        static let base04 = UIColor(hexString: "#FFFFFF")
    }

    // MARK: - Fonts

    enum Font {
        private static let sfProBold = "SFProText-Bold"
        private static let sfProRegular = "SFProText-Regular"
        private static let sfProMedium = "SFProText-Medium"

        static let regularExtraLarge = UIFont(name: sfProBold, size: 32)
        static let boldLarge = UIFont(name: sfProBold, size: 20)
        static let boldNormal = UIFont(name: sfProBold, size: 16)
        static let medium = UIFont(name: sfProMedium, size: 16)
        static let mediumSmall = UIFont(name: sfProMedium, size: 14)
        static let regularNormal = UIFont(name: sfProRegular, size: 14)
        static let regularSmall = UIFont(name: sfProRegular, size: 10)
    }

    // MARK: Assets

    enum IconName {
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
        static let pairingSuccessful = "pairingSuccessful"
    }
}
