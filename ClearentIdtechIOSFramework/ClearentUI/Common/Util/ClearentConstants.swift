//
//  ClearentConstants.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 08.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

@objc public class ClearentConstants: NSObject {
    // use a class from same package to identify the package
    @objc public class var bundle: Bundle {
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
        
        // Manual Entry Card Info
        static let calendar = "calendar"
        static let exclamationMark = "redExclamationMark"
        static let expandMedium = "expandMedium"
        static let collapseMedium = "collapseMedium"
        static let deleteButton = "smallDeleteButton"
    }

    enum Size {
        public static let defaultButtonBorderWidth = 1.0
        public static let modalStackViewMargin = 32.0
    }
    
    enum Tips {
        public static let defaultTipPercentages = [15, 18, 20]
        public static let minCustomTipValue: Double = 0.01
    }
    
    public enum Amount {
        public static let maxNoOfCharacters = 11
    }
    
    enum Localized {
        enum Internet {
            public static let noConnection = "xsdk_internet_no_connection".localized
            public static let error = "xsdk_internet_error_title".localized
        }
        
        enum Bluetooth {
            public static let turnedOff = "xsdk_bluetooth_turned_off".localized
            public static let noPermission = "xsdk_bluetooth_no_permission".localized
            public static let error = "xsdk_bluetooth_error_title".localized
            public static let permissionError = "xsdk_bluetooth_permission_error_title".localized
        }
        
        enum ReaderDetails {
            public static let navigationItem = "xsdk_reader_details_nav_title".localized
            public static let connected = "xsdk_reader_details_connected".localized
            public static let autojoinTitle = "xsdk_reader_details_autojoin_title".localized
            public static let autojoinDescription = "xsdk_reader_details_autojoin_description".localized
            public static let readerName = "xsdk_reader_details_readername_title".localized
            public static let customReaderName = "xsdk_reader_details_custom_readername_title".localized
            public static let addCustomReaderName = "xsdk_reader_details_add_custom_readername_title".localized
            public static let serialNumber = "xsdk_reader_details_serialnumber_title".localized
            public static let version = "xsdk_reader_details_version_title".localized
            public static let removeReader = "xsdk_reader_details_remove_reader".localized
            public static let removeReaderAlertTitle = "xsdk_reader_details_remove_alert_title".localized
            public static let removeReaderAlertDescription = "xsdk_reader_details_remove_alert_message".localized
            public static let confirm = "xsdk_reader_details_remove_alert_confirm".localized
            public static let cancel = "xsdk_reader_details_remove_alert_cancel".localized
            public static let signalWeak = "xsdk_reader_details_signal_weak".localized
            public static let signalGood = "xsdk_reader_details_signal_good".localized
            public static let signalMedium = "xsdk_reader_details_signal_medium".localized
            public static let signalStatus = "xsdk_reader_details_signal_status".localized
            public static let batteryStatus = "xsdk_reader_details_battery_status".localized
        }
        
        enum ManualEntry {
            public static let header = "xsdk_payment_manual_entry_title".localized
            public static let footerCancel = "xsdk_payment_manual_entry_user_action_cancel".localized
            public static let footerConfirm = "xsdk_payment_manual_entry_user_action_confirm".localized
            public static let additionalSection = "xsdk_payment_manual_entry_additional_section_title".localized
            public static let cardNo = "xsdk_payment_manual_entry_card_no".localized
            public static let cardNoError = "xsdk_payment_manual_entry_card_no_error".localized
            public static let expirationDate = "xsdk_payment_manual_entry_exp_date".localized
            public static let expirationDatePlaceholder = "xsdk_payment_manual_entry_exp_date_placeholder".localized
            public static let expirationDateError = "xsdk_payment_manual_entry_exp_date_error".localized
            public static let csc = "xsdk_payment_manual_entry_csc".localized
            public static let cscPlaceholder = "xsdk_payment_manual_entry_csc_placeholder".localized
            public static let cscError = "xsdk_payment_manual_entry_csc_error".localized
            public static let cardHolderFirstName = "xsdk_payment_manual_entry_cardholder_first_name".localized
            public static let cardHolderFirstNameError = "xsdk_payment_manual_entry_cardholder_first_name_error".localized
            public static let cardHolderLastName = "xsdk_payment_manual_entry_cardholder_last_name".localized
            public static let cardHolderLastNameError = "xsdk_payment_manual_entry_cardholder_last_name_error".localized
            public static let billingZipCode = "xsdk_payment_manual_entry_billing_zip".localized
            public static let billingZipCodeError = "xsdk_payment_manual_entry_billing_zip_error".localized
            public static let invoiceNo = "xsdk_payment_manual_entry_invoice_no".localized
            public static let invoiceNoError = "xsdk_payment_manual_entry_invoice_no_error".localized
            public static let orderNo = "xsdk_payment_manual_entry_order_no".localized
            public static let orderNoError = "xsdk_payment_manual_entry_order_no_error".localized
            public static let companyName = "xsdk_payment_manual_entry_company_name".localized
            public static let companyNameError = "xsdk_payment_manual_entry_company_name_error".localized
            public static let customerID = "xsdk_payment_manual_entry_customer_id".localized
            public static let customerIDError = "xsdk_payment_manual_entry_customer_id_error".localized
            public static let shippingZipCode = "xsdk_payment_manual_entry_shipping_zip".localized
            public static let shippingZipCodeError = "xsdk_payment_manual_entry_shipping_zip_error".localized
        }
        
        enum Signature {
            public static let title = "xsdk_signature_title".localized
            public static let subtitle = "xsdk_signature_subtitle".localized
            public static let action = "xsdk_signature_action".localized
            public static let skip = "xsdk_signature_error_action_skip".localized
            public static let signatureUploadFailure = "xsdk_signature_upload_failure_title".localized
            public static let signatureUploadSuccessful = "xsdk_signature_upload_sucessful_title".localized
        }
        
        enum Keyboard {
            public static let done = "xsdk_keyboard_done".localized
        }
        
        enum Pairing {
            public static let connecting = "xsdk_pairing_connecting_reader".localized
            public static let connectionSuccessful = "xsdk_pairing_connection_sucessful".localized
            public static let pair = "xsdk_pairing_user_action_pair".localized
            public static let done = "xsdk_pairing_user_action_done".localized
            public static let pairNewReader = "xsdk_pairing_pair_new_reader".localized
            public static let settings = "xsdk_pairing_user_action_settings".localized
            public static let addName = "xsdk_pairing_user_action_addName".localized
            public static let later = "xsdk_pairing_user_action_later".localized
            public static let selectReader = "xsdk_pairing_select_reader".localized
            public static let noReadersFoundTitle = "xsdk_pairing_no_readers_found_title".localized
            public static let noReadersFoundDescription = "xsdk_pairing_no_readers_found_description".localized
            public static let readerName = "xsdk_pairing_reader_name".localized
            public static let readerNameInputHint = "xsdk_pairing_reader_name_input_hint".localized
            public static let readerRange = "xsdk_pairing_prepare_pairing_reader_range".localized
            public static let readerButton = "xsdk_pairing_prepare_pairing_reader_button".localized
            public static let addReaderName = "xsdk_pairing_add_name_to_reader".localized
            public static let renameReader = "xsdk_pairing_rename_your_reader".localized
            public static let readerSuccessfulPaired = "xsdk_pairing_paired_successful".localized
        }
        
        enum ReaderInfo {
            public static let idle = "xsdk_reader_signal_idle".localized
            public static let connected = "xsdk_reader_signal_connected".localized
        }
        
        enum ReadersList {
            public static let noReaderConnected = "xsdk_readers_list_no_reader_connected".localized
            public static let selectReader = "xsdk_readers_list_select_reader".localized
        }
        
        enum Error {
            public static let cancel = "xsdk_general_error_user_action_cancel".localized
            public static let retry = "xsdk_general_error_user_action_retry".localized
            public static let manualEntry = "xsdk_general_error_user_action_manually_enter_card".localized
            public static let generalErrorTitle = "xsdk_general_error_title".localized
            public static let generalErrorDescription = "xsdk_general_error_description".localized
            public static let readerError = "xsdk_reader_error_title".localized
        }
        
        enum FlowDataProvider {
            public static let transactionCompleted = "xsdk_payment_transaction_completed_description".localized
        }
        
        enum Tips {
            public static let percentageAndValueFormat = "xsdk_tips_percentage_and_value".localized
            public static let customAmount = "xsdk_tips_custom_amount".localized
            public static let transactionTip = "xsdk_tips_user_transaction_tip_title".localized
            public static let withoutTip = "xsdk_tips_user_action_transaction_without_tip".localized
            public static let withTip = "xsdk_tips_user_action_transaction_with_tip".localized
        }
    }
}
