//
//  FTShapeEditController.swift
//  Noteshelf
//
//  Created by Sameer on 16/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTShapeControllerEditDelegate: AnyObject {
    func didUpdateShape(with sides: CGFloat)
    func referenceView() -> UIView
    func contentScale() -> CGFloat
    func snappedAngle() -> CGFloat
}

class FTShapeEditController: UIViewController {
    var circleView: FTKnobCircleView?
    var specialKnob: FTSpecialKnobView?
    var dragKnobView: FTDragView?
    var snappedAngle = CGFloat.zero
    weak var delegate: FTShapeControllerEditDelegate?
    let defaultSides: CGFloat = 3
    let THRESHOLDANGLE : CGFloat = 10;
    let ANGLEJUMP : CGFloat = 40;
    
    var scale : CGFloat {
        var scaleToReturn : CGFloat = 1;
        if let del = self.delegate {
            scaleToReturn = del.contentScale();
        }
        return scaleToReturn;
    };
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func configureShapeEditView() {
        if let view = self.delegate?.referenceView() as? FTResizableView, circleView == nil {
            self.view.frame = view.contentFrame()
            addCircleView()
        }
    }
    
    func removeCircleView() {
        circleView?.removeFromSuperview()
        dragKnobView?.removeFromSuperview()
        specialKnob?.removeFromSuperview()
        dragKnobView = nil
        specialKnob = nil
        circleView = nil
    }
    
    func addCircleView() {
        if (circleView == nil) {
            circleView = FTKnobCircleView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.size.width * 0.7, height: view.frame.size.height * 0.7)))
            if let circleView = circleView {
                if let refPoint = parent?.view.convert(view.center, to: view) {
                    circleView.center = refPoint
                }
                circleView.backgroundColor = .clear
                circleView.isHidden = true
                view.addSubview(circleView)
                let point = circleView.point(onEllipse: delegate?.snappedAngle() ?? 80)
                addControlKnob(at: point)
            }
        }
    }

    private func addControlKnob(at point: CGPoint) {
        specialKnob = FTSpecialKnobView(with: point)
        dragKnobView = FTDragView(with: point)
        dragKnobView?.center = point
        specialKnob?.center = point
        view.addSubview(specialKnob!)
        view.addSubview(dragKnobView!)
    }
    
    func knobView(for point: CGPoint) -> UIView? {
        var view: UIView?
        for eachView in self.view.subviews where eachView is FTDragView  {
            if eachView.frame.contains(point) {
                view = eachView
                break
            }
        }
        return view
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        let point = firstTouch.location(in: self.view)
        let knobView = knobView(for: point)
        NotificationCenter.default.post(name: Notification.Name(FTPDFDisableGestures), object: self.view.window);
        circleView?.isHidden = false
        if let knob = knobView as? FTDragView {
            dragKnobView = knob
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        if dragKnobView != nil {
            didMoveCircle(firstTouch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        NotificationCenter.default.post(name: Notification.Name(FTPDFEnableGestures), object: self.view.window);
        if let specialKnob = specialKnob {
            dragKnobView?.center = specialKnob.center
            circleView?.isHidden = true
        }
        dragKnobView = nil
    }
    
    private func didMoveCircle(_ touch: UITouch) {
        let curPoint = touch.location(in: self.view);
        if let circleView = circleView {
            let center = circleView.center
            let currentCenterAngle = atan2((curPoint.y - center.y),
                                           (curPoint.x - center.x))
            var angleInDegrees = abs(self.angleWRT360Degree(angleInRadians: currentCenterAngle) + CGFloat(90))
            if angleInDegrees > 360 {
                angleInDegrees = angleInDegrees.truncatingRemainder(dividingBy: 360)
            }
            dragKnobView?.center = curPoint
            if  angleInDegrees == 360 {
                return
            }
            if snapToNearAngleIfNeeded(byAddingAngle: angleInDegrees) {
                let numberOfSides = snappedAngle / 40 + defaultSides
                let point = circleView.point(onEllipse: snappedAngle)
                self.delegate?.didUpdateShape(with: numberOfSides)
                specialKnob?.center = point
            }
        }
    }
}

private extension FTShapeEditController {
    func snapToNearAngleIfNeeded(byAddingAngle newangle: CGFloat) -> Bool
    {
        let angle = snappedAngle;
        let angleToConsider = newangle;
        let previous90 = self.nearestPrevSnapAngle(angle: angleToConsider);
        let next90 = self.nearestNextSnapAngle(angle: snappedAngle);
        if(abs(angleToConsider - previous90) <= THRESHOLDANGLE) {
            let nearestAngle = previous90 - angle;
            if(abs(nearestAngle) > 0.01)  {
                snappedAngle = previous90
                return true;
            }
        }
        else if(abs(next90 - angleToConsider) <= THRESHOLDANGLE) {
            let nearestAngle = next90 - angle;
            if(abs(nearestAngle) > 0.01)  {
                snappedAngle = next90
                return true;
            }
        }
        return false;
    }
    
    func currentViewAngle() -> CGFloat {
        circleView!.transform.angle
    }
    
    func angleWRT360Degree(angleInRadians : CGFloat) -> CGFloat
    {
        var angle = round(angleInRadians*RADIANS_TO_DEGREE);
        if(abs(angle) < 0.01) {
            angle = 0;
        }
        
        let angleWrt360 = Int(abs(angle)/360);
        if(angle < 0) {
            angle = (CGFloat(angleWrt360)*360.0)+angle;
        }
        else {
            angle -= (CGFloat(angleWrt360)*360);
        }
        
        if(angle < 0) {
            angle = 360.0 + angle;
        }
        
        if(angle >= 360.0) {
            angle = (angle - 360.0);
        }
        
        return angle;
    }
    
    func nearestNextSnapAngle(angle : CGFloat) -> CGFloat
    {
        let angle = angle
        let angleQuotent = Int(angle/ANGLEJUMP);
        var newAngle = CGFloat(angleQuotent)*ANGLEJUMP+ANGLEJUMP;
        if newAngle > 360 {
            newAngle = newAngle.truncatingRemainder(dividingBy: 360)
        }
        return newAngle;
    }
    
    func nearestPrevSnapAngle(angle : CGFloat) -> CGFloat
    {
        let angle = angle;
        let angleQuotent = Int(angle/ANGLEJUMP);
        let previous90 = CGFloat(angleQuotent)*ANGLEJUMP;
        return previous90;
    }
}

class FTSpecialKnobView: UIView {
    var imageView: UIImageView?
    var segmentIndex: Int = 0
    
    init(with point: CGPoint) {
        super.init(frame: CGRect(origin: point, size: CGSize(width: 20, height: 20)))
        addImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addImageView() {
        imageView = UIImageView(image: UIImage(named: "specialknob"))
        if let imageView = imageView {
            imageView.frame = frame
            imageView.frame.origin = .zero
            self.addSubview(imageView)
        }
    }
}
