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

    @IBOutlet weak var stackView: ClearentAdaptiveStackView!

    // MARK: Init

    public init() {
        super.init(nibName: String(describing: ClearentPaymentProcessingViewController.self), bundle: ClearentConstants.bundle)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let presenter = presenter else { return }
        presenter.startBluetoothDevicePairing()
    }

    // MARK: Private

    // MARK: IBAction

    @IBAction func pairBluetoothDeviceButtonPressed(_: Any) {
        guard let presenter = presenter else { return }
        presenter.pairAgainBluetoothDevice()
    }

    @IBAction func dismissButtonPressed(_: Any) {
        dismiss(animated: true)
    }
}

extension ClearentPaymentProcessingViewController: ClearentPaymentProcessingView {
    public func updateInfoLabel(message: String) {
        //paymentProcessingLabel.text = message
    }

    public func updatePairingButton(shouldBeHidden: Bool) {
        //pairBluetoothDeviceButton.isHidden = shouldBeHidden
    }

    public func updateContent(with component: PaymentFeedbackComponentProtocol) {
        stackView.removeAllArrangedSubviews()

        // ReaderStatusHeaderView
        let readerStatusHeader = ClearentReaderStatusHeaderView()
        readerStatusHeader.setup(readerName: component.readerName,
                                 connectivityStatusImageName: component.signalStatus.iconName, connectivityStatus: component.signalStatus.title,
                                 readerBatteryStatusImageName: component.batteryStatus.iconName, readerBatteryStatus: component.batteryStatus.title)
        stackView.addArrangedSubview(readerStatusHeader)

        if let imageName = component.mainIconName, let description = component.mainDescription {
            if let title = component.mainTitle {
                // ReaderFeedbackView
                let readerFeedbackView = ClearentReaderFeedbackView()
                readerFeedbackView.setup(imageName: imageName, title: title, description: description)
                stackView.addArrangedSubview(readerFeedbackView)
            } else {
                // UserActionView
                let actionView = ClearentUserActionView()
                actionView.setup(imageName: imageName, description: description)
                stackView.addArrangedSubview(actionView)
            }
        }

        // PrimaryButton
        if let userAction = component.userAction {
            let button = ClearentPrimaryButton()
            button.button.setTitle(userAction, for: .normal)
            stackView.addArrangedSubview(button)
        }
    }
}
