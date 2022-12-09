//
//  ServiceFeeExtension.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 05.12.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

extension ServiceFeeProgramType {
    var title: String {
        switch self {
        case .SURCHARGE:
            return ClearentConstants.Localized.ServiceFee.typeSurcharge
        case .NON_CASH_ADJUSTMENT:
            return ClearentConstants.Localized.ServiceFee.typeNCA
        case .EMPOWER_LITE:
            return ClearentConstants.Localized.ServiceFee.typeServiceLite
        case .SERVICE_FEE:
            return ClearentConstants.Localized.ServiceFee.typeService
        case .CONVENIENCE_FEE:
            return ClearentConstants.Localized.ServiceFee.typeConvenience
        }
    }
    
    var basePriceTitle: String {
        switch self {
        case .NON_CASH_ADJUSTMENT, .SERVICE_FEE:
            return ClearentConstants.Localized.ServiceFee.basePriceCash
        case .SURCHARGE, .EMPOWER_LITE:
            return ClearentConstants.Localized.ServiceFee.basePriceCashDebitCard
        case .CONVENIENCE_FEE:
            return ClearentConstants.Localized.ServiceFee.basePrice
        }
    }
    
    var adjustedPriceTitle: String {
        switch self {
        case .NON_CASH_ADJUSTMENT, .SERVICE_FEE:
            return ClearentConstants.Localized.ServiceFee.adjustedPriceCard
        case .SURCHARGE, .EMPOWER_LITE:
            return ClearentConstants.Localized.ServiceFee.adjustedPriceCreditCard
        case .CONVENIENCE_FEE:
            return ClearentConstants.Localized.ServiceFee.adjustedPriceTotal
        }
    }
    
    var description: String? {
        switch self {
        case .CONVENIENCE_FEE:
            return ClearentConstants.Localized.ServiceFee.description
        default:
            return nil
        }
    }
}
