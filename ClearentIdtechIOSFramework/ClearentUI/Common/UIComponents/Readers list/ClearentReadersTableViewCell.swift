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
    
    @IBOutlet weak var backgroundRoundedView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var readerStatusIcon: UIView!
    @IBOutlet weak var readerNameLabel: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure()
    }
    
    // MARK: Public
    
    public static func register(tableView: UITableView) {
        tableView.register(UINib(nibName: ClearentReadersTableViewCell.nib, bundle: Bundle(for: ClearentReadersTableViewCell.self)), forCellReuseIdentifier: ClearentReadersTableViewCell.identifier)
    }
    
    public func setup(readerName: String, isFirstCell: Bool? = nil) {
        if let _ = isFirstCell {
            readerStatusIcon.backgroundColor = ClearentConstants.Color.accent01
            
            readerStatusIcon.layer.cornerRadius = readerStatusIcon.frame.width / 2
            readerStatusIcon.layer.masksToBounds = true
        } else {
            readerStatusIcon.removeFromSuperview()
        }
        
        readerNameLabel.text = readerName
    }
    
    // MARK: Private
    
    private func configure() {
        backgroundRoundedView.backgroundColor = ClearentConstants.Color.backgroundSecondary03
        backgroundRoundedView.layer.cornerRadius = 8
        backgroundRoundedView.layer.masksToBounds = true
        
        readerNameLabel.font = ClearentConstants.Font.regularSmall
        detailsButton.titleLabel?.isHidden = true
    }
}
