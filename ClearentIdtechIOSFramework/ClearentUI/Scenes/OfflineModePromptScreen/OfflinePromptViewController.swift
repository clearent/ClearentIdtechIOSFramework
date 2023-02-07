//
//  OfflinePromptViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Ovidiu Rotaru on 07.02.2023.
//  Copyright © 2023 Clearent, L.L.C. All rights reserved.
//

import UIKit

class OfflinePromptViewController: ClearentBaseViewController {
    
    
    @IBOutlet weak var stackView: ClearentRoundedCornersStackView!
    
    // MARK: - Init
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: String(describing: OfflinePromptViewController.self), bundle: ClearentConstants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
