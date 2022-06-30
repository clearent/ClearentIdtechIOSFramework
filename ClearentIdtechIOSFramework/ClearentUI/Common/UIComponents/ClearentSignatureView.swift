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
         static let cellsPerRow = 3
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
         clearButton.titleLabel?.font = ClearentConstants.Font.proTextNormal

         roundedCornersView.layer.cornerRadius = Layout.cornerRadius
         roundedCornersView.layer.borderWidth = Layout.borderWidth
         roundedCornersView.layer.borderColor = ClearentConstants.Color.backgroundSecondary02.cgColor
         
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
         doneButton.isBorderedButton = false
         doneButton.button.isUserInteractionEnabled = false
     }
 }

 class ClearentDrawingPanel: UIView {
     var bufferImage: UIImage?
     private var drawingLayer: CAShapeLayer?
     private var currentPath: UIBezierPath?
     private var temporaryPath: UIBezierPath?
     private var points = [CGPoint]()
     private var lineWidth: CGFloat = 2.0
     
     // MARK: Init
     
     override public init(frame: CGRect) {
         super.init(frame: frame)
         setup()
     }
     
     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setup()
     }
     
     private func setup() {
         layer.removeAllAnimations()
         layer.masksToBounds = true  // Restrict the drawing within the canvas
         backgroundColor = .clear
         isMultipleTouchEnabled = false
     }
     
     // MARK: Drawing
     
     override func draw(_ rect: CGRect) {
         bufferImage?.draw(in: rect)
         
         let drawingLayer = drawingLayer ?? CAShapeLayer()
         drawingLayer.contentsScale = UIScreen.main.scale
         
         drawingLayer.lineWidth = lineWidth
         drawingLayer.lineJoin = .round
         drawingLayer.lineCap = .round
         drawingLayer.fillColor = UIColor.clear.cgColor
         drawingLayer.miterLimit = 0
         drawingLayer.strokeColor = ClearentConstants.Color.base01.cgColor
         
         let linePath = UIBezierPath()
         
         if let tempPath = temporaryPath, let bezierPath = currentPath {
             linePath.append(tempPath)
             linePath.append(bezierPath)
             drawingLayer.path = linePath.cgPath
         }
         
         if self.drawingLayer == nil {
             self.drawingLayer = drawingLayer
             layer.addSublayer(drawingLayer)
         }
     }
     
     func clearDrawing() {
         bufferImage = nil
         drawingLayer?.removeFromSuperlayer()
         drawingLayer = nil
         setNeedsDisplay()
     }
     
     // MARK: - Touches
     
     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         guard let point = touches.first?.preciseLocation(in: self) else { return }
         points.removeAll()
         points.append(point)
     }
     
     override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
         guard let point = touches.first?.preciseLocation(in: self) else { return }
         points.append(point)
         updatePaths()
         layer.setNeedsDisplay()
     }
     
     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         // single touch support
         if points.count == 1 {
             currentPath = createPathStarting(at: points[0])
             currentPath?.lineWidth = lineWidth / 2.0
             currentPath?.addArc(withCenter: points[0], radius: lineWidth / 4.0, startAngle: 0, endAngle: .pi * 2.0, clockwise: true)
         }

         finishPath()
     }
     
     override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
         finishPath()
     }
     
     // MARK: - Bezier paths Management
     
     private func updatePaths() {
         // update main path
         while points.count > 4 {
             points[3] = CGPoint(x: (points[2].x + points[4].x)/2.0, y: (points[2].y + points[4].y)/2.0)
             if currentPath == nil {
                 currentPath = createPathStarting(at: points[0])
             }
             currentPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
             points.removeFirst(3)
             temporaryPath = nil
         }
         
         // build temporary path up to last touch point
         switch points.count {
         case 2:
             temporaryPath = createPathStarting(at: points[0])
             temporaryPath?.addLine(to: points[1])
             break
         case 3:
             temporaryPath = createPathStarting(at: points[0])
             temporaryPath?.addQuadCurve(to: points[2], controlPoint: points[1])
             break
         case 4:
             temporaryPath = createPathStarting(at: points[0])
             temporaryPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
             break
         default:
             break
         }
     }
     
     private func finishPath() {
         saveBufferImage()
         // add temp path to current path to reflect the changes in canvas
         if let tempPath = temporaryPath {
             currentPath?.append(tempPath)
         }
         
         currentPath = nil
     }
     
     private func createPathStarting(at point: CGPoint) -> UIBezierPath {
         let localPath = UIBezierPath()
         localPath.move(to: point)
         return localPath
     }
     
     private func saveBufferImage() {
         bufferImage = UIGraphicsImageRenderer(bounds: bounds).image { _ in
             drawHierarchy(in: bounds, afterScreenUpdates: true)
         }
     }
 }

