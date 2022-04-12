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
    
    override var margins: [RelativeMargin] {
        [RelativeMargin(constant: 58.0, relatedViewType: ClearentUserActionView.self)]
    }
    
    // MARK: Public
    
    public func setup(readerName: String,
                      connectivityStatusImageName: String,
                      connectivityStatus: String,
                      readerBatteryStatusImageName: String?,
                      readerBatteryStatus: String?) {
        readerNameLabel.text = readerName
        readerConnectivityStatusView.setup(imageName: connectivityStatusImageName, status: connectivityStatus)
        readerBatteryStatusView.setup(imageName: readerBatteryStatusImageName, status: readerBatteryStatus)
    }
}
