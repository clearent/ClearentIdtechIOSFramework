//
//  ClearentUIManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

/**
 * This class is to be used as a singleton and its main purpose is to start different processes from the SDK by providing UIControllers that will handle the entire process
 *
 */
public final class ClearentUIManager: NSObject {
    private let clearentWrapper = ClearentWrapper.shared
    @objc public static let shared = ClearentUIManager()
    
    @objc public static var configuration: ClearentUIManagerConfiguration!

    @objc public var cardReaderPaymentIsPreferred: Bool = true {
        didSet {
            clearentWrapper.cardReaderPaymentIsPreffered = cardReaderPaymentIsPreferred
        }
    }

    @objc public var offlineModeState: OfflineModeState = .off {
        didSet {
            clearentWrapper.offlineModeState = offlineModeState
        }
    }

    // MARK: Init
    
    /**
     * This method will update the SDK with the necessary configuration to work properly
     */
    public func initialize(with configuration: ClearentUIManagerConfiguration) {
        ClearentUIManager.configuration = configuration
        setupReaderInfo()
    }
    
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
    
    // MARK: Public
    

    /**
     * Method returns a UIController that can handle the entire payment process
     * @param amount, the amount to be charged in a transaction
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func paymentViewController(amount: Double, completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .payment, amount: amount, dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UIController that can handle the pairing process of a card reader
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func pairingViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .pairing(), dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UIController that will display a list containing current card reader informations and recently paired readers
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func readersViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .showReaders, dismissCompletion: {[weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UIController that will display a list containing current card reader informations and recently paired readers
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func settingsViewController(completion: ((ClearentError?) -> Void)?) -> UINavigationController {
        navigationController(processType: .showSettings, dismissCompletion: { [weak self] result in
            let completionResult = self?.resultFor(completionResult: result)
            completion?(completionResult)
        })
    }
    
    func navigationController(processType: ProcessType, amount: Double? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UINavigationController {

        var viewController: UIViewController?
        if processType == .showSettings {
            viewController = ClearentSettingsModalViewController()
        } else {
            viewController = processingModalViewController(processType: processType, amount: amount, editableReader: editableReader, dismissCompletion: dismissCompletion)
        }
        
        guard let viewController = viewController else {
            return UINavigationController()
        }

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }
    
    func processingModalViewController(processType: ProcessType, amount: Double? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UIViewController {
        let viewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders || processType == .renameReader)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, amount: amount, processType: processType)
        presenter.editableReader = editableReader
        viewController.presenter = presenter
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
