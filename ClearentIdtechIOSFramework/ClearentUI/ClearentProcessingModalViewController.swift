//
//  ClearentProcessingModalViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentProcessingModalViewController: UIViewController {
    // MARK: - Properties

    @IBOutlet var stackView: ClearentAdaptiveStackView!
    public var presenter: ProcessingModalProtocol?
    private enum Layout {
        static let cornerRadius = 15.0
        static let margin = 16.0
        static let emptySpaceHeight = 104.0
        static let backgroundColor = ClearentConstants.Color.backgroundSecondary01
    }

    private var initialTouchPoint = CGPoint.zero

    // MARK: - Init

    public init() {
        super.init(nibName: String(describing: ClearentProcessingModalViewController.self), bundle: ClearentConstants.bundle)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupStyle()

        presenter?.startFlow()
    }

    // MARK: - Private

    private func dismissViewController() {
        dismiss(animated: true, completion: nil)
        ClearentWrapper.shared.cancelTransaction()
    }

    private func setupStyle() {
        view.backgroundColor = .clear
        view.isOpaque = false
        stackView.addRoundedCorners(backgroundColor: Layout.backgroundColor, radius: Layout.cornerRadius, margin: Layout.margin)
    }
}

// MARK: - ClearentPaymentProcessingView

extension ClearentProcessingModalViewController: ClearentProcessingModalView {
    public func showLoadingView() {
        stackView.removeAllArrangedSubviews()
        let loadingView = ClearentLoadingView()
        let emptySpace = ClearentEmptySpace(height: Layout.emptySpaceHeight)
        stackView.addArrangedSubview(emptySpace)
        stackView.addArrangedSubview(loadingView)
    }

    public func updateContent(with feedback: FlowFeedback) {
        stackView.removeAllArrangedSubviews()
        feedback.items.forEach {
            if let component = uiComponent(for: $0, proccessType: feedback.flow) {
                stackView.addArrangedSubview(component)
            }
        }
    }

    private func uiComponent(for item: FlowDataItem, proccessType: ProcessType) -> UIView? {
        let object = item.object
        switch item.type {
        case .readerInfo:
            guard let readerInfo = object as? ReaderInfo else { return nil }
            return readerInfoView(readerInfo: readerInfo)
        case .graphicType:
            guard let graphic = object as? FlowGraphicType else { return nil }
            return icon(with: graphic)
        case .title:
            guard let text = object as? String else { return nil }
            return ClearentTitleLabel(text: text)
        case .description:
            guard let text = object as? String else { return nil }
            return ClearentSubtitleLabel(text: text)
        case .userAction:
            guard let userAction = object as? FlowButtonType else { return nil }
            return button(userAction: userAction, proccessType: proccessType)
        case .devicesFound:
            guard let readersInfo = object as? [ReaderInfo] else { return nil }
            return readersList(readersInfo: readersInfo)
        case .hint:
            guard let text = object as? String else { return nil }
            return ClearentHintView(text: text)
        }
    }

    public func dismissView() {
        dismissViewController()
    }

    private func readerInfoView(readerInfo: ReaderInfo) -> ClearentReaderStatusHeaderView {
        let name = readerInfo.readerName
        let signalStatus = readerInfo.signalStatus
        let batteryStatus = readerInfo.batteryStatus
        let statusHeader = ClearentReaderStatusHeaderView()
        statusHeader.setup(readerName: name, signalStatusIconName: signalStatus.iconName, signalStatusTitle: signalStatus.title, batteryStatusIconName: batteryStatus.iconName, batteryStatusTitle: batteryStatus.title)
        return statusHeader
    }

    private func icon(with graphic: FlowGraphicType) -> UIView? {
        if let iconName = graphic.iconName, graphic != .loading {
            return ClearentIcon(iconName: iconName)
        }
        return ClearentLoadingView()
    }

    private func readersList(readersInfo: [ReaderInfo]) -> ClearentPairingReadersList {
        let items = readersInfo.map { item in
            ClearentPairingReaderItem(title: item.readerName) {
                ClearentWrapper.shared.selectReader(reader: item)
            }
        }
        return ClearentPairingReadersList(items: items)
    }

    private func button(userAction: FlowButtonType, proccessType: ProcessType) -> ClearentPrimaryButton {
        let button = ClearentPrimaryButton(title: userAction.title)
        button.action = { [weak self] in
            guard let strongSelf = self, let presenter = strongSelf.presenter else { return }
            switch userAction {
            case .cancel, .done:
                strongSelf.dismissViewController()
            case .retry, .pair:
                presenter.restartProcess(processType: proccessType)
            }
        }
        return button
    }
}
