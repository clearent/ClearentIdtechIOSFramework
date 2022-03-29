//
//  ClearentPaymentProcessingViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentPaymentProcessingViewController: UIViewController {
    public var presenter: PaymentProcessingProtocol?
    private let nibIdentifier = "ClearentPaymentProcessingViewController"
    
    @IBOutlet weak var paymentProcessingLabel: UILabel!
    @IBOutlet weak var tryPairingAgainButton: UIButton!
    
    
    // MARK: Init
    
    public init() {
        super.init(nibName: nibIdentifier, bundle: Bundle(for: ClearentPaymentProcessingViewController.self))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter?.startBluetoothDevicePairing()
    }
}

extension ClearentPaymentProcessingViewController: ClearentPaymentProcessingView {
    public func updateInfoLabel(message: String) {
        paymentProcessingLabel.text = message
    }
}
