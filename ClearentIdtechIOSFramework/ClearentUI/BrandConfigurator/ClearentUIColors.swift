//
//  ClearentUIColors.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 01.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

public protocol ClearentUIColors {
    
    // MARK: - ClearentLoadingView
    
    // The loading view's fill color
    var loadingViewFillColor: UIColor { get }
    
    // MARK: - ClearentPrimaryButton
    
    // The background's color for button of type filled
    var filledBackgroundColor: UIColor { get }
    
    // The text's color for button of type filled
    var filledButtonTextColor: UIColor { get }
    
    // The background's color for button of type filled and disabled
    var filledDisabledBackgroundColor: UIColor { get }
    
    // The text's color for button of type filled and disabled
    var filledDisabledButtonTextColor: UIColor { get }
    
    // The border's color for button of type bordered
    var borderColor: UIColor { get }
    
    // The background's color for button of type bordered
    var borderedBackgroundColor: UIColor { get }
    
    // The text's color for button of type bordered
    var borderedButtonTextColor: UIColor { get }
    
    // MARK: - ClearentHintView
    
    // The background's color when this component is highlighted
    var highlightedBackgroundColor: UIColor { get }
    
    // The text color when this component is highlighted
    var highlightedTextColor: UIColor { get }
    
    // The default text color
    var defaultTextColor: UIColor { get }
    
    // MARK: - ClearentTitleLabel
    
    // The label's text color (also used in ClearentReaderDetailsScreen)
    var titleLabelColor: UIColor { get }
    
    // MARK: - ClearentSubtitleLabel
    
    // The label's text color (also used in ClearentReaderDetailsScreen)
    var subtitleLabelColor: UIColor { get }
    
    // MARK: - ClearentReaderStatusHeaderView
    
    // The reader name label's color
    var readerNameColor: UIColor { get }
    
    // MARK: - ClearentReaderConnectivityStatusView
    
    // The status label's color (also used in ClearentReaderStatusHeaderView)
    var readerStatusLabelColor: UIColor { get }
    
    // MARK: - ClearentReadersTableViewCell
    
    // The reader name label's color (also used in ClearentPairingReaderItem)
    var readerNameLabelColor: UIColor { get }
    
    // The reader status icon's color when the reader is connected
    var readerStatusConnectedIconColor: UIColor { get }
    
    // The reader status icon's color when the reader is not connected
    var readerStatusNotConnectedIconColor: UIColor { get }
    
    // The cell's background color
    var readersCellBackgroundColor: UIColor { get }
    
    // MARK: - ClearentTipCheckboxView
    
    // The border's color of the checkbox view when is selected
    var checkboxSelectedBorderColor: UIColor { get }
    
    // The border's color of the checkbox view when is not selected
    var checkboxUnselectedBorderColor: UIColor { get }
    
    // The tip label's color
    var tipLabelColor: UIColor { get }
    
    // MARK: ClearentTextField
    
    // The info label's color
    var infoLabelColor: UIColor { get }
    
    // MARK: - ClearentReaderDetailsScreen
    
    // The navigation bar's tint color
    var navigationBarTintColor: UIColor { get }
    
    // The title's color
    var screenTitleColor: UIColor { get }
    
    // The remove reader button's border color
    var removeReaderButtonBorderColor: UIColor { get }
    
    // The remove reader button's text color
    var removeReaderButtonTextColor: UIColor { get }
    
    // MARK: - ClearentSignatureView
    
    // The description message's color
    var signatureDescriptionMessageColor: UIColor { get }
    
    // MARK: - ClearentManualEntryFormView
    
    // The color of header, fields and section displayed on Manual Entry Form view
    var manualPaymentTitleColor: UIColor { get }
    
    // The error message's text color
    var manualPaymentErrorMessageColor: UIColor { get }
    
    // MARK: - ClearentPaymentTextField
    
    // The payment textfield placeholder's color
    var manualPaymentTextFieldPlaceholder: UIColor { get }
}
