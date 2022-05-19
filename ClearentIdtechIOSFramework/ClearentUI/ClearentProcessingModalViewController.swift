//
//  ClearentProcessingModalViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentProcessingModalViewController: ClearentBaseViewController {
    
    // MARK: - Properties

    private var showOnTop: Bool = false
    @IBOutlet var stackView: ClearentRoundedCornersStackView!
    public var presenter: ProcessingModalProtocol?

    // MARK: - Init

    public init(showOnTop: Bool) {
        super.init(nibName: String(describing: ClearentProcessingModalViewController.self), bundle: ClearentConstants.bundle)
        self.showOnTop = showOnTop
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.positionView(onTop: showOnTop, of: view)
        presenter?.startFlow()
    }
}

// MARK: - ClearentPaymentProcessingView

extension ClearentProcessingModalViewController: ClearentProcessingModalView {
    
    public func showLoadingView() {
        stackView.showLoadingView()
    }

    public func dismissViewController() {
        dismiss(animated: true, completion: nil)
        ClearentWrapper.shared.cancelTransaction()
    }

    public func updateContent(with feedback: FlowFeedback) {
        stackView.removeAllArrangedSubviews()
        
        feedback.items.forEach {
            if let component = uiComponent(for: $0, processType: feedback.flow, feedbackType: feedback.type) {
                stackView.addArrangedSubview(component)
            }
        }
    }

    private func uiComponent(for item: FlowDataItem, processType: ProcessType, feedbackType: FlowFeedbackType) -> UIView? {
        let object = item.object
        
        switch item.type {
        case .readerInfo:
            guard let readerInfo = object as? ReaderInfo else { return nil }

            return readerInfoView(readerInfo: readerInfo, flowFeedbackType: feedbackType)
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

            return actionButton(userAction: userAction, processType: processType)
        case .devicesFound:
            guard let readersInfo = object as? [ReaderInfo] else { return nil }
            
            return readersList(readersInfo: readersInfo)
        case .hint:
            guard let text = object as? String else { return nil }
            
            return ClearentHintView(text: text)
        case .recentlyPaired:
            guard let readersInfo = object as? [ReaderInfo] else { return nil }
            
            return ClearentReadersTableView(dataSource: readersInfo, delegate: self)
        }
    }

    private func readerInfoView(readerInfo: ReaderInfo, flowFeedbackType: FlowFeedbackType) -> ClearentReaderStatusHeaderView {
        let name = readerInfo.readerName
        let signalStatus = readerInfo.signalStatus(flowFeedbackType: flowFeedbackType)
        let batteryStatus = readerInfo.batteryStatus(flowFeedbackType: flowFeedbackType)
        let statusHeader = ClearentReaderStatusHeaderView()
        
        showOnTop ? statusHeader.setup(readerName: name, dropDownIconName: ClearentConstants.IconName.expanded, signalStatusIconName: signalStatus.iconName, signalStatusTitle: signalStatus.title, batteryStatusIconName: batteryStatus.iconName, batteryStatusTitle: batteryStatus.title) : statusHeader.setup(readerName: name, signalStatusIconName: signalStatus.iconName, signalStatusTitle: signalStatus.title, batteryStatusIconName: batteryStatus.iconName, batteryStatusTitle: batteryStatus.title)
        
        statusHeader.action = { [weak self] in
            if self?.showOnTop == true {
                self?.dismiss(animated: true, completion: nil)
            }
        }
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
                self.presenter?.connectTo(reader: item)
            }
        }
        return ClearentPairingReadersList(items: items)
    }

    private func actionButton(userAction: FlowButtonType, processType: ProcessType) -> ClearentPrimaryButton {
        let button = ClearentPrimaryButton()
        button.title = userAction.title
        let color = ClearentConstants.Color.self
        let isBorderedButton = userAction == .cancel || userAction == .pairNewReader
        button.enabledBackgroundColor = isBorderedButton ? color.backgroundSecondary01 : color.base01
        button.enabledTextColor = isBorderedButton ? color.base01 : color.backgroundSecondary01
        button.borderColor = color.backgroundSecondary02
        button.borderWidth = isBorderedButton ? ClearentConstants.Size.primaryButtonBorderWidth : 0
        
        button.action = { [weak self] in
            guard let strongSelf = self, let presenter = strongSelf.presenter else { return }
            switch userAction {
            case .cancel, .done:
                strongSelf.dismissViewController()
            case .retry, .pair:
                presenter.restartProcess(processType: processType)
            case .pairNewReader:
                strongSelf.stackView.positionView(onTop: false, of: strongSelf.view)
                presenter.startPairingFlow()
            }
        }
        return button
    }
}

extension ClearentProcessingModalViewController: ClearentReadersTableViewDelegate {
    func didSelectReader(_ reader: ReaderInfo) {
        presenter?.connectTo(reader: reader)
    }
}
