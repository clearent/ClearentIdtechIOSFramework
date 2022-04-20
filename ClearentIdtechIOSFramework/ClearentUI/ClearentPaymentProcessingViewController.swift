//
//  ClearentPaymentProcessingViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentPaymentProcessingViewController: UIViewController {
    @IBOutlet weak var stackView: ClearentAdaptiveStackView!
    
    public var presenter: PaymentProcessingProtocol?
    private var initialTouchPoint = CGPoint.zero
    private enum ModalLayout {
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
        setupStyle()
        presenter?.startBluetoothDevicePairing()
    }
    
    // MARK: Private
    
    private func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
        SDKWrapper.shared.cancelTransaction()
        presenter?.dismissAction?()
    }

    private func setupStyle() {
        view.backgroundColor = .clear
        view.isOpaque = false
        stackView.addRoundedCorners(backgroundColor: ModalLayout.backgroundColor, radius: ModalLayout.cornerRadius, margin: ModalLayout.margin)
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismiss)))
    }
}


// MARK: Swipe down

extension ClearentPaymentProcessingViewController {
    enum Constants {
        static let dismissTreshold = 200.0
        static let dismissAnimationDuration = 0.3
    }

    @objc func handleDismiss(sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: view?.window)
        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            if touchPoint.y > initialTouchPoint.y {
                view.frame.origin.y = touchPoint.y - initialTouchPoint.y
            }
        case .ended, .cancelled:
            if touchPoint.y - initialTouchPoint.y > Constants.dismissTreshold {
                dismissViewController()
            } else {
                UIView.animate(withDuration: Constants.dismissAnimationDuration, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        default:
            break
        }
    }
}

// MARK: ClearentPaymentProcessingView

extension ClearentPaymentProcessingViewController: ClearentPaymentProcessingView {
    public func updateContent(with component: PaymentFeedbackComponentProtocol) {
        stackView.removeAllArrangedSubviews()
        createStatusHeader(with: component)
        createMainInfoView(with: component)
        createButton(with: component)
    }
    
    private func createStatusHeader(with component: PaymentFeedbackComponentProtocol) {
        let readerStatusHeader = ClearentReaderStatusHeaderView()
        readerStatusHeader.setup(readerName: component.readerName,
                                 signalStatusIconName: component.signalStatus.iconName,
                                 signalStatusTitle: component.signalStatus.title,
                                 batteryStatusIconName: component.batteryStatus.iconName,
                                 batteryStatusTitle: component.batteryStatus.title)
        stackView.addArrangedSubview(readerStatusHeader)
    }
    
    private func createMainInfoView(with component: PaymentFeedbackComponentProtocol) {
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
    }
    
    private func createButton(with component: PaymentFeedbackComponentProtocol) {
        if let userAction = component.userAction {
            let button = ClearentPrimaryButton()
            button.title = userAction
            button.action = { [weak self] in
                self?.dismissViewController()
            }
            stackView.addArrangedSubview(button)
        }
    }
}
