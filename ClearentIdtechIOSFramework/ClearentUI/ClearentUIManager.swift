//
//  ClearentUIManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

/**
 * This class is to be used as a singleton and its main purpose is to start different processes from the SDK by providing UINavigationControllers that handles the entire process.
 */
public final class ClearentUIManager: NSObject {
    
    // MARK: - Properties
    
    private let clearentWrapper = ClearentWrapper.shared
    
    @objc public static let shared = ClearentUIManager()
    
    ///  Make sure this is set before using the SDK
    @objc public static var configuration: ClearentUIManagerConfiguration!

    /// If true, card reader payment flow will be displayed. Otherwise, a form where the user needs to input card data is shown
    @objc public var cardReaderPaymentIsPreferred: Bool = true {
        didSet {
            clearentWrapper.cardReaderPaymentIsPreffered = cardReaderPaymentIsPreferred
        }
    }
    
    var isOfflineModeConfirmed = false

    // MARK: - Init
    
    /**
     * This method updates the SDK with the necessary configuration to work properly.
     */
    @objc public func initialize(with configuration: ClearentUIManagerConfiguration) {
        ClearentUIManager.configuration = configuration
        setupReaderInfo()
    }
    
    // MARK: - Internal
    
    func setupReaderInfo() {
        // reset connection status on app restart
        if var connectedReader = ClearentWrapperDefaults.recentlyPairedReaders?.first(where: { $0.isConnected }) {
            connectedReader.isConnected = false
            ClearentWrapper.shared.updateReaderInRecentlyUsed(reader: connectedReader)
        }
        
        ClearentWrapperDefaults.lastPairedReaderInfo = ClearentWrapperDefaults.recentlyPairedReaders?.first { $0.autojoin }
        
        ClearentWrapper.configuration.readerInfoReceived = { reader in
            DispatchQueue.main.async {
                ClearentUIManager.configuration.readerInfoReceived?(ClearentWrapperDefaults.pairedReaderInfo)
            }
        }
    }
    
    func navigationController(processType: ProcessType, paymentInfo: PaymentInfo? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UINavigationController {
        var viewController: UIViewController?
        
        if processType == .offlineModeSetup {
            viewController = offlineSetupViewController(dismissCompletion: dismissCompletion)
        } else if processType == .showSettings {
            viewController = settingsViewController(dismissCompletion: dismissCompletion)
        } else {
            viewController = processingModalViewController(processType: processType, paymentInfo: paymentInfo, editableReader: editableReader, dismissCompletion: dismissCompletion)
        }
        
        guard let viewController = viewController else {
            return UINavigationController()
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }
    
    // MARK: Public
    /**
     * Method that returns a UINavigationController that can handle the entire payment process.
     * @param paymentInfo, a PaymentInfo object that contains information regarding amount, customer, invoice, web auth etc.
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func paymentViewController(paymentInfo: PaymentInfo?, completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .payment, paymentInfo: paymentInfo, dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method that returns a UINavigationController that can handle the pairing process of a card reader.
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func pairingViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .pairing(), dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UINavigationController that will display settings information like the following: link to recently paired readers, offline mode related info, option to enable email receipt functionality
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func settingsViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .showSettings, dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UINavigationController that will display a pop-up that will notify the user about offline mode
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func offlineModeQuestionViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .offlineModeSetup, dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    @objc public func allUnprocessedOfflineTransactionsCount() -> Int {
        let offlineManager = clearentWrapper.retrieveOfflineManager()
        return offlineManager?.unproccesedTransactionsCount() ?? 0
    }
    
    /**
     * Method that returns a bool representing if we should display the offline mode warning
     */
    @objc public func shouldDisplayOfflineModeLabel() -> Bool {
        ClearentWrapperDefaults.enableOfflineMode
    }
    
    // MARK: - Private

    private func processingModalViewController(processType: ProcessType, paymentInfo: PaymentInfo? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders || processType == .renameReader)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, paymentInfo: paymentInfo, processType: processType)
        presenter.editableReader = editableReader
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        return viewController
    }
    
    private func settingsViewController(dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = ClearentSettingsModalViewController()
        let presenter = ClearentSettingsPresenter(settingsPresenterView: viewController)
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        return viewController
    }
    
    private func offlineSetupViewController(dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = OfflinePromptViewController()
        viewController.dismissCompletion = dismissCompletion
        return viewController
    }
        
    private func resultFor(completionResult: CompletionResult) -> ClearentError? {
        switch completionResult {
        case .success(_):
            return nil
        case .failure(let err):
            return err
        }
    }
}
