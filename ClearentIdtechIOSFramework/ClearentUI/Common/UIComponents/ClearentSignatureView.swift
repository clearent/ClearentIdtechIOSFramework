//
 //  ClearentSignatureView.swift
 //  ClearentIdtechIOSFramework
 //
 //  Created by Carmen Jurcovan on 29.06.2022.
 //  Copyright © 2022 Clearent, L.L.C. All rights reserved.
 //

 import Foundation

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
     private var previousOrientation: UIDeviceOrientation = .unknown
     
     public var doneAction: ((_ resultedImage: UIImage) -> Void)?
     
     override var margins: [BottomMargin] {
         [RelativeBottomMargin(constant: 16.0, relatedViewType: ClearentPrimaryButton.self),
         BottomMargin(constant: 16)]
     }

     @IBAction func clearButtonWasTapped(_ sender: Any) {
         drawingPanel.clearDrawing()
     }
     
     @IBAction func doneButtonWasTapped(_ sender: Any) {
         doneAction?(drawingPanel.bufferImage ?? UIImage())
     }
     
     override func configure() {
         setupDescriptionLabel()
         setupDoneButton()
         setupSignatureIndicator()
         setupRoundedCornersView()
         clearButton.titleLabel?.font = ClearentConstants.Font.proTextNormal

         NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
     }
    
     @objc func orientationDidChange() {
         if UIDevice.current.orientation != previousOrientation {
             drawingPanel.clearDrawing()
             previousOrientation = UIDevice.current.orientation
         }
     }
     
     deinit {
         NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
     }
     
     // MARK: - Private
     
     private func setupDescriptionLabel() {
         descriptionLabel.text = "xsdk_signature_subtitle".localized
         descriptionLabel.font = ClearentConstants.Font.proTextSmall
         descriptionLabel.textAlignment = .left
         descriptionLabel.textColor = ClearentConstants.Color.base01
     }
     
     private func setupSignatureIndicator() {
         indicatorLine.backgroundColor = ClearentConstants.Color.base05
         indicatorLabel.textColor = ClearentConstants.Color.base05
     }
     
     private func setupDoneButton() {
         doneButton.title = "xsdk_signature_action".localized
         doneButton.button.isUserInteractionEnabled = false
     }
     
     private func setupRoundedCornersView() {
         roundedCornersView.layer.cornerRadius = Layout.cornerRadius
         roundedCornersView.layer.borderWidth = Layout.borderWidth
         roundedCornersView.layer.borderColor = ClearentConstants.Color.backgroundSecondary02.cgColor
     }
 }
