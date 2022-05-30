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
    @IBOutlet weak var dropDownImageView: UIImageView!
    @IBOutlet weak var readerConnectivityStatusView: ClearentReaderConnectivityStatusView!
    @IBOutlet weak var readerBatteryStatusView: ClearentReaderConnectivityStatusView!
    
    public var state: ReaderStatusHeaderViewState = .collapsed
    public var action: (() -> Void)?
    
    public override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16, relatedViewType: ClearentReadersTableView.self),
            RelativeBottomMargin(constant: 30, relatedViewType: ClearentIcon.self),
            RelativeBottomMargin(constant: 40, relatedViewType: ClearentLoadingView.self)
        ]
    }
    
    // MARK: Public
    
    public func setup(readerName: String,
                      dropDownIconName: String? = nil,
                      signalStatus: (iconName: String?, title: String),
                      batteryStatus: (iconName: String?, title: String?)) {
        readerNameLabel.text = readerName
        
        if let dropDownIconName = dropDownIconName {
            dropDownImageView.image = UIImage(named: dropDownIconName, in: ClearentConstants.bundle, compatibleWith: nil)
        }
        readerConnectivityStatusView.setup(imageName: signalStatus.iconName, status: signalStatus.title)
        
        if let batteryImage = batteryStatus.iconName, let batteryStatus = batteryStatus.title {
            readerBatteryStatusView.isHidden = false
            readerBatteryStatusView.setup(imageName: batteryImage, status: batteryStatus)
            return
        }
        readerBatteryStatusView.isHidden = true
    }
    
    public func updateDropDownIcon() {
        let iconName = state == .collapsed ? ClearentConstants.IconName.collapsed : ClearentConstants.IconName.expanded
        dropDownImageView.image = UIImage(named: iconName, in: ClearentConstants.bundle, compatibleWith: nil)
    }
    
    // MARK: Private
    
    @IBAction func didTapOnReaderStatusHeaderView(_ sender: Any) {
        state = state == .collapsed ? .expanded : .collapsed
        updateDropDownIcon()
        
        action?()
    }
}
