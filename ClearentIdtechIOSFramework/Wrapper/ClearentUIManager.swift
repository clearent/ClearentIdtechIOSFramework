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
    public var flowFeedbackReceived: ((_ readerInfo: ReaderInfo?) -> Void)?
    
    public override init() {
        super.init()
        _ = ClearentWrapper.shared
    }
    
    public func updateWith(baseURL: String, apiKey: String, publicKey: String) {
        clearentWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
    
    public func paymentViewController(amount: Double) -> UIViewController {
        viewController(processType: .payment, amount:amount)
    }
    
    public func pairingViewController() -> UIViewController {
        viewController(processType: .pairing)
    }
    
    public func readersViewController() -> UIViewController {
        viewController(processType: .showReaders)
    }
    
    private func viewController(processType: ProcessType, amount: Double? = nil) ->  UIViewController {
        let paymentProcessingViewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders)
          let paymentProcessingPresenter = ClearentProcessingModalPresenter(paymentProcessingView: paymentProcessingViewController, amount: amount, processType: processType)
          paymentProcessingViewController.presenter = paymentProcessingPresenter
          paymentProcessingViewController.modalPresentationStyle = .overFullScreen
        
          if (ClearentWrapperDefaults.pairedReaderInfo != nil) {
              flowFeedbackReceived?(ClearentWrapperDefaults.pairedReaderInfo)
          }
 
          return paymentProcessingViewController
    }
}
