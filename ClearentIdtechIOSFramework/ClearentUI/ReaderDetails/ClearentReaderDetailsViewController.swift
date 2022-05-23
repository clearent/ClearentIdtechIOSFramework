//
//  ClearentReaderDetailsViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 16.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

protocol LoadingViewProtocol {
    var loadingView: UIView { get }
    func showFullScreenLoadingView()
    func removeLoadingView()
}

extension LoadingViewProtocol where Self: UIViewController {
    func showFullScreenLoadingView() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow } )  {
            loadingView.frame = window.bounds
            loadingView.backgroundColor = ClearentConstants.Color.backgroundPrimary02.withAlphaComponent(0.6)
            window.addSubview(loadingView)
            let activityIndicator = ClearentLoadingView(color: ClearentConstants.Color.backgroundPrimary02, lineWidth: 4)
            activityIndicator.center = loadingView.center
            loadingView.translatesAutoresizingMaskIntoConstraints = true
            DispatchQueue.main.async {
                self.loadingView.addSubview(activityIndicator)
            }
        }
    }
    
    func removeLoadingView() {
        DispatchQueue.main.async {
            self.loadingView.removeFromSuperview()
        }
    }
}

class ClearentReaderDetailsViewController: UIViewController, LoadingViewProtocol {
    public lazy var loadingView: UIView = UIView(frame: .zero)
    
    var detailsPresenter: ClearentReaderDetailsProtocol!

    @IBOutlet weak var stackView: ClearentAdaptiveStackView!
    @IBOutlet var connectedView: ClearentLabelSwitch!
    @IBOutlet var signalStatusView: ClearentLabelWithIcon!
    @IBOutlet var batteryStatusView: ClearentLabelWithIcon!
    @IBOutlet var autojoinView: ClearentLabelSwitch!
    @IBOutlet var readerName: ClearentInfoWithIcon!
    @IBOutlet var serialNumberView: ClearentInfoWithIcon!
    @IBOutlet var versionNumberView: ClearentInfoWithIcon!
    @IBOutlet var removeReaderButton: ClearentPrimaryButton!

    var readerInfo: ReaderInfo { detailsPresenter.currentReader }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupSwitches()
        updateReaderInfo()
        setupReaderName()
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
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = view.backgroundColor
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = ClearentConstants.Color.backgroundPrimary02
        navigationController?.navigationBar.titleTextAttributes = [.font: ClearentConstants.Font.proDisplayBoldLarge]
        navigationItem.title = "xsdk_reader_details_nav_title".localized
    }

    private func setupSwitches() {
        connectedView.titleText = "xsdk_reader_details_connected".localized
        connectedView.descriptionText = ""
        connectedView.isOn = readerInfo.isConnected
        connectedView.valueChangedAction = { [weak self] isOn in
            guard let strongSelf = self else { return }
            if isOn {
                let modalVC = ClearentUIManager.shared.viewController(processType: .pairing(withReader: strongSelf.readerInfo)) { isConnected in
                    strongSelf.didChangedConnectionStatus(reader: strongSelf.readerInfo, isConnected: isConnected)
                }
                strongSelf.navigationController?.present(modalVC, animated: false)
            } else {
                strongSelf.detailsPresenter.disconnectFromReader()
                strongSelf.didChangedConnectionStatus(reader: strongSelf.readerInfo, isConnected: false)
            }
        }

        autojoinView.titleText = "xsdk_reader_details_autojoin_title".localized
        autojoinView.descriptionText = "xsdk_reader_details_autojoin_description".localized
        autojoinView.isOn = readerInfo.autojoin
        autojoinView.valueChangedAction = { [weak self] isOn in
            self?.showFullScreenLoadingView()
            self?.detailsPresenter.handleAutojoin(markAsAutojoin: isOn)
        }
    }
    
    private func didChangedConnectionStatus(reader: ReaderInfo, isConnected: Bool) {
        if let defaultReader = ClearentWrapperDefaults.pairedReaderInfo {
            detailsPresenter.currentReader = defaultReader
        }
        connectedView.isOn = isConnected
        updateReaderInfo()
    }

    func updateReaderInfo() {
        setupReaderStatus()
        setupSerialNumber()
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
        readerName.titleText = "xsdk_reader_details_readername_title".localized
        readerName.descriptionText = readerInfo.readerName
        readerName.icon.isHidden = true
    }

    private func setupSerialNumber() {
        if let serialNumber = readerInfo.serialNumber {
            serialNumberView.titleText = "xsdk_reader_details_serialnumber_title".localized
            serialNumberView.descriptionText = serialNumber
            serialNumberView.icon.isHidden = true
        }
        serialNumberView.isHidden = readerInfo.serialNumber == nil
    }

    private func setupVersion() {
        if let versionNumber = readerInfo.version {
            versionNumberView.titleText = "xsdk_reader_details_version_title".localized
            versionNumberView.descriptionText = versionNumber
            versionNumberView.icon.isHidden = true
        }
        versionNumberView.isHidden = readerInfo.version == nil
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
        }
    }

    @objc func didPressBackButton() {
        detailsPresenter.handleBackAction()
    }
}
