//
//  ClearentReaderDetailsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderDetailsViewController: ClearentAbstractViewController {
    
    // MARK: - Properties
    
    var readerInfo: ReaderInfo { detailsPresenter.currentReader }
    var detailsPresenter: ClearentReaderDetailsProtocol!

    // MARK: - IBOutlets

    @IBOutlet var stackView: ClearentAdaptiveStackView!
    @IBOutlet var connectedView: ClearentLabelSwitch!
    @IBOutlet var signalStatusView: ClearentLabelWithIcon!
    @IBOutlet var batteryStatusView: ClearentLabelWithIcon!
    @IBOutlet var autojoinView: ClearentLabelSwitch!
    @IBOutlet var readerName: ClearentInfoWithIcon!
    @IBOutlet var customReaderName: ClearentInfoWithIcon!
    @IBOutlet var serialNumberView: ClearentInfoWithIcon!
    @IBOutlet var versionNumberView: ClearentInfoWithIcon!
    @IBOutlet var removeReaderButton: ClearentPrimaryButton!

    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupSwitches()
        updateReaderInfo()
        setupReaderName()
        setupCustomReaderName()
        setupButton()
        addNavigationBarWithBackItem(barTitle: ClearentConstants.Localized.ReaderDetails.navigationItem)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    // MARK: - Internal
    
    override func didPressBackButton() {
        detailsPresenter.handleBackAction()
    }
    
    // MARK: - Private

    private func setupSwitches() {
        connectedView.titleText = ClearentConstants.Localized.ReaderDetails.connected
        connectedView.descriptionText = ""
        connectedView.isOn = readerInfo.isConnected
        connectedView.valueChangedAction = { [weak self] isOn in
            guard let strongSelf = self else { return }
            if isOn {
                let modalVC = ClearentUIManager.shared.navigationController(processType: .pairing(withReader: strongSelf.readerInfo)) { result in
                    if case .success(_) = result {
                        strongSelf.didChangedConnectionStatus(isConnected: true)
                    } else {
                        strongSelf.didChangedConnectionStatus(isConnected: false)
                    }
                }
                strongSelf.navigationController?.present(modalVC, animated: false)
            } else {
                strongSelf.detailsPresenter.disconnectFromReader()
                strongSelf.didChangedConnectionStatus(isConnected: false)
            }
        }

        autojoinView.titleText = ClearentConstants.Localized.ReaderDetails.autojoinTitle
        autojoinView.descriptionText = ClearentConstants.Localized.ReaderDetails.autojoinDescription
        autojoinView.isOn = readerInfo.autojoin
        autojoinView.valueChangedAction = { [weak self] isOn in
            self?.detailsPresenter.handleAutojoin(markAsAutojoin: isOn)
        }
    }
    
    private func didChangedConnectionStatus(isConnected: Bool) {
        if let defaultReader = ClearentWrapperDefaults.pairedReaderInfo {
            detailsPresenter.currentReader = defaultReader
        }
        connectedView.isOn = isConnected
        updateReaderInfo()
    }

    private func didChangedCustomReaderName(customName: String?) {
        detailsPresenter.currentReader = readerInfo
        detailsPresenter.currentReader.customReaderName = customName
        updateReaderInfo()
    }

    private func updateReaderInfo() {
        setupReaderStatus()
        setupSerialNumber()
        setupCustomReaderName()
        setupVersion()
    }

    private func setupReaderStatus() {
        if let signalStatus = detailsPresenter.readerSignalStatus {
            signalStatusView.iconName = signalStatus.iconName
            signalStatusView.title = signalStatus.title
        }
        signalStatusView.isHidden = detailsPresenter.readerSignalStatus == nil

        if let batteryStatus = detailsPresenter.readerBatteryStatus {
            batteryStatusView.title = batteryStatus.title
            batteryStatusView.iconName = batteryStatus.iconName
        }
        batteryStatusView.isHidden = detailsPresenter.readerBatteryStatus == nil
    }

    private func setupReaderName() {
        readerName.titleText = ClearentConstants.Localized.ReaderDetails.readerName
        readerName.descriptionText = readerInfo.readerName
        readerName.button.isHidden = true
    }

    private func setupCustomReaderName() {
        customReaderName.titleText = ClearentConstants.Localized.ReaderDetails.customReaderName
        customReaderName.editButtonPressed = { [weak self] in
            guard let strongSelf = self else { return }
            let modalVC = ClearentUIManager.shared.navigationController(processType: .renameReader, editableReader: self?.detailsPresenter.currentReader) { result in
                if case let.success(customName) = result {
                    strongSelf.didChangedCustomReaderName(customName: customName)
                }
            }
            strongSelf.navigationController?.present(modalVC, animated: false)
        }
        
        if self.detailsPresenter.currentReader.customReaderName != nil {
            customReaderName.deleteButtonPressed = { [weak self] in
                guard self != nil else { return }
                self?.detailsPresenter.deleteReaderName()
                self?.didChangedCustomReaderName(customName: nil)
            }
            
            customReaderName.secondIconName = ClearentConstants.IconName.deleteButton
            customReaderName.deleteButton.isHidden = false
        } else {
            customReaderName.deleteButton.isHidden = true
        }
        
        if let friendlyreaderName = detailsPresenter.currentReader.customReaderName {
            customReaderName.descriptionText = friendlyreaderName
        } else {
            customReaderName.descriptionText = ClearentConstants.Localized.ReaderDetails.addCustomReaderName
        }
        customReaderName.iconName = ClearentConstants.IconName.editButton
    }

    private func setupSerialNumber() {
        serialNumberView.isHidden = true
        if let serialNumber = readerInfo.serialNumber, !serialNumber.isEmpty {
            serialNumberView.titleText = ClearentConstants.Localized.ReaderDetails.serialNumber
            serialNumberView.descriptionText = serialNumber
            serialNumberView.button.isHidden = true
            serialNumberView.isHidden = false
        }
    }

    private func setupVersion() {
        versionNumberView.isHidden = true
        if let versionNumber = readerInfo.version, !versionNumber.isEmpty {
            versionNumberView.titleText = ClearentConstants.Localized.ReaderDetails.version
            versionNumberView.descriptionText = versionNumber
            versionNumberView.button.isHidden = true
            versionNumberView.isHidden = false
        }
    }

    private func setupButton() {
        removeReaderButton.title = ClearentConstants.Localized.ReaderDetails.removeReader
        removeReaderButton.borderedButtonTextColor = ClearentUIBrandConfigurator.shared.colorPalette.removeReaderButtonTextColor
        removeReaderButton.borderColor = ClearentUIBrandConfigurator.shared.colorPalette.removeReaderButtonBorderColor
        removeReaderButton.buttonStyle = .bordered
        removeReaderButton.action = { [weak self] in
            self?.showRemoveReaderAlert()
        }
    }

    private func showRemoveReaderAlert() {
        let readerName = detailsPresenter.currentReader.customReaderName ?? detailsPresenter.currentReader.readerName
        let alertTitle = String(format: ClearentConstants.Localized.ReaderDetails.removeReaderAlertTitle, readerName)
        let alert = UIAlertController(title: alertTitle, message: ClearentConstants.Localized.ReaderDetails.removeReaderAlertDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ClearentConstants.Localized.ReaderDetails.confirm, style: .destructive) { [weak self] _ in
            self?.detailsPresenter.removeReader()
        })
        alert.addAction(UIAlertAction(title: ClearentConstants.Localized.ReaderDetails.cancel, style: .cancel) { _ in })

        present(alert, animated: true, completion: nil)
    }
}
