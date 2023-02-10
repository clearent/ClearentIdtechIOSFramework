//
//  ClearentSignatureView.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 29.06.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

import Foundation
import UIKit

class ClearentSignatureView: ClearentMarginableView {
    private struct Layout {
        static let cornerRadius = 8.0
        static let borderWidth = 1.0
    }

    // MARK: - IBOutlets

    @IBOutlet var clearButton: UIButton!
    @IBOutlet var doneButton: ClearentPrimaryButton!
    @IBOutlet var drawingPanel: ClearentDrawingPanel!
    @IBOutlet var indicatorLabel: UILabel!
    @IBOutlet var indicatorLine: UIView!
    @IBOutlet var roundedCornersView: UIView!
    @IBOutlet var descriptionLabel: UILabel!
    
    // MARK: - Properties
    
    private var previousOrientation: UIInterfaceOrientation?
    public var doneAction: ((_ resultedImage: UIImage) -> Void)?

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16.0, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 16)
        ]
    }

    // MARK: - Actions
    
    @IBAction func clearButtonWasTapped(_: Any) {
        drawingPanel.clearDrawing()
    }
    
    @IBAction func doneButtonWasTapped(_: Any) {
        doneAction?(drawingPanel.resultedImage)
    }
    
    // MARK: - Internal
    
    override func configure() {
        setupDescriptionLabel()
        setupDoneButton()
        setupSignatureIndicator()
        setupRoundedCornersView()
        clearButton.titleLabel?.font = ClearentUIBrandConfigurator.shared.fonts.primaryButtonTextFont

        setupPreviousOrientation()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func orientationDidChange() {
        guard let previousOrientation = previousOrientation else { return }
        let orientationDidChange = previousOrientation.isPortrait && Orientation.isLandscape || previousOrientation.isLandscape && Orientation.isPortrait
        if orientationDidChange {
            drawingPanel.clearDrawing()
            setupPreviousOrientation()
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // MARK: - Private
    
    private func setupDescriptionLabel() {
        descriptionLabel.text = ClearentConstants.Localized.Signature.subtitle
        descriptionLabel.font = ClearentUIBrandConfigurator.shared.fonts.signatureSubtitleFont
        descriptionLabel.textAlignment = .left
        descriptionLabel.textColor = ClearentUIBrandConfigurator.shared.colorPalette.signatureDescriptionMessageColor
    }
    
    private func setupSignatureIndicator() {
        indicatorLine.backgroundColor = ClearentConstants.Color.base05
        indicatorLabel.textColor = ClearentConstants.Color.base05
    }
    
    private func setupDoneButton() {
        doneButton.title = ClearentConstants.Localized.Signature.action
        doneButton.button.isUserInteractionEnabled = false
    }
    
    private func setupRoundedCornersView() {
        roundedCornersView.layer.cornerRadius = Layout.cornerRadius
        roundedCornersView.layer.borderWidth = Layout.borderWidth
        roundedCornersView.layer.borderColor = ClearentConstants.Color.backgroundSecondary02.cgColor
    }
    
    private func setupPreviousOrientation() {
        previousOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
    }
}


private struct Orientation {
    static var isPortrait: Bool {
        get { UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isPortrait ?? false }
    }
    
    static var isLandscape: Bool {
        get { UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false }
    }
}
