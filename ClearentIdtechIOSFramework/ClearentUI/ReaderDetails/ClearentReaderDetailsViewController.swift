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
    @IBOutlet var serialNumber: ClearentInfoWithIcon!
    @IBOutlet var versionNumber: ClearentInfoWithIcon!
    @IBOutlet var removeReaderButton: ClearentPrimaryButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
      //  setupTexts()
        setupButton()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTexts()
    }
    
    func setupTexts() {
        guard let readerInfo = detailsPresenter.readerInfo else { return }
        connectedView.titleText = "xsdk_reader_details_connected".localized
        connectedView.descriptionText = ""
        connectedView.isOn = readerInfo.isConnected
        
        let signal = String(readerInfo.signalLevel!)
        let battery = String(readerInfo.batterylevel!)
        signalStatusView.title = String(format: "xsdk_reader_details_signal_status".localized, signal)
        batteryStatusView.title = String(format: "xsdk_reader_details_battery_status".localized, battery)
        
        autojoinView.titleText = "xsdk_reader_details_autojoin_title".localized
        autojoinView.descriptionText = "xsdk_reader_details_autojoin_description".localized
        
        readerName.titleText = "xsdk_reader_details_readername_title".localized
        readerName.descriptionText = readerInfo.readerName
        
        serialNumber.titleText = "xsdk_reader_details_serialnumber_title".localized
        serialNumber.descriptionText = readerInfo.serialNumber
        
        versionNumber.titleText = "xsdk_reader_details_version_title".localized
        versionNumber.descriptionText = readerInfo.version
        
        removeReaderButton.title = "xsdk_reader_details_remove_reader".localized
    }
    
    func setupButton() {
        let color = ClearentConstants.Color.self
        removeReaderButton.enabledBackgroundColor = color.backgroundSecondary01
        removeReaderButton.enabledTextColor = color.warning
        removeReaderButton.borderColor = color.warning
        removeReaderButton.borderWidth = ClearentConstants.Size.primaryButtonBorderWidth
        removeReaderButton.action = {
            // TODO
        }
    }
}
