//
//  ClearentUIManager.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation

public final class ClearentUIManager : NSObject {
    
    private let clearentWrapper = ClearentWrapper.shared
    public static let shared = ClearentUIManager()
    public var readerInfoReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    public var signatureEnabled: Bool = true
    public var useCardReaderPaymentMethod: Bool = true
    public var tipAmounts: [Double] = ClearentConstants.Tips.defaultTipPercentages
    
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

        ClearentWrapper.shared.readerInfoReceived = { [weak self] _ in
            DispatchQueue.main.async {
                self?.readerInfoReceived?(ClearentWrapperDefaults.pairedReaderInfo)
            }
        }
    }
    
    // MARK: Public
    
    public func updateWith(baseURL: String, apiKey: String, publicKey: String) {
        clearentWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
    
    public func paymentViewController(amount: Double) -> UINavigationController {
        viewController(processType: .payment, amount:amount)
    }
    
    public func pairingViewController() -> UINavigationController {
        viewController(processType: .pairing())
    }
    
    public func readersViewController() -> UINavigationController {
        viewController(processType: .showReaders)
    }
    
    internal func viewController(processType: ProcessType, amount: Double? = nil, editableReader: ReaderInfo? = nil, dismissCompletion: ((_ isConnected: Bool, _ customName: String?) -> Void)? = nil) ->  UINavigationController {

        let viewController = ClearentProcessingModalViewController(showOnTop: (processType == .showReaders || processType == .renameReader))
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, amount: amount, processType: processType)
        presenter.editableReader = editableReader
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }
}
