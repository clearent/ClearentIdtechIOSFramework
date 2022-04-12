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
        static let accent01 = UIColor(hexString: "#2FAC10")
        static let base01 = UIColor(hexString: "#272431")
        static let base02 = UIColor(hexString: "#6A6D7D")
        static let base03 = UIColor(hexString: "#000000")
    }
    
    // MARK: - Fonts
    
    enum Font {
        static let boldExtraLarge = UIFont.boldSystemFont(ofSize: 32)
        static let boldLarge = UIFont.boldSystemFont(ofSize: 20)
        static let regularLarge = UIFont.systemFont(ofSize: 16)
        static let regularMedium = UIFont.systemFont(ofSize: 14)
        static let regularSmall = UIFont.systemFont(ofSize: 10)
    }
    
    // MARK: Assets
    
    enum Assets {
        enum DeviceBatteryStatus {
            static let full = "full"
            static let high = "high"
            static let mediumHigh = "mediumHigh"
            static let medium = "medium"
            static let mediumLow = "mediumLow"
            static let low = "low"
        }
        
        enum DeviceConnectivityStatus {
            static let online = "onlineConnectivityStatus"
            static let idle = "idleConnectivityStatus"
        }
        
        enum UserInteraction {
            static let pressButtonOnReader = "pressButtonOnReader"
            static let cardInteraction = "cardInteraction"
        }
        
        enum Information {
            static let error = "error"
            static let warning = "warning"
        }
    }
}
