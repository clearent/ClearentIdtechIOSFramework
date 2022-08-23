//
//  ClearentUIFont.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 06.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public protocol ClearentUIFonts {
    
    // MARK: - ClearentPrimaryButton

    var primaryButtonTextFont: UIFont { get }

    // MARK: - ClearentHintView

    var hintTextFont: UIFont { get }

    // MARK: - ClearentTitleLabel
    
    var modalTitleFont: UIFont { get }

    // MARK: - ClearentSubtitleLabel
    
    var modalSubtitleFont: UIFont { get }

    // MARK: - ClearentPairingReaderItem, ClearentReadersTableViewCell
    
    var listItemTextFont: UIFont { get }

    // MARK: - ClearentReaderStatusHeaderView
    
    var readerNameTextFont: UIFont { get }

    // MARK: - ClearentReaderStatusHeaderView, ClearentReaderConnectivityStatusView
    
    var statusLabelFont: UIFont { get }

    // MARK: - ClearentTipCheckboxView
    
    var tipItemTextFont: UIFont { get }

    // MARK: - ClearentTextField
    
    var customNameInfoLabelFont: UIFont { get }

    var customNameInputLabelFont: UIFont { get }

    // MARK: - ClearentReaderDetailsScreen
    
    var screenTitleFont: UIFont { get }
    
    // MARK: - ClearentSignatureView
    
    var signatureSubtitleFont: UIFont { get }

    // MARK: - ClearentLabelSwitch, ClearentInfoWithIcon, ClearentLabelWithIcon
    
    var detailScreenItemTitleFont: UIFont { get }
    
    var detailScreenItemSubtitleFont: UIFont { get }
     
    var detailScreenItemDescriptionFont: UIFont { get }
    
    // MARK: - ClearentPaymentHeaderView, ClearentPaymentTextField
    
    var paymentViewTitleLabelFont: UIFont { get }
    
    var paymentFieldTitleLabelFont: UIFont { get }
    
    var errorMessageLabelFont: UIFont { get }
    
    // MARK: - ClearentPaymentSectionHeaderView
    
    var sectionTitleLabelFont: UIFont { get }
    
    // MARK: - ClearentPaymentTextField
    
    var textfieldPlaceholder: UIFont { get }
}
