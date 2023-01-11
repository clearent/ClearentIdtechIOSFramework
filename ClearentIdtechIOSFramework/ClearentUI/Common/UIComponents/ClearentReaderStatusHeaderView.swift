//
//  ClearentReaderStatusHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

public class ClearentReaderStatusHeaderView: ClearentMarginableView {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var readerNameLabel: UILabel!
    @IBOutlet weak var readerConnectivityStatusView: ClearentReaderConnectivityStatusView!
    @IBOutlet weak var readerBatteryStatusView: ClearentReaderConnectivityStatusView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var verticalSeparator: UIView!

    public var action: (() -> Void)?
    
    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentReadersTableView.self),
            RelativeBottomMargin(constant: 30, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 10, relatedViewType: ClearentIconAndLabel.self),
            RelativeBottomMargin(constant: 30, relatedViewType: ClearentAnimationWithSubtitle.self),
            RelativeBottomMargin(constant: 40, relatedViewType: ClearentLoadingView.self),
            RelativeBottomMargin(constant: 24, relatedViewType: ClearentSubtitleLabel.self),
            RelativeBottomMargin(constant: 30, relatedViewType: ClearentTitleLabel.self)
        ]
    }
    
    public override func configure() {
        readerNameLabel.font = ClearentUIBrandConfigurator.shared.fonts.readerNameTextFont
        readerNameLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.readerNameColor

        descriptionLabel.font = ClearentUIBrandConfigurator.shared.fonts.statusLabelFont
        descriptionLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.readerStatusLabelColor

        verticalSeparator.backgroundColor = ClearentConstants.Color.backgroundSecondary02
    }
    
    // MARK: Public
    
    public func setup(readerName: String,
                      dropDownIconName: String? = nil,
                      description: String? = nil,
                      signalStatus: (iconName: String?, title: String)? = nil,
                      batteryStatus: (iconName: String, title: String)? = nil) {
        readerNameLabel.text = readerName
        
        if let description = description {
            descriptionLabel.text = description
        }
        descriptionLabel.isHidden = description == nil

        setupConnectivityComponent(signalStatus: signalStatus)
        setupBatteryComponent(batteryStatus: batteryStatus)
    }

    // MARK: Private
    
    private func setupConnectivityComponent(signalStatus: (iconName: String?, title: String)? = nil) {
        if let signalStatus = signalStatus {
            readerConnectivityStatusView.setup(imageName: signalStatus.iconName, status: signalStatus.title)
        }
        readerConnectivityStatusView.isHidden = signalStatus == nil
    }
    
    private func setupBatteryComponent(batteryStatus: (iconName: String, title: String)? = nil) {
        if let batteryStatus = batteryStatus {
            readerBatteryStatusView.setup(imageName: batteryStatus.iconName, status: batteryStatus.title)
        }
        readerBatteryStatusView.isHidden = batteryStatus == nil
        verticalSeparator.isHidden = readerBatteryStatusView.isHidden
    }
    
    @IBAction func didTapOnReaderStatusHeaderView(_ sender: Any) {
        action?()
    }
}
