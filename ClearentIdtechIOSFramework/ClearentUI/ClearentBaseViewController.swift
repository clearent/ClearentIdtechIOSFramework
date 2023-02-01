//
//  ClearentBaseViewController.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 10.05.2022.
//

import UIKit

/// A custom view controller that has a semi-transparent background
open class ClearentBaseViewController: ClearentAbstractViewController {
    private let backgroundView = UIView()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        createSemiTransparentBackground()
    }
    
    private func createSemiTransparentBackground() {
        view.backgroundColor = .clear
        view.isOpaque = false
        backgroundView.backgroundColor = ClearentConstants.Color.backgroundPrimary02
        backgroundView.alpha = 0.8
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.height)
        ])
    }
    
    func removeSemiTransparentBackground() {
        view.backgroundColor = .white
        view.isOpaque = true
        backgroundView.removeFromSuperview()
    }
}
