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
    
    // MARK: Init
    
    public override init() {
        super.init()
        ClearentWrapperDefaults.pairedReaderInfo?.isConnected = false
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
    
    internal func viewController(processType: ProcessType, amount: Double? = nil, dismissCompletion: ((_ isConnected: Bool) -> Void)? = nil) ->  UINavigationController {

        let viewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders)
        let presenter = ClearentProcessingModalPresenter(modalProcessingView: viewController, amount: amount, processType: processType)
        viewController.presenter = presenter
        viewController.dismissCompletion = dismissCompletion
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overFullScreen
        return navigationController
    }
}