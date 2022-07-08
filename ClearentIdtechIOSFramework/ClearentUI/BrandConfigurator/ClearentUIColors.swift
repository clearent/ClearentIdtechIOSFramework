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
    
    // MARK: ClearentLoadingView
    
    // The loading view's fill color
    var loadingViewFillColor: UIColor { get }
    
    // MARK: ClearentPrimaryButton
    
    // The button's background color when it is enabled
    var enabledBackgroundColor: UIColor { get }
    
    // The button's background color when it is disabled
    var disabledBackgroundColor: UIColor { get }
    
    // The button's text color when it is enabled
    var enabledTextColor: UIColor { get }
    
    // The button's text color when it is disabled
    var disabledTextColor: UIColor { get }
    
    // The button's border color
    var buttonBorderColor: UIColor { get }
    
    // MARK: ClearentHintView
    
    // The background's color when this component is highlighted
    var highlightedBackgroundColor: UIColor { get }
    
    // The text color when this component is highlighted
    var highlightedTextColor: UIColor { get }
    
    // The default text color
    var defaultTextColor: UIColor { get }
    
    // MARK: ClearentTitleLabel
    
    // The label's text color (also used in ClearentReaderDetailsScreen)
    var titleLabelColor: UIColor { get }
    
    // MARK: ClearentSubtitleLabel
    
    // The label's text color (also used in ClearentReaderDetailsScreen)
    var subtitleLabelColor: UIColor { get }
    
    // MARK: ClearentReaderStatusHeaderView
    
    // The reader name label's color
    var readerNameColor: UIColor { get }
    
    // MARK: ClearentReaderConnectivityStatusView
    
    // The status label's color (also used in ClearentReaderStatusHeaderView)
    var readerStatusLabelColor: UIColor { get }
    
    // MARK: ClearentReadersTableViewCell
    
    // The reader name label's color (also used in ClearentPairingReaderItem)
    var readerNameLabelColor: UIColor { get }
    
    // The reader status icon's color when the reader is connected
    var readerStatusConnectedIconColor: UIColor { get }
    
    // The reader status icon's color when the reader is not connected
    var readerStatusNotConnectedIconColor: UIColor { get }
    
    // The cell's background color
    var readersCellBackgroundColor: UIColor { get }
    
    // MARK: ClearentTipCheckboxView
    
    // The border's color of the checkbox view when is selected
    var checkboxSelectedBorderColor: UIColor { get }
    
    // The border's color of the checkbox view when is not selected
    var checkboxUnselectedBorderColor: UIColor { get }
    
    // The percentage label's color
    var percentageLabelColor: UIColor { get }
    
    // The tip value label's color
    var tipLabelColor: UIColor { get }
    
    // The tip adjustment button's tint color
    var tipAdjustmentTintColor: UIColor { get }
    
    // MARK: ClearentTextField
    
    // The info label's color
    var infoLabelColor: UIColor { get }
    
    // MARK: ClearentReaderDetailsScreen
    
    // The navigation bar's tint color
    var navigationBarTintColor: UIColor { get }
    
    // The title's color
    var screenTitleColor: UIColor { get }
    
    // MARK: ClearentSignatureView
    
    // The description message's color
    var signatureDescriptionMessageColor: UIColor { get }
}
