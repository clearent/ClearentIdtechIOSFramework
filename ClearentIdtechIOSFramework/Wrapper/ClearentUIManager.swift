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
    
    public func paymentViewController(amount: Double?) -> UIViewController {
        let paymentProcessingViewController = ClearentProcessingModalViewController()
        let paymentProcessingPresenter = ClearentProcessingModalPresenter(paymentProcessingView: paymentProcessingViewController, amount: amount, processType: .payment)
        paymentProcessingViewController.presenter = paymentProcessingPresenter
        paymentProcessingViewController.modalPresentationStyle = .overFullScreen
        if (clearentWrapper.readerInfo != nil) {
            flowFeedbackReceived?(clearentWrapper.readerInfo)
        }
        
        return paymentProcessingViewController
    }
    
    public func pairingViewController(amount: Double?) -> UIViewController {
        let paymentProcessingViewController = ClearentProcessingModalViewController()
        let paymentProcessingPresenter = ClearentProcessingModalPresenter(paymentProcessingView: paymentProcessingViewController, amount: nil, processType: .pairing)
        paymentProcessingViewController.presenter = paymentProcessingPresenter
        paymentProcessingViewController.modalPresentationStyle = .overFullScreen
        if (clearentWrapper.readerInfo != nil) {
            flowFeedbackReceived?(clearentWrapper.readerInfo)
        }
        
        return paymentProcessingViewController
    }
}
