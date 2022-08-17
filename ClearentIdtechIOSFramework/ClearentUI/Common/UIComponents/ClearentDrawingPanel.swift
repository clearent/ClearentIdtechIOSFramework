//
//  ClearentDrawingPanel.swift
//  ClearentIdtechIOSFramework
//
//  Created by Carmen Jurcovan on 01.07.2022.
//  Copyright © 2022 Clearent, L.L.C. All rights reserved.
//

class ClearentDrawingPanel: UIView {
    var bufferImage: UIImage?
    private var drawingLayer: CAShapeLayer?
    private var currentPath: UIBezierPath?
    private var temporaryPath: UIBezierPath?
    private var points = [CGPoint]()
    private let lineWidth: CGFloat = 2.0

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        layer.removeAllAnimations()
        layer.masksToBounds = true // Restrict the drawing within the canvas
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

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let point = touches.first?.preciseLocation(in: self) else { return }
        points.removeAll()
        points.append(point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let point = touches.first?.preciseLocation(in: self) else { return }
        points.append(point)
        updatePaths()
        layer.setNeedsDisplay()
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        // single touch support
        if points.count == 1 {
            currentPath = createPathStarting(at: points[0])
            currentPath?.lineWidth = lineWidth / 2.0
            currentPath?.addArc(withCenter: points[0], radius: lineWidth / 4.0, startAngle: 0, endAngle: .pi * 2.0, clockwise: true)
        }

        finishPath()
    }

    override func touchesCancelled(_: Set<UITouch>?, with _: UIEvent?) {
        finishPath()
    }

    // MARK: - Bezier paths Management

    private func updatePaths() {
        // update main path
        while points.count > 4 {
            points[3] = CGPoint(x: (points[2].x + points[4].x) / 2.0, y: (points[2].y + points[4].y) / 2.0)
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
        case 3:
            temporaryPath = createPathStarting(at: points[0])
            temporaryPath?.addQuadCurve(to: points[2], controlPoint: points[1])
        case 4:
            temporaryPath = createPathStarting(at: points[0])
            temporaryPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
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
