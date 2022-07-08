//
//  ClearentReadersTableViewCell.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Pop on 11.05.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import UIKit

class ClearentReadersTableViewCell: UITableViewCell {
    
    enum Layout {
        static let cellHeight: CGFloat = 48
    }
    
    static let identifier = "ClearentReadersTableViewCellIdentifier"
    static let nib = "ClearentReadersTableViewCell"

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var readerStatusIcon: UIView!
    @IBOutlet weak var readerNameLabel: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var roundedCornersView: UIView!

    var detailsAction: (() -> Void)?

    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure()
    }
    
    // MARK: Public
    
    public static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentReadersTableViewCell.nib, bundle: Bundle(for: ClearentReadersTableViewCell.self)), forCellReuseIdentifier: ClearentReadersTableViewCell.identifier)
    }
    
    public func setup(reader: ReaderItem) {
        if let pairedReaderInfo = ClearentWrapperDefaults.pairedReaderInfo, reader.readerInfo == pairedReaderInfo {
            if reader.isConnecting {
                setupLoadingIdicator()
            } else {
                setupReaderStatusIcon(isConnected: pairedReaderInfo.isConnected)
            }
            readerStatusIcon.isHidden = reader.isConnecting
        } else {
            readerStatusIcon.isHidden = true
        }
        readerNameLabel.text = reader.readerInfo.readerName
        if let customName = reader.readerInfo.customReaderName {
            readerNameLabel.text = customName
        }
    }
    
    // MARK: Private
    
    private func setupLoadingIdicator() {
        let loadingIndicatorView = UIActivityIndicatorView()
        stackView.insertArrangedSubview(loadingIndicatorView, at: 0)
        
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.widthAnchor.constraint(equalToConstant: 12).isActive = true
        loadingIndicatorView.heightAnchor.constraint(equalToConstant: 12).isActive = true
        loadingIndicatorView.startAnimating()
    }
    
    private func setupReaderStatusIcon(isConnected: Bool) {
        readerStatusIcon.backgroundColor = isConnected ? ClearentUIBrandConfigurator.shared.colorPalette.readerStatusConnectedIconColor : ClearentUIBrandConfigurator.shared.colorPalette.readerStatusNotConnectedIconColor
        readerStatusIcon.layer.cornerRadius = readerStatusIcon.frame.width / 2
        readerStatusIcon.layer.masksToBounds = true
    }
    
    private func configure() {
        roundedCornersView.backgroundColor = ClearentUIBrandConfigurator.shared.colorPalette.readersCellBackgroundColor
        roundedCornersView.layer.cornerRadius = 8
        roundedCornersView.layer.masksToBounds = true
        
        readerNameLabel.font = ClearentUIBrandConfigurator.shared.fonts.listItemTextFont
        readerNameLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.readerNameLabelColor
        detailsButton.setTitle("", for: .normal)
    }

    @IBAction func detailsButtonWasPressed(_: Any) {
        detailsAction?()
    }
}
