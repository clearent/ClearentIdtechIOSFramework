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
    
    // MARK: - Internal
    
    internal enum KeychainService {
        static let account = "xplor_sdk_account"
        static let serviceName = "xplor_sdk_offline_mode_service"
    }
    
    internal enum Messaging {
        static let suppress = "SUPPRESS"
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
        static let staticCardInteraction = "cardInteraction"
        static let decreaseTip = "decreaseTipButton"
        static let increaseTip = "increaseTipButton"

        // Information
        static let error = "error"
        static let warning = "warning"
        static let smallWarning = "small_warning"
        static let success = "success"

        // Pairing
        static let rightArrow = "right-arrow"
        public static let rightArrowLarge = "right-arrow-large"
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
        
        // Offline transactions report
        static let separatorLine = "report_line"
    }
    
    enum AnimationName {
        static let cardInteraction = "card_animation"
    }

    enum Size {
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
    
    // MARK: - Localizable

    enum Localized {
        enum Internet {
            public static let noConnection = "xsdk_internet_no_connection".localized
            public static let error = "xsdk_internet_error_title".localized
            public static let noConnectionDoneButton = "xsdk_internet_no_connection_btn_ok".localized
        }
        
        enum Bluetooth {
            public static let turnedOff = "xsdk_bluetooth_turned_off".localized
            public static let noPermission = "xsdk_bluetooth_no_permission".localized
            public static let error = "xsdk_bluetooth_error_title".localized
            public static let permissionError = "xsdk_bluetooth_permission_error_title".localized
        }
        
        enum OfflineReport {
            public static let navigationItem = "xsdk_offline_report_nav_title".localized
            public static let clearButtonTitle = "xsdk_offline_report_clear_report".localized
            public static let saveLogButtonTitle = "xsdk_offline_report_save_error_log".localized
            public static let infoLabeltext = "xsdk_offline_info".localized
            
            public static let approvedCount = "xsdk_offline_report_entry_approved_count".localized
            public static let approvedAmount = "xsdk_offline_report_entry_approved_amount".localized
            public static let declinedCount = "xsdk_offline_report_entry_declined_count".localized
            public static let declinedAmount = "xsdk_offline_report_entry_declined_amount".localized
            public static let errorCount = "xsdk_offline_report_entry_error_count".localized
            public static let errorAmount = "xsdk_offline_report_entry_error_amount".localized
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
        
        enum ReaderInteraction {
            public static let tap = "xsdk_payment_transaction_reader_tap".localized
            public static let insert = "xsdk_payment_transaction_reader_insert".localized
            public static let slide = "xsdk_payment_transaction_reader_slide".localized
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
            public static let signatureUploadSuccessfully = "xsdk_signature_upload_sucessful_title".localized
            public static let signatureAcceptedSuccessfully = "xsdk_signature_accepted_succesful_title".localized
        }
        
        enum EmailReceipt {
            public static let emailReceiptOptionTitle = "xsdk_email_option_title".localized
            public static let emailReceiptOptionButtonYes = "xsdk_email_option_button_yes".localized
            public static let emailReceiptOptionButtonNo = "xsdk_email_option_button_no".localized
            public static let emailFormTitle = "xsdk_email_form_title".localized
            public static let emailFormSubtitle = "xsdk_email_form_subtitle".localized
            public static let emailFormInputPlaceholder = "xsdk_email_form_input_placeholder".localized
            public static let emailFormInvalidAddress = "xsdk_email_form_invalid_address".localized
            public static let emailFormButtonSend = "xsdk_email_form_button_send".localized
            public static let emailFormButtonSkip = "xsdk_email_form_button_skip".localized
            public static let emailFormSendReceiptSuccess = "xsdk_email_form_send_receipt_success".localized
            public static let emailFormSendReceiptFailed = "xsdk_email_form_send_receipt_failed".localized
            public static let emailFormSaveEmailSuccess = "xsdk_email_form_save_email_success".localized            
            public static let emailFormOfflineModeInfo = "xsdk_email_form_offline_mode_info".localized
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
            public static let errorCode = "xsdk_general_error_code".localized
            public static let errorMessage = "xsdk_general_error_message".localized
            public static let transactionID = "xsdk_general_error_transaction_id".localized
            public static let exchangeID = "xsdk_general_error_exchange_id".localized
            public static let parseHttpResponseErrorTitle = "xsdk_response_parsing_error".localized
            public static let parseHttpResponseErrorMessage = "xsdk_http_response_parsing_error_message".localized
        }
        
        enum FlowDataProvider {
            public static let transactionCompleted = "xsdk_payment_transaction_completed_description".localized
            public static let transactionCompletedSurchargeAvoided = "xsdk_payment_transaction_completed_avoided_surcharge".localized
            public static let transactionAccepted = "xsdk_payment_transaction_accepted_description".localized
            public static let transactionNotAccepted = "xsdk_payment_transaction_not_accepted_description".localized
        }
        
        enum Tips {
            public static let percentageAndValueFormat = "xsdk_tips_percentage_and_value".localized
            public static let customAmount = "xsdk_tips_custom_amount".localized
            public static let transactionTip = "xsdk_tips_user_transaction_tip_title".localized
            public static let withoutTip = "xsdk_tips_user_action_transaction_without_tip".localized
            public static let withTip = "xsdk_tips_user_action_transaction_with_tip".localized
        }
        
        enum ServiceFee {
            public static let typeSurcharge = "xsdk_service_fee_type_surcharge".localized
            public static let typeNCA = "xsdk_service_fee_type_nca".localized
            public static let typeServiceLite = "xsdk_service_fee_type_service_lite".localized
            public static let typeService = "xsdk_service_fee_type_service".localized
            public static let typeConvenience = "xsdk_service_fee_type_convenience".localized
            public static let basePrice = "xsdk_service_fee_base_price".localized
            public static let basePriceCash = "xsdk_service_fee_base_price_cash".localized
            public static let basePriceCashDebitCard = "xsdk_service_fee_base_price_cash_debit_card".localized
            public static let adjustedPriceCard = "xsdk_service_fee_adjusted_price_card".localized
            public static let adjustedPriceCreditCard = "xsdk_service_fee_adjusted_price_credit_card".localized
            public static let adjustedPriceTotal = "xsdk_service_fee_adjusted_price_total".localized
            public static let description = "xsdk_service_fee_description".localized
        }
        
        enum OfflineMode {
            public static let enableOfflineMode = "xsdk_offline_mode_enable_title".localized
            public static let offlineModeConfirmOption = "xsdk_offline_mode_confirm_option".localized
            public static let offlineModeCancelOption = "xsdk_offline_mode_cancel_option".localized
            public static let offlineModeConfirmationMessage = "xsdk_offline_mode_confirmation_message".localized
            public static let offlineModeConfirmationMessageConfirm = "xsdk_offline_mode_confirmation_proceed".localized
            public static let offlineModeConfirmationMessageCancel = "xsdk_offline_mode_confirmation_cancel".localized
            public static let offlineModeWarningMessageTitle = "xsdk_offline_mode_warning_message_title".localized
            public static let offlineModeWarningMessageDescription = "xsdk_offline_mode_warning_message_description".localized
            public static let offlineModeWarningConfirmationDescription = "xsdk_offline_mode_warning_confirmation_description".localized
            public static let offlineModeEnabled = "xsdk_offline_mode_enabled".localized
            public static let offlineModeWarningMessageConfirm = "xsdk_offline_mode_warning_message_confirmation".localized
            public static let offlineModeEncryptionWarningMessage = "xsdk_offline_mode_encryption_message".localized
            
            public static let offlineModeReportTitle = "xsdk_offline_mode_report_title".localized
            public static let offlineModeMechantID = "xsdk_offline_mode_report_merchant_id".localized
            public static let offlineModeTerminalID = "xsdk_offline_mode_report_terminal_id".localized
            public static let offlineModeReportDate = "xsdk_offline_mode_report_report_date".localized
            public static let offlineModeReportTime = "xsdk_offline_mode_report_report_time".localized
            public static let offlineModeReportOfflineDate = "xsdk_offline_mode_report_offline_date".localized
            public static let offlineModeReportOfflineTime = "xsdk_offline_mode_report_offline_time".localized
            public static let offlineModeReportTransactionID = "xsdk_offline_mode_report_transaction_id".localized
            public static let offlineModeReportExternalRefID = "xsdk_offline_mode_report_external_ref_id".localized
            public static let offlineModeReportCardHolderName = "xsdk_offline_mode_report_cardholder_name".localized
            public static let offlineModeReportCardType = "xsdk_offline_mode_report_card_type".localized
            public static let offlineModeReportLastFourDigits = "xsdk_offline_mode_report_last_four_digits".localized
            public static let offlineModeReportExpirationDate = "xsdk_offline_mode_report_expiration_date".localized
            public static let offlineModeReportAmount = "xsdk_offline_mode_report_amount".localized
            public static let offlineModeReportTipAmount = "xsdk_offline_mode_report_tip_amount".localized
            public static let offlineModeReportEmpowerAmount = "xsdk_offline_mode_report_empower_amount".localized
            public static let offlineModeReportTotalAmount = "xsdk_offline_mode_report_total_amount".localized
            public static let offlineModeReportCustomerID = "xsdk_offline_mode_report_customer_id".localized
            public static let offlineModeReportOrderID = "xsdk_offline_mode_report_order_id".localized
            public static let offlineModeReportInvoice = "xsdk_offline_mode_report_invoice".localized
            public static let offlineModeReportBillingAddress = "xsdk_offline_mode_report_billing_address".localized
            public static let offlineModeReportShippingAddress = "xsdk_offline_mode_report_shipping_address".localized
            public static let offlineModeReportSoftwareType = "xsdk_offline_mode_report_software_type".localized
            public static let offlineModeReportSoftwareVersion = "xsdk_offline_mode_report_software_version".localized
            public static let offlineModeReportError = "xsdk_offline_mode_report_error".localized
            public static let offlineModeReportErrorDate = "xsdk_offline_mode_report_error_date".localized
            public static let offlineModeReportErrorTime = "xsdk_offline_mode_report_error_time".localized
        }
        
        enum Settings {
            public static let settingsOfflineModeTitle = "xsdk_settings_title".localized
            public static let settingsReadersPlaceholder = "xsdk_settings_readers_placeholder".localized
            public static let settingsOfflineModeSubtitle = "xsdk_settings_offline_subtitle".localized
            public static let settingsOfflineSwitchEnabled = "xsdk_settings_offline_switch_enabled".localized
            public static let settingsOfflineSwitchEnablePrompt = "xsdk_settings_offline_switch_enable_prompt".localized
            public static let settingsOfflinePendingTransactions = "xsdk_settings_offline_pending_transactions".localized
            public static let settingsOfflineOnePendingTransactions = "xsdk_settings_offline_one_pending_transaction".localized
            public static let settingsOfflineUploadErrors = "xsdk_settings_offline_upload_errors".localized
            public static let settingsOfflineUploadSuccess = "xsdk_settings_offline_upload_success".localized
            public static let settingsOfflineButtonProcess = "xsdk_settings_offline_btn_process".localized
            public static let settingsOfflineButtonReport = "xsdk_settings_offline_btn_report".localized
            public static let settingsOfflineButtonDone = "xsdk_settings_offline_btn_done".localized
            public static let settingsOfflineButtonProcessNoInternet = "xsdk_settings_offline_btn_process_no_internet".localized
            public static let settingsEmailReceiptSubtitle = "xsdk_settings_email_receipt_subtitle".localized
            public static let settingsEmailReceiptEnabled = "xsdk_settings_email_receipt_enabled".localized
        }
    }
}
