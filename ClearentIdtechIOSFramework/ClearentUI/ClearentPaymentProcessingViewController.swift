//
//  ClearentPaymentProcessingViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentPaymentProcessingViewController: UIViewController {

    private let sdkWrapper: SDKWrapper
    private let nibIdentifier = "ClearentPaymentProcessingViewController"
    
    // MARK: Init
    
    public init(baseURL: String, publicKey: String, apiKey: String) {
        self.sdkWrapper = SDKWrapper(baseURL: baseURL, publicKey: publicKey, apiKey: apiKey)
        
        super.init(nibName: nibIdentifier, bundle: Bundle(for: ClearentPaymentProcessingViewController.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
}
