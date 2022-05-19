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
    
    public override init() {
        super.init()
        ClearentWrapper.shared.readerInfoReceived = {[weak self] _ in
            DispatchQueue.main.async {
                self?.readerInfoReceived?(ClearentWrapper.shared.readerInfo)
            }
        }
    }
    
    public func updateWith(baseURL: String, apiKey: String, publicKey: String) {
        clearentWrapper.updateWithInfo(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
    }
    
    public func paymentViewController(amount: Double) -> UINavigationController {
        viewController(processType: .payment, amount:amount)
    }
    
    public func pairingViewController() -> UINavigationController {
        viewController(processType: .pairing)
    }
    
    public func readersViewController() -> UINavigationController {
        viewController(processType: .showReaders)
    }
    
    private func viewController(processType: ProcessType, amount: Double? = nil) ->  UINavigationController {
        let viewController = ClearentProcessingModalViewController(showOnTop: processType == .showReaders)
          let presenter = ClearentProcessingModalPresenter(paymentProcessingView: viewController, amount: amount, processType: processType)
         viewController.presenter = presenter
        
          if (clearentWrapper.readerInfo != nil) {
              readerInfoReceived?(clearentWrapper.readerInfo)
          }
 
          let navigationController = UINavigationController(rootViewController: viewController)
          navigationController.isNavigationBarHidden = true
          navigationController.modalPresentationStyle = .overFullScreen
          return navigationController
    }
}
