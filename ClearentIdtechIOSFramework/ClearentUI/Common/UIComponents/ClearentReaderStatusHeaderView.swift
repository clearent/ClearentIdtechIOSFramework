//
//  ClearentReaderStatusHeaderView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 05.04.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReaderStatusHeaderView: ClearentMarginableView {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var readerNameLabel: UILabel!
    @IBOutlet weak var readerConnectivityStatusView: ClearentReaderConnectivityStatusView!
    @IBOutlet weak var readerBatteryStatusView: ClearentReaderConnectivityStatusView!
    
    override var margins: [Margin] {
        [
            RelativeMargin(constant: 50.0, relatedViewType: ClearentUserActionView.self),
            RelativeMargin(constant: 30.0, relatedViewType: ClearentReaderFeedbackView.self)
        ]
    }
    
    // MARK: Public
    
    public func setup(readerName: String,
                      connectivityStatusImageName: String,
                      connectivityStatus: String,
                      readerBatteryStatusImageName: String?,
                      readerBatteryStatus: String?) {
        readerNameLabel.text = readerName
        readerConnectivityStatusView.setup(imageName: connectivityStatusImageName, status: connectivityStatus)
        guard let batteryImage = readerBatteryStatusImageName, let batteryStatus = readerBatteryStatus else {
            readerBatteryStatusView.isHidden = true
            return
        }
        readerBatteryStatusView.setup(imageName: batteryImage, status: batteryStatus)
    }
}
