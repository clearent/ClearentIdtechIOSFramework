//
//  ClearentReaderDetailsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

public class ClearentReaderDetailsViewController: UIViewController {
    public var detailsPresenter: ClearentReaderDetailsProtocol!

    @IBOutlet var connectedView: ClearentLabelSwitch!
    @IBOutlet var signalStatusView: ClearentLabelWithIcon!
    @IBOutlet var batteryStatusView: ClearentLabelWithIcon!
    @IBOutlet var autojoinView: ClearentLabelSwitch!
    @IBOutlet var readerName: ClearentInfoWithIcon!
    @IBOutlet var serialNumberView: ClearentInfoWithIcon!
    @IBOutlet var versionNumberView: ClearentInfoWithIcon!
    @IBOutlet var removeReaderButton: ClearentPrimaryButton!

    var readerInfo: ReaderInfo { detailsPresenter.readerInfo }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupSwitches()
        setupReaderStatus()
        setupReaderName()
        setupSerialNumber()
        setupVersion()
        setupButton()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    private func setupNavigationBar() {
        let image = UIImage(named: ClearentConstants.IconName.navigationArrow, in: ClearentConstants.bundle, compatibleWith: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didPressBackButton))
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = view.backgroundColor
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = ClearentConstants.Color.backgroundPrimary02
        navigationController?.navigationBar.titleTextAttributes = [.font: ClearentConstants.Font.proDisplayLarge]
        navigationItem.title = "xsdk_reader_details_nav_title".localized
    }

    private func setupSwitches() {
        connectedView.titleText = "xsdk_reader_details_connected".localized
        connectedView.descriptionText = ""
        connectedView.isOn = readerInfo.isConnected
        connectedView.valueChangedAction = { [weak self] isOn in
            self?.detailsPresenter.handleConnection(shouldConnect: isOn)
        }

        autojoinView.titleText = "xsdk_reader_details_autojoin_title".localized
        autojoinView.descriptionText = "xsdk_reader_details_autojoin_description".localized
        autojoinView.isOn = readerInfo.autojoin
        autojoinView.valueChangedAction = { [weak self] isOn in
            self?.detailsPresenter.handleAutojoin(markAsAutojoin: isOn)
        }
    }

    private func setupReaderStatus() {
        if let signalLevel = readerInfo.signalLevel {
            let signalStatus = readerInfo.signalStatus()
            signalStatusView.title = String(format: "xsdk_reader_details_signal_status".localized, signalLevel)
            signalStatusView.iconName = signalStatus.iconName
        } else {
            signalStatusView.removeFromSuperview()
        }

        if let batteryIcon = readerInfo.batteryStatus().iconName, let batteryTitle = readerInfo.batteryStatus().title {
            batteryStatusView.title = String(format: "xsdk_reader_details_battery_status".localized, batteryTitle)
            batteryStatusView.iconName = batteryIcon
        } else {
            batteryStatusView.removeFromSuperview()
        }
    }

    private func setupReaderName() {
        readerName.titleText = "xsdk_reader_details_readername_title".localized
        readerName.descriptionText = readerInfo.readerName
        readerName.icon.removeFromSuperview()
    }

    private func setupSerialNumber() {
        if let serialNumber = readerInfo.serialNumber {
            serialNumberView.titleText = "xsdk_reader_details_serialnumber_title".localized
            serialNumberView.descriptionText = serialNumber
            serialNumberView.icon.removeFromSuperview()
        } else {
            serialNumberView.removeFromSuperview()
        }
    }

    private func setupVersion() {
        if let versionNumber = readerInfo.version {
            versionNumberView.titleText = "xsdk_reader_details_version_title".localized
            versionNumberView.descriptionText = versionNumber
            versionNumberView.icon.removeFromSuperview()
        } else {
            versionNumberView.removeFromSuperview()
        }
    }

    private func setupButton() {
        removeReaderButton.title = "xsdk_reader_details_remove_reader".localized
        let color = ClearentConstants.Color.self
        removeReaderButton.enabledBackgroundColor = color.backgroundSecondary01
        removeReaderButton.enabledTextColor = color.warning
        removeReaderButton.borderColor = color.warning
        removeReaderButton.borderWidth = ClearentConstants.Size.primaryButtonBorderWidth
        removeReaderButton.action = { [weak self] in
            self?.detailsPresenter.removeReader()
            self?.navigationController?.popViewController(animated: true)
        }
    }

    @objc func didPressBackButton() {
        navigationController?.popViewController(animated: true)
    }
}
