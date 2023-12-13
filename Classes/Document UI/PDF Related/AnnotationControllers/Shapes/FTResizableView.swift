//
//  FTResizableView.swift
//  Noteshelf
//
//  Created by Sameer on 10/02/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
let diameter:CGFloat = 40
let angleJump: CGFloat = 90

protocol FTResizableViewDelegate: AnyObject {
    func rotateShape(with angle: CGFloat)
    func contextMenuInteraction(action: FTShapeEditAction)
}

class FTResizableObject: NSObject {
    static func resizableView(with frame: CGRect, isPerfectShape: Bool) -> FTResizableView {
        if isPerfectShape {
            return FTResizableView(frame: frame)
        }
        return FTEmptyView(frame: frame)
    }
}

class FTResizableView: UIView {
    var topLeft:FTKnobView!
    var topRight:FTKnobView!
    var bottomLeft:FTKnobView!
    var bottomRight:FTKnobView!
    var rightMid:FTKnobView!
    var topMid:FTKnobView!
    var bottomMid:FTKnobView!
    var leftMid:FTKnobView!
    var rotateHandle:FTRotateKnobView!
    var rotateDegree: UILabel!
    var angleInfoView: FTAnlgeInfoView!
    var previousLocation = CGPoint.zero
    var rotateLine = CAShapeLayer()
    var path = UIBezierPath()
    
    weak var delegate: FTResizableViewDelegate?
    
    func getActiveControlPoint(for view: FTKnobView) -> FTControlPoint {
        var activeControlPoint = FTControlPoint.topLeft
        switch view {
        case topLeft:
            activeControlPoint = .topLeft
        case topRight:
            activeControlPoint = .topRight
        case bottomLeft:
            activeControlPoint = .bottomLeft
        case bottomRight:
            activeControlPoint = .bottomRight
        case topMid:
            activeControlPoint = .topMid
        case rightMid:
            activeControlPoint = .rightSideMid
        case bottomMid:
            activeControlPoint = .bottomMid
        case leftMid:
            activeControlPoint = .leftSideMid
        default:
            activeControlPoint = .topLeft
        }
        return activeControlPoint
    }
    
    func activeControlPoint(for refPoint: CGPoint) -> FTControlPoint? {
        let views: [FTKnobView] = [topLeft, topRight, bottomLeft, bottomRight]
        let returnView = views.first { eachView in
           eachView.frame.insetBy(dx: -30, dy: -30).contains(refPoint)
        }
        if let returnView {
            return self.getActiveControlPoint(for: returnView)
        }
        return nil
    }
    
    
    
    override func draw(_ rect: CGRect) {
        //createShape()
        //        UIColor.white.setFill()
        //        path.fill()
        //        UIColor.black.setStroke()
        //        path.stroke()
    }
    
    func rotateHandleTapped() {
        let nearestAngle = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle())
        let currentAngle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle())
        let rotatedAngle = (nearestAngle-currentAngle)*(DEGREE_TO_RADIANS)
        self.delegate?.rotateShape(with: rotatedAngle)
    }
    
    func createShape() {
        path = UIBezierPath()
        path.lineWidth = 4
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: 0.0, y: self.frame.size.height))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: 0.0))
        path.close()
    }
    
    override func didMoveToSuperview() {
        topLeft = FTKnobView()
        topRight = FTKnobView()
        bottomLeft = FTKnobView()
        bottomRight = FTKnobView()
        rotateHandle = FTRotateKnobView(with: .zero)
        topMid = FTKnobView()
        bottomMid = FTKnobView()
        rightMid = FTKnobView()
        leftMid = FTKnobView()
        rotateDegree = UILabel()
        rotateDegree.frame.size = CGSize(width: 50, height: 20)
        rotateDegree.text = "\(0)"
        rotateDegree.textColor = .black
        rotateLine.opacity = 0.0
//        rotateLine.lineDashPattern = [3,2]
        angleInfoView = FTAnlgeInfoView()
        showAngleInfoView(show: false)

        superview?.addSubview(topLeft)
        superview?.addSubview(topRight)
        superview?.addSubview(bottomLeft)
        superview?.addSubview(bottomRight)
        superview?.addSubview(topMid)
        superview?.addSubview(bottomMid)
        superview?.addSubview(leftMid)
        superview?.addSubview(rightMid)
        
        superview?.addSubview(rotateHandle)
        superview?.addSubview(angleInfoView)

        //superview?.addSubview(rotateDegree)
//        layer.borderColor = UIColor.red.cgColor
//        layer.borderWidth = 5
        self.updateDragHandles()
    }
    
    func updateDragHandles(with scale: CGFloat = 1.0) {
        if self.frame != .null && !self.frame.isInfinite {
            topLeft.center.updateIfRequired(with: transformedTopLeft())
            topRight.center.updateIfRequired(with: transformedTopRight())
            bottomLeft.center.updateIfRequired(with: transformedBottomLeft())
            bottomRight.center.updateIfRequired(with: transformedBottomRight())
            topMid.center.updateIfRequired(with: transformedTopMid())
            rightMid.center.updateIfRequired(with: transformedRightMid())
            bottomMid.center.updateIfRequired(with: transformedBottomMid())
            leftMid.center.updateIfRequired(with: transformedLeftMid())
            rotateHandle.center.updateIfRequired(with: transformedRotateHandle(with: 30))
            angleInfoView.center.updateIfRequired(with: transformedRotateDegree())
        }
    }
    
    func angleBetweenPoints(startPoint:CGPoint, endPoint:CGPoint)  -> CGFloat {
        let a = startPoint.x - self.center.x
        let b = startPoint.y - self.center.y
        let c = endPoint.x - self.center.x
        let d = endPoint.y - self.center.y
        let atanA = atan2(a, b)
        let atanB = atan2(c, d)
        return atanA - atanB
    }
    
    func centerWithinBoundary(_ center: CGPoint) -> CGPoint {
        guard let superView = self.superview else { return center }

        let superViewBounds = superView.bounds
        let currentFrame = self.frame

        var frame = CGRect(
            x: center.x - currentFrame.width * 0.5,
            y: center.y - currentFrame.height * 0.5,
            width: currentFrame.width,
            height: currentFrame.height
        )

        // Ensure the frame stays completely within the superview bounds
        frame.origin.x = min(max(frame.origin.x, 0), superViewBounds.width - frame.width)
        frame.origin.y = min(max(frame.origin.y, 0), superViewBounds.height - frame.height)

        return CGPoint(x: frame.midX, y: frame.midY)
    }
    
    func updateDegreeLabel(angleInRadians : CGFloat) {
        let angleInDegree = angleWRT360Degree(angleInRadians: angleInRadians)
        rotateDegree.text = "\(Int(angleInDegree))"
        print(angleInDegree)
    }
    
    func showAngleInfoView(show: Bool) {
        angleInfoView.isHidden = !show
    }
    
    func updateAngleInfo() {
        let angle = self.angleWRT360Degree(angleInRadians: self.transform.angle)
        angleInfoView.updateAngleLabel(with: Int(angle))
    }
}

class FTEmptyView: FTResizableView {
    override func didMoveToSuperview() {
        rotateHandle = FTRotateKnobView(with: .zero)
        angleInfoView = FTAnlgeInfoView()
        showAngleInfoView(show: false)
        superview?.addSubview(rotateHandle)
        superview?.addSubview(angleInfoView)
//        layer.borderColor = UIColor.red.cgColor
//        layer.borderWidth = 2
        updateDragHandles()
    }
    
    override func updateDragHandles(with scale: CGFloat = 1.0) {
        if self.frame != .null && !self.frame.isInfinite {
            rotateHandle.center.updateIfRequired(with: transformedRotateHandle(with: 20))
            angleInfoView.center.updateIfRequired(with: transformedRotateDegree())
        }
    }
}

#if targetEnvironment(macCatalyst)
extension FTResizableView: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            var actions = [UIMenuElement]()
            let cutAction = UIAction(title: NSLocalizedString("Cut", comment: "Cut")) { [weak self] _ in
                self?.delegate?.contextMenuInteraction(action: .cut)
            }
            actions.append(cutAction)

            let copyAction = UIAction(title: NSLocalizedString("Copy", comment: "Copy")) { [weak self] _ in
                self?.delegate?.contextMenuInteraction(action: .copy)
            }
            actions.append(copyAction)

            let deleteAction = UIAction(title: NSLocalizedString("Delete", comment: "Delete")) { [weak self] _ in
                self?.delegate?.contextMenuInteraction(action: .delete)
            }
            deleteAction.attributes = .destructive;
            actions.append(deleteAction)
            
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}
#endif

class FTAnlgeInfoView: UIView {
    var angleLabel: UILabel?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(hexString: "#3C3C43")
        self.frame.size = CGSize(width: 46, height: 25)
        self.layer.cornerRadius = 10;
        
        self.layer.shadowColor = UIColor.black.cgColor;
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 0.12;
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0);
        addLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addLabel() {
        angleLabel = UILabel(frame: frame)
        angleLabel?.textAlignment = .center
        angleLabel?.font =  UIFont.appFont(for: .medium, with: 15)
        angleLabel?.textColor = UIColor.white
        self.addSubview(angleLabel!)
    }
    
    func updateAngleLabel(with angle: Int) {
        angleLabel?.text = "\(angle)º";
    }
}
extension CGPoint {
    func isNaN() -> Bool {
        if self.x.isNaN || self.y.isNaN {
            return true
        }
        return false
    }
    
    mutating func updateIfRequired(with point: CGPoint) {
        if !point.isNaN() {
            self = point
        }
    }
}
