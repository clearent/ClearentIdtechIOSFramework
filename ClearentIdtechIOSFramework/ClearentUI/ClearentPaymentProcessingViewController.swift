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
    
    enum ModalLayout {
        static let cornerRadius = 15.0
        static let margin = 16.0
        static let backgroundColor = ClearentConstants.Color.backgroundSecondary01
    }

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
        customizeModalView()
    }

    // MARK: Private

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter?.startBluetoothDevicePairing()
    }

    private func customizeModalView() {
        view.backgroundColor = .clear
        view.isOpaque = false
        stackView.addRoundedCorners(backgroundColor: ModalLayout.backgroundColor, radius: ModalLayout.cornerRadius, margin: ModalLayout.margin)
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

        if let description = component.mainDescription {
            if let iconName = component.iconName, let title = component.mainTitle {
                // ReaderFeedbackView
                let readerFeedbackView = ClearentReaderFeedbackView()
                readerFeedbackView.setup(imageName: iconName, title: title, description: description)
                stackView.addArrangedSubview(readerFeedbackView)
            } else {
                // UserActionView
                let actionView = ClearentUserActionView()
                actionView.setup(imageName: component.iconName, description: description)
                stackView.addArrangedSubview(actionView)
            }
        }

        // PrimaryButton
        if let userAction = component.userAction {
            let button = ClearentPrimaryButton()
            button.title = userAction
            button.action = { [weak self] in
                self?.dismiss(animated: true)
            }
            stackView.addArrangedSubview(button)
        }
    }
}
