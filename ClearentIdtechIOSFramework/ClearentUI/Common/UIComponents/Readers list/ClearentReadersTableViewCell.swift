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
        guard let pairedReaderInfo = ClearentWrapperDefaults.pairedReaderInfo else { return }
        readerStatusIcon.isHidden = reader.readerInfo.readerName != pairedReaderInfo.readerName
        if reader.readerInfo.readerName == pairedReaderInfo.readerName {
            
            if reader.isConnecting {
                let loadingIndicatorView = UIActivityIndicatorView()
                stackView.insertArrangedSubview(loadingIndicatorView, at: 0)
                
                loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
                loadingIndicatorView.widthAnchor.constraint(equalToConstant: 12).isActive = true
                loadingIndicatorView.heightAnchor.constraint(equalToConstant: 12).isActive = true
                loadingIndicatorView.startAnimating()
            } else {
                readerStatusIcon.backgroundColor = pairedReaderInfo.isConnected ? ClearentConstants.Color.accent01 : ClearentConstants.Color.accent02
                readerStatusIcon.layer.cornerRadius = readerStatusIcon.frame.width / 2
                readerStatusIcon.layer.masksToBounds = true
            }
            readerStatusIcon.isHidden = reader.isConnecting
        }
        readerNameLabel.text = reader.readerInfo.readerName
    }
    
    // MARK: Private
    
    private func configure() {
        roundedCornersView.backgroundColor = ClearentConstants.Color.backgroundSecondary03
        roundedCornersView.layer.cornerRadius = 8
        roundedCornersView.layer.masksToBounds = true
        
        readerNameLabel.font = ClearentConstants.Font.proTextNormal
        detailsButton.setTitle("", for: .normal)
    }

    @IBAction func detailsButtonWasPressed(_: Any) {
        detailsAction?()
    }
}
