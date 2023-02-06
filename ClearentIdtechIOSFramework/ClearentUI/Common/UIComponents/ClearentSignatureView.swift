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

    // MARK: - Properties

    @IBOutlet var clearButton: UIButton!
    @IBOutlet var doneButton: ClearentPrimaryButton!
    @IBOutlet var drawingPanel: ClearentDrawingPanel!
    @IBOutlet var indicatorLabel: UILabel!
    @IBOutlet var indicatorLine: UIView!
    @IBOutlet var roundedCornersView: UIView!
    @IBOutlet var descriptionLabel: UILabel!
    private var previousOrientation: UIDeviceOrientation?

    public var doneAction: ((_ resultedImage: UIImage) -> Void)?

    override var margins: [BottomMargin] {
        [
            RelativeBottomMargin(constant: 16.0, relatedViewType: ClearentPrimaryButton.self),
            BottomMargin(constant: 16)
        ]
    }

    @IBAction func clearButtonWasTapped(_: Any) {
        drawingPanel.clearDrawing()
    }
    
    @IBAction func doneButtonWasTapped(_: Any) {
        doneAction?(drawingPanel.resultedImage)
    }
    
    override func configure() {
        setupDescriptionLabel()
        setupDoneButton()
        setupSignatureIndicator()
        setupRoundedCornersView()
        clearButton.titleLabel?.font = ClearentUIBrandConfigurator.shared.fonts.primaryButtonTextFont

        previousOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
   
    @objc func orientationDidChange() {
        guard let previousOrientation = previousOrientation else { return }
        let landscapeOrientations = [UIDeviceOrientation.landscapeLeft, UIDeviceOrientation.landscapeRight]
        let portraitOrientations = [UIDeviceOrientation.portrait, UIDeviceOrientation.portraitUpsideDown]
        
        let orientationDidChange = landscapeOrientations.contains(UIDevice.current.orientation) && portraitOrientations.contains(previousOrientation) ||
                                   portraitOrientations.contains(UIDevice.current.orientation) && landscapeOrientations.contains(previousOrientation)
        if orientationDidChange {
            drawingPanel.clearDrawing()
            self.previousOrientation = UIDevice.current.orientation
        }
    }
    
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
}
