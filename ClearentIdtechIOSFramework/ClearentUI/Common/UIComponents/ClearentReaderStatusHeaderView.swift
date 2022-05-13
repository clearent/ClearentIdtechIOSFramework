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
                      signalStatusIconName: String,
                      signalStatusTitle: String,
                      batteryStatusIconName: String?,
                      batteryStatusTitle: String?) {
        readerNameLabel.text = readerName
        
        guard let dropDownIconName = dropDownIconName else { return }
        dropDownImageView.image = UIImage(named: dropDownIconName, in: ClearentConstants.bundle, compatibleWith: nil)
        readerConnectivityStatusView.setup(imageName: signalStatusIconName, status: signalStatusTitle)
        
        if let batteryImage = batteryStatusIconName, let batteryStatus = batteryStatusTitle {
            readerBatteryStatusView.isHidden = false
            readerBatteryStatusView.setup(imageName: batteryImage, status: batteryStatus)
            return
        }
        readerBatteryStatusView.isHidden = true
    }
    
    public func updateDropDownIcon() {
        dropDownImageView.image = state == .collapsed ? UIImage(named: ClearentConstants.IconName.collapsed, in: ClearentConstants.bundle, compatibleWith: nil) :
        UIImage(named: ClearentConstants.IconName.expanded, in: ClearentConstants.bundle, compatibleWith: nil)
    }
}
