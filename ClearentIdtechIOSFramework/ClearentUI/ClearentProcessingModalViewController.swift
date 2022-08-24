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
    var dismissCompletion: ((CompletionResult) -> Void)?

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

        positionViewOnTop(flag: showOnTop)
        presenter?.startFlow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Register keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        view.frame.origin.y = view.safeAreaInsets.top - stackView.frame.minY + ClearentConstants.Size.modalStackViewMargin
    }

    @objc private func keyboardWillHide(notification: Notification) {
        view.frame.origin.y = 0
    }
}

// MARK: - ClearentPaymentProcessingView

extension ClearentProcessingModalViewController: ClearentProcessingModalView {
    
    func updateUserActionButtonState(enabled: Bool) {
        let button = stackView.findButtonInStack(with: FlowButtonType.done)
        button?.isUserInteractionEnabled = enabled
        if enabled {
            button?.setFilledButton()
        } else {
            button?.setDisabledButton()
        }
    }
    
    func positionViewOnTop(flag: Bool) {
        stackView.positionView(onTop: flag, of: view)
    }
    
    public func updateContent(with feedback: FlowFeedback) {
        stackView.removeAllArrangedSubviews()
        stackView.isUserInteractionEnabled = true
        ClearentWrapper.shared.flowType = (feedback.flow, feedback.type)
        feedback.items.forEach {
            if let component = uiComponent(for: $0) {
                stackView.addArrangedSubview(component)
            }
        }
    }
    
    public func addLoadingViewToCurrentContent() {
        stackView.insertArrangedSubview(ClearentLoadingView(), at: 1)
    }
    
    public func showLoadingView() {
        stackView.showLoadingView()
    }

    public func dismissViewController(result: CompletionResult) {
        ClearentWrapperDefaults.skipOnboarding = true
        ClearentWrapper.shared.stopContinousSearching()
        ClearentWrapper.shared.cancelTransaction()
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            self?.dismissCompletion?(result)
        }
    }

    private func uiComponent(for item: FlowDataItem) -> UIView? {
        let object = item.object
        
        switch item.type {
        case .readerInfo:
            return readerInfoView(readerInfo: object as? ReaderInfo)
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

            return actionButton(userAction: userAction)
        case .devicesFound:
            guard let readersInfo = object as? [ReaderInfo] else { return nil }
            
            return readersList(readersInfo: readersInfo)
        case .hint:
            guard let text = object as? String else { return nil }
            let hint = ClearentHintView(text: text)
            hint.isHighlighted = !ClearentWrapperDefaults.skipOnboarding
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
        case .input:
            return ClearentTextField(currentReaderName: presenter?.editableReader?.customReaderName, inputName: ClearentConstants.Localized.Pairing.readerName, hint: ClearentConstants.Localized.Pairing.readerNameInputHint, delegate: self)
        case .tips:
            guard let amountInfo = object as? AmountInfo else { return nil }
            return tipOptionsListView(with: amountInfo)
        case .signature:
            return signatureView()
        case .manualEntry:
            return manualEntryFormView()
        }
    }
    
    private func signatureView() -> ClearentSignatureView {
        // all orientations should be allowed when signature view is displayed
        ClearentApplicationOrientation.customOrientationMaskClosure?(UIInterfaceOrientationMask.all)
        let signatureView = ClearentSignatureView()
        signatureView.doneAction = { [weak self] signatureImage in
            self?.presenter?.handleSignature(with: signatureImage)
        }
        return signatureView
    }
    
    private func manualEntryFormView() -> ClearentManualEntryFormView {
        let dataSource = ClearentPaymentDataSource(with: [ClearentPaymentBaseSection(), ClearentPaymentAdditionalSection()])
        let manualEntryFormView = ClearentManualEntryFormView(with: dataSource)
        manualEntryFormView.delegate = self
        dataSource.delegate = manualEntryFormView
        
        return manualEntryFormView
    }

    private func readerInfoView(readerInfo: ReaderInfo?) -> ClearentReaderStatusHeaderView? {
        guard let flowFeedbackType = ClearentWrapper.shared.flowType?.flowFeedbackType else { return nil }
        if readerInfo == nil && flowFeedbackType != .showReaders { return nil }
        var name = readerInfo?.readerName ?? ClearentConstants.Localized.ReadersList.noReaderConnected
        if let customName = readerInfo?.customReaderName {
            name = customName
        }
        let description = readerInfo == nil ? ClearentConstants.Localized.ReadersList.selectReader : nil
        let signalStatus = readerInfo?.signalStatus(flowFeedbackType: flowFeedbackType, isConnecting: presenter?.selectedReaderFromReadersList != nil)
        let batteryStatus = readerInfo?.batteryStatus(flowFeedbackType: flowFeedbackType)
        let iconName = showOnTop ? ClearentConstants.IconName.expanded : nil
        
        let statusHeaderView = ClearentReaderStatusHeaderView()
        statusHeaderView.setup(readerName: name, dropDownIconName: iconName, description: description, signalStatus: signalStatus, batteryStatus: batteryStatus)
        statusHeaderView.action = { [weak self] in
            if self?.showOnTop == true {
                self?.presenter?.handleUserAction(userAction: .cancel)
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

    private func readersList(readersInfo: [ReaderInfo]) -> ClearentListView {
        let items = readersInfo.map { item -> ClearentPairingReaderItem in
           let readerName = item.customReaderName ?? item.readerName
           return ClearentPairingReaderItem(title: readerName) {
               self.presenter?.connectTo(reader: item)
            }
        }
        return ClearentListView(items: items)
    }

    private func actionButton(userAction: FlowButtonType) -> ClearentPrimaryButton {
        let button = ClearentPrimaryButton()
        button.title = userAction.title
        if [.cancel, .pairNewReader, .renameReaderLater, .transactionWithoutTip, .skipSignature].contains(userAction) {
            button.buttonStyle = .bordered
        }
        if userAction == .transactionWithTip {
            button.title = userAction.transactionWithTipTitle(for: presenter?.amountWithoutTip)
        }
        button.type = userAction
        button.action = { [weak self] in
            guard let strongSelf = self, let presenter = strongSelf.presenter else { return }
            presenter.handleUserAction(userAction: userAction)
        }
        return button
    }
    
    private func tipOptionsListView(with amountInfo: AmountInfo) -> ClearentListView {
        let tipOptionsList = amountInfo.tipOptions.map { tip -> ClearentTipOptionView in
            let tipOption = ClearentTipOptionView(percentageTextAndValue: tip.percentageTextAndValue, tipValue: tip.value, isCustomTip: tip.isCustom)
            tipOption.tipSelectedAction = { [weak self] value in
                self?.presenter?.tip = value
                if let button = self?.stackView.findButtonInStack(with: .transactionWithTip) {
                    var amountInfo = amountInfo
                    amountInfo.selectedTipValue = value
                    button.title = button.type?.transactionWithTipTitle(for: amountInfo.finalAmount)
                }
            }
            return tipOption
        }
        return ClearentListView(items: tipOptionsList)
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
    }
}

extension ClearentProcessingModalViewController: ClearentTextFieldProtocol {
    
    func didChangeValidationState(isValid: Bool) {
        presenter?.enableDoneButtonForInput(enabled: isValid)
    }
    
    func didFinishWithResult(name: String?) {
        presenter?.updateTemporaryReaderName(name: name)
    }
}

extension ClearentProcessingModalViewController: ClearentManualEntryFormViewProtocol {
    func didTapOnCancelButton() {
        presenter?.handleUserAction(userAction: .cancel)
    }
    
    func didTapOnConfirmButton(dataSource: ClearentPaymentDataSource) {
        presenter?.sendManualEntryTransaction(with: dataSource)
    }
}
