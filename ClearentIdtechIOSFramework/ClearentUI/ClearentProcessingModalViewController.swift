//
//  ClearentProcessingModalViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 28.03.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentProcessingModalViewController: ClearentBaseViewController {
    
    // MARK: - Properties

    private var showOnTop: Bool = false
    @IBOutlet var stackView: ClearentRoundedCornersStackView!
    var presenter: ProcessingModalProtocol?
    var dismissCompletion: ((_ isConnected: Bool) -> Void)?

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
    
    public func updateContent(with feedback: FlowFeedback) {
        stackView.removeAllArrangedSubviews()
        stackView.isUserInteractionEnabled = true
        
        feedback.items.forEach {
            if let component = uiComponent(for: $0, processType: feedback.flow, feedbackType: feedback.type) {
                stackView.addArrangedSubview(component)
            }
        }
    }
    
    public func updateCurrentContentWithLoadingView() {
        stackView.insertArrangedSubview(ClearentLoadingView(), at: 1)
    }
    
    public func showLoadingView() {
        stackView.showLoadingView()
    }

    public func dismissViewController(isConnected: Bool) {
        ClearentWrapper.shared.cancelTransaction()
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            self?.dismissCompletion?(isConnected)
        }
    }

    private func uiComponent(for item: FlowDataItem, processType: ProcessType, feedbackType: FlowFeedbackType) -> UIView? {
        let object = item.object
        
        switch item.type {
        case .readerInfo:
            return readerInfoView(readerInfo: object as? ReaderInfo, flowFeedbackType: feedbackType)
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
            let hint = ClearentHintView(text: text)
            if case let .pairing(_, firstPairing) = presenter?.processType {
                hint.isHighlighted = firstPairing
            }
            return hint
        case .recentlyPaired:
            guard let readersInfo = object as? [ReaderInfo] else { return nil }
            var readersTableViewDataSource: [ReaderItem] = readersInfo.map { ReaderItem(readerInfo: $0) }
            
            if let pairedReaderInfo = ClearentWrapperDefaults.pairedReaderInfo, pairedReaderInfo.isConnected {
                guard let indexOfConnectedReader = readersTableViewDataSource.firstIndex(where: {$0.readerInfo == pairedReaderInfo}) else { return nil }
                readersTableViewDataSource.insert(readersTableViewDataSource.remove(at: indexOfConnectedReader), at: 0)
                presenter?.selectedReaderFromReadersList = nil
            } else {
                guard let selectedReaderFromReadersList = presenter?.selectedReaderFromReadersList else {
                    return ClearentReadersTableView(dataSource: readersTableViewDataSource, delegate: self)
                }
                guard let indexOfSelectedReader = readersTableViewDataSource.firstIndex(where: {$0.readerInfo == selectedReaderFromReadersList.readerInfo}) else { return nil }
                readersTableViewDataSource[indexOfSelectedReader].isConnecting = true
            }
            return ClearentReadersTableView(dataSource: readersTableViewDataSource, delegate: self)
        }
    }

    private func readerInfoView(readerInfo: ReaderInfo?, flowFeedbackType: FlowFeedbackType) -> ClearentReaderStatusHeaderView? {
        if readerInfo == nil && flowFeedbackType != .showReaders { return nil }
        let name = readerInfo?.readerName ?? "xsdk_readers_list_no_reader_connected".localized
        let description = readerInfo == nil ? "xsdk_readers_list_select_reader".localized : nil
        let signalStatus = readerInfo?.signalStatus(flowFeedbackType: flowFeedbackType, isConnecting: presenter?.selectedReaderFromReadersList != nil)
        let batteryStatus = readerInfo?.batteryStatus(flowFeedbackType: flowFeedbackType)
        let iconName = showOnTop ? ClearentConstants.IconName.expanded : nil
        
        let statusHeaderView = ClearentReaderStatusHeaderView()
        statusHeaderView.setup(readerName: name, dropDownIconName: iconName, description: description, signalStatus: signalStatus, batteryStatus: batteryStatus)
        statusHeaderView.action = { [weak self] in
            if self?.showOnTop == true {
                self?.dismiss(animated: true, completion: nil)
                ClearentWrapper.shared.shouldBeginContinuousSearchingForReaders?(false)
            }
        }
        return statusHeaderView
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
        button.isBorderedButton = userAction == .cancel || userAction == .pairNewReader
        
        button.action = { [weak self] in
            guard let strongSelf = self, let presenter = strongSelf.presenter else { return }
            switch userAction {
            case .cancel, .done:
                strongSelf.dismissViewController(isConnected: userAction == .done)
            case .retry, .pair:
                presenter.restartProcess(processType: processType, newPair: false)
            case .pairInFlow:
                presenter.restartProcess(processType: processType, newPair: true)
            case .pairNewReader:
                strongSelf.stackView.positionView(onTop: false, of: strongSelf.view)
                presenter.startPairingFlow()
                ClearentWrapper.shared.shouldBeginContinuousSearchingForReaders?(false)
            case .settings:
                let url = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!)!
                UIApplication.shared.open(url)
            }
        }
        return button
    }
}

extension ClearentProcessingModalViewController: ClearentReadersTableViewDelegate {
    func didSelectReaderDetails(currentReader: ReaderItem, allReaders: [ReaderItem]) {
        guard let navigationController = navigationController, let flowDataProvider = presenter?.sdkFeedbackProvider else { return }
        presenter?.showDetailsScreen(for: currentReader, allReaders: allReaders, flowDataProvider: flowDataProvider, on: navigationController)
    }

    func didSelectReader(_ reader: ReaderInfo) {
        presenter?.connectTo(reader: reader)
        stackView.isUserInteractionEnabled = false
        ClearentWrapper.shared.shouldBeginContinuousSearchingForReaders?(false)
    }
}
