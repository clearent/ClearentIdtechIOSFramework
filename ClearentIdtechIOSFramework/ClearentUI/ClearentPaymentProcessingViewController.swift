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
    @IBOutlet weak var connectedToLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var pairBluetoothDeviceButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
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
        
        configureButtons()
        
        connectedToLabel.isHidden = true
        deviceNameLabel.isHidden = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let presenter = presenter else { return }
        presenter.startBluetoothDevicePairing()
    }
    
    // MARK: Private
    
    private func configureButtons() {
        pairBluetoothDeviceButton.isHidden = true
        pairBluetoothDeviceButton.layer.cornerRadius = 7
        pairBluetoothDeviceButton.clipsToBounds = true
        
        dismissButton.isHidden = true
        dismissButton.layer.cornerRadius = 7
        dismissButton.clipsToBounds = true
    }
    
    // MARK: IBAction
    
    @IBAction func pairBluetoothDeviceButtonPressed(_ sender: Any) {
        guard let presenter = presenter else { return }
        presenter.pairAgainBluetoothDevice()
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension ClearentPaymentProcessingViewController: ClearentPaymentProcessingView {
    public func updateInfoLabel(message: String) {
        paymentProcessingLabel.text = message
    }
    
    public func updatePairingButton(shouldBeHidden: Bool) {
        pairBluetoothDeviceButton.isHidden = shouldBeHidden
    }
    
    public func updateDismissButton(shouldBeHidden: Bool) {
        dismissButton.isHidden = shouldBeHidden
    }
    
    public func updateDeviceNameLabel(value: String) {
        connectedToLabel.isHidden = false
        deviceNameLabel.isHidden = false
        deviceNameLabel.text = value
    }
}
