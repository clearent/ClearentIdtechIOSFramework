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
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    @objc public var signatureEnabled: Bool = true
    @objc public var useCardReaderPaymentMethod: Bool = true {
        didSet {
            clearentWrapper.useCardReaderPaymentMethod = useCardReaderPaymentMethod
        }
    }
    @objc public var tipAmounts: [Int] = ClearentConstants.Tips.defaultTipPercentages
    
    // MARK: Init
    
    public override init() {
        super.init()
        setupReaderInfo()
    }
    
    func setupReaderInfo() {
        // reset connection status on app restart
        if var connectedReader = ClearentWrapperDefaults.recentlyPairedReaders?.first(where: { $0.isConnected }) {
            connectedReader.isConnected = false
            ClearentWrapper.shared.updateReaderInRecentlyUsed(reader: connectedReader)
        }
        
        ClearentWrapperDefaults.lastPairedReaderInfo = ClearentWrapperDefaults.recentlyPairedReaders?.first { $0.autojoin }

        clearentWrapper.readerInfoReceived = { [weak self] reader in
            DispatchQueue.main.async {
                self?.readerInfoReceived?(ClearentWrapperDefaults.pairedReaderInfo)
            }
        }
    }
    
    // MARK: Public
    
    /**
     * Method updates the SDK with needed parameters to work properly
     * @param baseURL, the endpoint of the backend
     * @param apiKey, the API Key in order to use the API
     * @param publicKey, needed for the card reader initialisation
     */
    @objc public func updateWith(baseURL: String, apiKey: String, publicKey: String) {
        clearentWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
    
    /**
     * Method returns a UIController that can handle the entire payment process
     * @param amount, the amount to be charged in a transaction
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func paymentViewController(amount: Double, completion: ((ClearentResult) -> Void)?) -> UINavigationController {
        viewController(processType: .payment, amount: amount, dismissCompletion: { [weak self] result in
            guard let completionResult = self?.resultFor(completionResult: result) else { return }
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UIController that can handle the pairing process of a card reader
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func pairingViewController(completion: ((ClearentResult) -> Void)?) -> UINavigationController {
        viewController(processType: .pairing(), dismissCompletion: { [weak self] result in
            guard let completionResult = self?.resultFor(completionResult: result) else { return }
            completion?(completionResult)
        })
    }
    
    /**
     * Method returns a UIController that will display a list containing current card reader informations and recently paired readers
     * @param completion, a closure to be executed once the clearent SDK UI is dimissed
     */
    @objc public func readersViewController(completion: ((ClearentResult) -> Void)?) -> UINavigationController {
        viewController(processType: .showReaders, dismissCompletion: {[weak self] result in
            guard let completionResult = self?.resultFor(completionResult: result) else { return }
            completion?(completionResult)
        })
    }

    internal func viewController(processType: ProcessType, amount: Double? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((CompletionResult) -> Void)? = nil) -> UINavigationController {
        let viewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders || processType == .renameReader)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, amount: amount, processType: processType)
        presenter.editableReader = editableReader
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }
    
    private func resultFor(completionResult:CompletionResult) -> ClearentResult {
        switch completionResult {
        case .success(_):
            return ClearentResult.processFinishedWithoutError
        case .failure(let err):
            return err
        }
    }
}
