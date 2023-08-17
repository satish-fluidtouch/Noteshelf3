//
//  FTImageEditorViewController.swift
//  Noteshelf
//
//  Created by Matra on 06/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

let MIN_IMAGE_VIEW_HEIGHT : CGFloat = 60;
let THRESHOLD_ANGLE : CGFloat = 10;
let ANGLE_JUMP : CGFloat = 90;
let CONTROL_POINT_SIZE : CGFloat = 40

let RADIANS_TO_DEGREE : CGFloat = 180.0/CGFloat.pi;
let DEGREE_TO_RADIANS : CGFloat = CGFloat.pi/180.0;

class FTLineDashView : UIView
{
    private weak var drawLineLayer : CAShapeLayer?;
    
    private var shapeLayer : CAShapeLayer {
        if(nil == drawLineLayer) {
            let shapelayer = CAShapeLayer.init();
            self.layer.addSublayer(shapelayer);
            self.drawLineLayer = shapelayer;
            self.drawLineLayer?.masksToBounds=true
            self.drawLineLayer?.strokeColor = UIColor(hexString: "007aff").cgColor
            self.drawLineLayer?.lineDashPattern = [4, 4]
            self.drawLineLayer?.lineWidth = 2.0
            self.drawLineLayer?.lineJoin=CAShapeLayerLineJoin.miter
            self.drawLineLayer?.frame = self.bounds;
            self.drawLineLayer?.fillColor = nil;
            let path = UIBezierPath.init();
            path.move(to: CGPoint.init(x: self.bounds.midX, y: 0));
            path.addLine(to: CGPoint.init(x: self.bounds.midX, y: self.bounds.maxY));
            self.drawLineLayer?.path = path.cgPath
            self.drawLineLayer?.allowsEdgeAntialiasing = true;
            self.layer.allowsEdgeAntialiasing = true;
        }
        return drawLineLayer!;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        CATransaction.begin();
        CATransaction.setDisableActions(true);
        self.shapeLayer.frame = self.bounds;
        let path = UIBezierPath.init();
        path.move(to: CGPoint.init(x: self.bounds.midX, y: 0));
        path.addLine(to: CGPoint.init(x: self.bounds.midX, y: self.bounds.maxY));
        self.shapeLayer.path = path.cgPath
        CATransaction.commit();
    }
}

@objcMembers public class FTImageResizeViewController: UIViewController {
    
    @IBOutlet weak var leftTopKnob : UIView?;
    @IBOutlet weak var rightTopKnob : UIView?;
    @IBOutlet weak var leftBottomKnob : UIView?;
    @IBOutlet weak var rightBottomKnob : UIView?;
    @IBOutlet weak var rotationKnob : UIImageView?;
    
    @IBOutlet weak var contentImageView : UIImageView?;
    @IBOutlet weak var borderView : DropBorderView?;
    @IBOutlet weak var rotateGesture : UIRotationGestureRecognizer?;
    @IBOutlet weak var pinchGesture : UIPinchGestureRecognizer?;
    @IBOutlet weak var tapGesture : UITapGestureRecognizer?;
    
    @IBOutlet weak var angleIndicatorView  : FTLineDashView?;
    @IBOutlet weak var angleInfoView  : FTStyledLabel?;
    @IBOutlet weak var angleInfoHolderView : UIView?;
    
    fileprivate var minSizeToMaintain : CGFloat
    {
        if(photoMode == .transform) {
            return 10;
        }
        return MIN_IMAGE_VIEW_HEIGHT;
    }
    
    private var activeControlPoint : RKControlPoint = RKControlPoint.controlPointNone;
    private var currentFrame : CGRect = CGRect.zero;
    private var startPoint : CGPoint = CGPoint.zero;
    private var isMoving  = false;
    private var isRotating  = false;
    private var isScaling  = false;
    public var sourceImage: UIImage = UIImage()
    
    var lastPrevPointInRotation : CGPoint = CGPoint.zero;
    var rotationTransform : CGAffineTransform = CGAffineTransform.identity;
    var allowsResizing = true {
        didSet{
            self.pinchGesture?.isEnabled = self.allowsResizing;
        }
    }
    var photoMode: FTPhotoMode = .normal
    var allowsEditing = false {
        didSet {
            self.rotateGesture?.isEnabled = self.allowsEditing;
            self.tapGesture?.isEnabled = self.allowsEditing;
            self.contentImageView?.image = self.sourceImage;
            self.setupMenuItems();
            self.showControlPoints(animate: true)
            _ = self.becomeFirstResponder()
        }
    };
    
    required init(withImage image : UIImage) {
        super.init(nibName: FTImageResizeViewController.className, bundle: nil);
        self.sourceImage = image
        self.contentImageView?.image = image
        self.view.isMultipleTouchEnabled = true
        self.view.layer.zPosition = 1
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.allowsResizing = true
        
        let doubleTapGesture1: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapGestureRecognized(_:)))
        doubleTapGesture1.numberOfTapsRequired = 2
        doubleTapGesture1.cancelsTouchesInView = false
        self.view.addGestureRecognizer(doubleTapGesture1)
//        _ = self.becomeFirstResponder()
//        self.setupMenuItems();
        
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateAngleInfoClose), object: nil);
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad();
        self.view.clipsToBounds = false
        self.leftTopKnob?.tag = RKControlPoint.controlPointTopLeft.rawValue;
        self.rightTopKnob?.tag = RKControlPoint.controlPointTopRight.rawValue;
        self.leftBottomKnob?.tag = RKControlPoint.controlPointBottomLeft.rawValue;
        self.rightBottomKnob?.tag = RKControlPoint.controlPointBottomRight.rawValue;
        self.rotationKnob?.tag = RKControlPoint.controlPointSmoothRotate.rawValue;
        
        self.contentImageView?.layer.allowsEdgeAntialiasing = true;
        
        if(!self.allowsResizing) {
            self.hideControlPoints(animate: false);
        }
        self.angleIndicatorView?.isHidden = true;
        
        self.angleInfoHolderView?.layer.shadowColor = UIColor.black.cgColor;
        self.angleInfoHolderView?.layer.shadowRadius = 5;
        self.angleInfoHolderView?.layer.shadowOpacity = 0.12;
        self.angleInfoHolderView?.layer.shadowOffset = CGSize(width: 0.0, height: 2.0);
        if let angleview = self.angleInfoView {
            angleview.layer.cornerRadius = angleview.bounds.height*0.5;
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.angleInfoHolderView?.transform = self.view.transform.inverted();
        if let angleview = self.angleInfoView {
            angleview.layer.cornerRadius = angleview.bounds.height*0.5;
        }
    }
    
    override public var canBecomeFirstResponder: Bool {
        return true;
    }
    
    override public func becomeFirstResponder() -> Bool {
        let responder = super.becomeFirstResponder();
        self.view.becomeFirstResponder();
        return responder;
    }
    
    func displayEditImageView(_ image: UIImage?) {
        //overriding it in subclass(FTImageAnnotationViewController)
    }
    
    // MARK: - Gesture
    
    func doubleTapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        //overriding it in subclass(FTImageAnnotationViewController)
    }
    
    public func showMenu(_ show: Bool) {
        _ = self.becomeFirstResponder()
        let theMenu = UIMenuController.shared
        if show {
            theMenu.update()
            if let superview = self.view.superview {
                theMenu.setTargetRect(self.view.frame.insetBy(dx: 0, dy: 0), in: superview)
            }
            theMenu.setMenuVisible(true, animated: true)
        } else {
            theMenu.setMenuVisible(false, animated: true)
        }
    }
    
    private func setupMenuItems() {
        let theMenu = UIMenuController.shared
        let editMenuItem = UIMenuItem(title: NSLocalizedString("Edit", comment: "Edit"), action: #selector(editMenuAction(_:)))
        
        let deleteMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(deleteMenuAction(_:)))
        theMenu.menuItems = [deleteMenuItem, editMenuItem]
    }
    
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        var returnvalue = false
        if action == #selector(self.deleteMenuAction(_:)) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        } else if action == #selector(self.editMenuAction(_:)) {
            if self.allowsEditing {
                returnvalue = true
            }
        }
        return returnvalue
    }
    
    //MARK: - Menu Action
    
    @objc private func editMenuAction(_ sender: Any?) {
        FTCLSLog("Image Edit Enter (menu): \(NSCoder.string(for: sourceImage.size))")
        displayEditImageView(sourceImage)
    }
    
    @objc private func deleteMenuAction(_ sender: Any?) {
        FTCLSLog("Image Delete (menu)")
        deleteAnnotation()
    }
    
    public func deleteAnnotation() {
        // overriding this in FTImageAnnotationViewController
    }
    
    private func hideControlPoints(animate : Bool)
    {
        if(animate) {
            UIView.beginAnimations(nil, context: nil);
            self.hideControlPoints(animate: false);
            UIView.commitAnimations();
        }
        else {
            self.leftTopKnob?.isHidden = true;
            self.rightTopKnob?.isHidden = true;
            self.rightBottomKnob?.isHidden = true;
            self.leftBottomKnob?.isHidden = true;
            
            self.rotationKnob?.isHidden = true;
            if(self.allowsResizing) {
                self.borderView?.isHidden = true;
            }
        }
    }
    
   func showControlPoints(animate : Bool)
    {
        if(!self.allowsResizing) {
            self.hideControlPoints(animate: false);
            return;
        }
        if(animate) {
            UIView.beginAnimations(nil, context: nil);
            self.showControlPoints(animate: false);
            UIView.commitAnimations();
        }
        else {
            self.leftTopKnob?.isHidden = false;
            self.rightTopKnob?.isHidden = false;
            self.rightBottomKnob?.isHidden = false;
            self.leftBottomKnob?.isHidden = false;
            self.borderView?.isHidden = false;
            self.rotationKnob?.isHidden = !self.allowsEditing;
        }
    }
}

//MARK: - Touch delegates
extension FTImageResizeViewController {
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touchesCount = touches.count;
        if let touchEvent = event {
            let localTouches = touchEvent.allTouches;
            touchesCount = (localTouches != nil) ? localTouches!.count : touchesCount;
        }
        
        if(touchesCount > 1 || self.isScaling || self.isRotating) {
            super.touchesBegan(touches, with: event);
            return;
        }
        let currentTouch = touches.first;
        
        self.isMoving = false;
        
        let currentPoint = currentTouch!.location(in: self.view);
        let hitTestView = self.view.hitTest(currentPoint, with: event);
        if let hitView = hitTestView, hitView.tag > 0 {
            if(hitView == self.rotationKnob!) {
                self.activeControlPoint = RKControlPoint.init(rawValue: hitView.tag)!;
                self.lastPrevPointInRotation = currentTouch!.location(in: self.view.superview);
            }
            else {
                self.activeControlPoint = self.activeKnobAtTouch(currentTouch!);
            }
            self.currentFrame = self.contentFrame();
            self.startPoint = currentTouch!.location(in: self.view.superview);
        }
        else {
            self.activeControlPoint = RKControlPoint.controlPointNone;
            if(self.isPointInside(currentPoint)) {
                self.isMoving = true;
            }
        }
        self.hideControlPoints(animate: true)
        self.showMenu(false)
        super.touchesBegan(touches, with: event);
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        var touchesCount = touches.count;
        if let touchEvent = event {
            let localTouches = touchEvent.allTouches;
            touchesCount = (localTouches != nil) ? localTouches!.count : touchesCount;
        }
        if(touchesCount > 1 || self.isScaling || self.isRotating) {
            return;
        }
        
        let touch = touches.first!;
        let prevPoint = touch.previousLocation(in: self.view.superview);
        let curPoint = touch.location(in: self.view.superview);
        
        if(self.activeControlPoint != .controlPointNone) {
            if(self.activeControlPoint == RKControlPoint.controlPointSmoothRotate) {
                let prevPoint1 = CGPoint.init(x: self.view.frame.midX, y: self.view.frame.midY);
                let curPoint1 = CGPoint.init(x: self.view.frame.midX, y: self.view.frame.midY);
                
                let prevAngle = prevPoint1.angle(self.lastPrevPointInRotation);
                let curAngle = curPoint1.angle(curPoint);
                
                let angleDifference = curAngle - prevAngle;
                
                if(abs(angleDifference*RADIANS_TO_DEGREE) > 5.0) {
                    self.tapGesture?.isEnabled = false;
                }
                
                if(isAngleNearToSnapArea(byAddingAngle: angleDifference)) {
                    self.angleIndicatorView?.isHidden = false;
                    if(self.snapToNear90IfNeeded(byAddingAngle: angleDifference)) {
                        self.lastPrevPointInRotation = curPoint;
                    }
                }
                else {
                    self.angleIndicatorView?.isHidden = true;
                    self.setRotationAngle(angleDifference);
                    self.lastPrevPointInRotation = curPoint;
                }
                self.showAngleInfoView(true, animate: true);
            }
            else {
                self.performKnobMovedUsingScalingApproach(touch: touch);
            }
        }
        else if(self.isMoving) {
            
            let offsetY = prevPoint.y - curPoint.y;
            let offsetX = prevPoint.x - curPoint.x;
            
            let frame = self.view.frame;
            var newCenter = CGPoint.init(x: frame.midX - offsetX, y: frame.midY - offsetY);
            newCenter = self.centerWithInBoundary(newCenter);
            self.view.center = newCenter;
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        self.finalizeonTouchEnd();
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event);
        self.finalizeonTouchEnd();
    }
    
    fileprivate func finalizeonTouchEnd()
    {
        self.showAngleInfoView(false, animate: true);
        self.angleIndicatorView?.isHidden = true;
        self.tapGesture?.isEnabled = self.allowsEditing;
        self.showControlPoints(animate: true)
        showMenu(true)
    }
}

extension FTImageResizeViewController
{
    @IBAction func didRotate(_ rotateGesture : UIRotationGestureRecognizer)
    {
        switch rotateGesture.state {
        case .began:
            self.isRotating = true;
            hideControlPoints(animate: true)
            showMenu(false)
        case .changed:
            let angle = rotateGesture.rotation;
            if(self.isAngleNearToSnapArea(byAddingAngle: angle)) {
                self.angleIndicatorView?.isHidden = false;
                if(self.snapToNear90IfNeeded(byAddingAngle: angle)) {
                    rotateGesture.rotation = 0;
                }
            }
            else {
                self.angleIndicatorView?.isHidden = true;
                rotateGesture.rotation = 0;
                self.setRotationAngle(angle);
            }
            self.showAngleInfoView(true, animate: true);
        case .cancelled, .ended:
            self.angleIndicatorView?.isHidden = true;
            self.showAngleInfoView(false, animate: true);
            self.isRotating = false;
            self.showControlPoints(animate: true)
            self.showMenu(true)
        default:
            break;
        }
    }
    
    @IBAction func didScale(_ pinchGesture : UIPinchGestureRecognizer)
    {
        switch pinchGesture.state {
        case .began:
            self.isScaling = true;
            hideControlPoints(animate: true)
            showMenu(false)
        case .changed:
            let scale = pinchGesture.scale;
            pinchGesture.scale = 1;
            self.setScale(scale);
        case .cancelled, .ended:
            self.isScaling = false;
            self.showControlPoints(animate: true)
            self.showMenu(true)
        default:
            break;
        }
    }
    
    @IBAction func didTapOnRotationKnob(_ tapGesture : UITapGestureRecognizer)
    {
        FTCLSLog("Image: Tapped On Rotation knob")
        if(tapGesture.state == .recognized) {
            let nearestAngle = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle());
            let currentAngle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle());
            self.setRotationAngle((nearestAngle-currentAngle)*(DEGREE_TO_RADIANS));
            self.showAngleInfoView(true, animate: true);
        }
    }
    
    fileprivate func setScale(_ scale : CGFloat)
    {
        let center = self.view.center;
        
        var newFrame = self.contentFrame();
        
        var newWidth = newFrame.size.width * scale;
        var newHeight = newFrame.size.height * scale;
        
        let MIN_HEIGHT = self.minSizeToMaintain;
        if(MIN_HEIGHT > 0) {
            if (newWidth < MIN_HEIGHT) {
                let widthRatio = MIN_HEIGHT/newWidth;
                newWidth = MIN_HEIGHT;
                newHeight *= widthRatio;
            }
            
            if (newHeight < MIN_HEIGHT) {
                let heightRatio = MIN_HEIGHT/newHeight;
                newHeight = MIN_HEIGHT;
                newWidth *= heightRatio;
            }
        }
        
        newFrame.size.width = newWidth;
        newFrame.size.height = newHeight;
        if(newFrame.isInfinite) {
            FTLogError("New frame is isInfinite");
        }
        self.updateContentFrame(newFrame);
        
        self.view.center = self.centerWithInBoundary(center); //center
    }
    
    fileprivate func setRotationAngle(_ angleInRadians : CGFloat)
    {
        self.view.transform = self.view.transform.rotated(by: angleInRadians);
        
        FTCLSLog("Image: Angle Changed to \(angleInRadians)")
    }
}

//MARK:- Angle Related -
private extension FTImageResizeViewController
{
    func snapToNear90IfNeeded(byAddingAngle angleInRadians: CGFloat) -> Bool
    {
        let angle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle());
        let angleToConsider = self.angleWRT360Degree(angleInRadians: self.currentViewAngle()+angleInRadians);
        
        let previous90 = self.nearestPrevSnapAngle(angleInRadians: self.currentViewAngle());
        let next90 = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle());
        
        if(abs(angleToConsider - previous90) <= THRESHOLD_ANGLE) {
            let nearestAngle = previous90 - angle;
            if(abs(nearestAngle) > 0.01)  {
                self.setRotationAngle(nearestAngle*DEGREE_TO_RADIANS);
                return true;
            }
        }
        else if(abs(next90 - angleToConsider) <= THRESHOLD_ANGLE) {
            let nearestAngle = next90 - angle;
            if(abs(nearestAngle) > 0.01)  {
                self.setRotationAngle(nearestAngle*DEGREE_TO_RADIANS);
                return true;
            }
        }
        return false;
    }
    
    func currentViewAngle() -> CGFloat
    {
        return CGAffineTransformGetRotation(self.view.transform);
    }
    
    func isAngleNearToSnapArea(byAddingAngle angleInRadians: CGFloat) -> Bool
    {
        let angle = self.angleWRT360Degree(angleInRadians: self.currentViewAngle()+angleInRadians);
        let previous90 = self.nearestPrevSnapAngle(angleInRadians: self.currentViewAngle()+angleInRadians);
        let next90 = self.nearestNextSnapAngle(angleInRadians: self.currentViewAngle()+angleInRadians);
        
        if(abs(angle - previous90) <= THRESHOLD_ANGLE) {
            return true;
        }
        else if(abs(next90 - angle) <= THRESHOLD_ANGLE) {
            return true;
        }
        return false;
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
    
    func nearestNextSnapAngle(angleInRadians : CGFloat) -> CGFloat
    {
        let angle = self.angleWRT360Degree(angleInRadians: angleInRadians);
        let angleQuotent = Int(angle/ANGLE_JUMP);
        let newAngle = CGFloat(angleQuotent)*ANGLE_JUMP+ANGLE_JUMP;
        return newAngle;
    }
    
    func nearestPrevSnapAngle(angleInRadians : CGFloat) -> CGFloat
    {
        let angle = self.angleWRT360Degree(angleInRadians: angleInRadians);
        let angleQuotent = Int(angle/ANGLE_JUMP);
        let previous90 = CGFloat(angleQuotent)*ANGLE_JUMP;
        return previous90;
    }
    
    func showAngleInfoView(_ show : Bool,animate : Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.animateAngleInfoClose), object: nil);
        if(show) {
            let angle = Int(self.angleWRT360Degree(angleInRadians: self.currentViewAngle()));
            self.angleInfoView?.styleText = "\(angle)º";
            if(animate) {
                if(self.angleInfoHolderView!.isHidden) {
                    self.angleInfoHolderView?.isHidden = false;
                    self.angleInfoHolderView?.alpha = 0.0;
                    UIView.animate(withDuration: 0.2,
                                   animations: {
                                    self.angleInfoHolderView?.alpha = 1.0;
                    })
                }
            }
            else {
                self.angleInfoHolderView?.isHidden = false;
            }
        }
        else {
            if(animate) {
                self.perform(#selector(self.animateAngleInfoClose), with: nil, afterDelay: 0.2, inModes: [RunLoop.Mode.default]);
            }
            else {
                self.angleInfoHolderView?.isHidden = true;
            }
        }
        
    }
    
    @objc func animateAngleInfoClose()
    {
        UIView.animate(withDuration: 0.2,
                       animations: {
                        self.angleInfoHolderView?.alpha = 0.0;
        }) { (_) in
            self.angleInfoHolderView?.isHidden = true;
        }
    }
}

//MARK:- Boundary Conditions -
private extension FTImageResizeViewController
{
    func pointWithInBoundary(_ point : CGPoint) -> CGPoint
    {
        var newPoint = point;
        let boundaryRect = self.view.superview!.bounds;
        
        let halfKnobSize : CGFloat = 20;
        if(newPoint.x < (boundaryRect.minX+halfKnobSize)) {
            newPoint.x = boundaryRect.minX+halfKnobSize;
        }
        
        if(newPoint.x > (boundaryRect.maxX-halfKnobSize)) {
            newPoint.x = boundaryRect.maxX-halfKnobSize;
        }
        
        if(newPoint.y < (boundaryRect.minY+halfKnobSize)) {
            newPoint.y = boundaryRect.minY+halfKnobSize;
        }
        
        if(newPoint.y > (boundaryRect.maxY-halfKnobSize)) {
            newPoint.y = boundaryRect.maxY-halfKnobSize;
        }
        return newPoint;
    }
    
    func centerWithInBoundary(_ center : CGPoint) -> CGPoint
    {
        let superViewBounds = self.view.superview!.bounds;
        let currentFrame = self.view.frame;
        
        var frame = CGRect.init(x: center.x - currentFrame.width*0.5,
                                y: center.y - currentFrame.height*0.5,
                                width: currentFrame.width,
                                height: currentFrame.height);
        let knobSize : CGFloat = 60;
        if(frame.origin.x > superViewBounds.width - knobSize) {
            frame.origin.x = superViewBounds.width - knobSize;
        }
        if(frame.maxX < knobSize) {
            frame.origin.x = knobSize - frame.width;
        }
        if(frame.maxY < knobSize) {
            frame.origin.y = knobSize - frame.height;
        }
        if(frame.origin.y > superViewBounds.height - knobSize) {
            frame.origin.y = superViewBounds.height - knobSize;
        }
        return CGPoint.init(x: frame.midX, y: frame.midY);
    }
}

extension FTImageResizeViewController
{
    
    public func contentFrame() -> CGRect
    {
        let transform = self.view.transform;
        self.view.transform = CGAffineTransform.identity;
        var frame = self.view.frame;
        frame = frame.insetBy(dx: 20, dy: 20);
        self.view.transform = transform;
        return frame;
    }
    
    func updateContentFrame(_ frame : CGRect)
    {
        if !(frame.isInfinite) {
            let transform = self.view.transform;
            self.view.transform = CGAffineTransform.identity;
            var frameToSet = frame;
            frameToSet = frameToSet.insetBy(dx: -20, dy: -20);
            if(frameToSet.isInfinite) {
                FTLogError("frameToSet is isInfinite");
            }
            self.view.frame = frameToSet;
            self.view.transform = transform;
        } else {
            FTLogError("frameToSet is isInfinite");
        }
    }
    
    fileprivate func angleBetweenPoint(_ point1 : CGPoint, andPoint point2 : CGPoint) -> CGFloat
    {
        let deltaY = point1.y - point2.y;
        let deltaX = point1.x - point2.x;
        
        let angle = atan2(deltaY, deltaX);
        
        return angle;
    }
    
    func isPointInside(_ point : CGPoint) -> Bool
    {
        if(self.allowsResizing) {
            let bezierPath = UIBezierPath.init();
            bezierPath.move(to: CGPoint.init(x: self.leftTopKnob!.frame.minX,
                                             y: self.leftTopKnob!.frame.minY));
            bezierPath.addLine(to: CGPoint.init(x: self.leftBottomKnob!.frame.minX,
                                                y: self.leftBottomKnob!.frame.maxY));
            bezierPath.addLine(to: CGPoint.init(x: self.rightBottomKnob!.frame.maxX,
                                                y: self.rightBottomKnob!.frame.maxY));
            bezierPath.addLine(to: CGPoint.init(x: self.rightTopKnob!.frame.maxX,
                                                y: self.rightTopKnob!.frame.minY));
            bezierPath.close();
            return bezierPath.contains(point)
        }
        else {
            return self.contentImageView!.frame.contains(point);
        }
    }
}

private extension FTImageResizeViewController
{
    func activeKnobAtTouch(_ touch : UITouch) -> RKControlPoint
    {
        var controlPoint = RKControlPoint.controlPointNone;
        
        let currentPointWrtView = touch.location(in: self.view.superview);
        let center = self.view.center;
        
        if(center.x > currentPointWrtView.x && center.y > currentPointWrtView.y) {
            controlPoint = RKControlPoint.controlPointTopLeft;
        }
        else if(center.x > currentPointWrtView.x && center.y < currentPointWrtView.y) {
            controlPoint = RKControlPoint.controlPointBottomLeft;
        }
        if(center.x < currentPointWrtView.x && center.y > currentPointWrtView.y) {
            controlPoint = RKControlPoint.controlPointTopRight;
        }
        if(center.x < currentPointWrtView.x && center.y < currentPointWrtView.y) {
            controlPoint = RKControlPoint.controlPointBottomRight;
        }
        return controlPoint;
    }
    
    func performKnobMovedUsingScalingApproach(touch : UITouch)
    {
        var curPoint2 = touch.location(in: self.view.superview);
        var prevPoint = touch.previousLocation(in: self.view.superview);
        
        curPoint2 = self.pointWithInBoundary(curPoint2);
        prevPoint = self.pointWithInBoundary(prevPoint);
        
        let frame = self.currentFrame;
        
        let xOffset = curPoint2.x - self.startPoint.x;
        let yOffset = curPoint2.y - self.startPoint.y;
        
        var newWidth : CGFloat = frame.width;
        var newHeight : CGFloat = frame.height;
        
        var useMinScale = false;
        
        if(self.activeControlPoint == .controlPointBottomRight) {
            newWidth = frame.size.width  + xOffset;
            newHeight = frame.size.height + yOffset;
        }
        else  if(self.activeControlPoint == .controlPointTopRight) {
            newWidth = frame.size.width  + xOffset;
            newHeight = frame.size.height - yOffset;
        }
        else if(self.activeControlPoint == .controlPointTopLeft){
            newWidth = frame.size.width  - xOffset;
            newHeight = frame.size.height - yOffset;
        }
        else if(self.activeControlPoint == .controlPointBottomLeft){
            newWidth = frame.size.width  - xOffset;
            newHeight = frame.size.height + yOffset;
        }
        
        if(frame.isInfinite) {
            FTLogError("frame is infinite");
        }
        
        let MIN_HEIGHT = self.minSizeToMaintain;
        if(MIN_HEIGHT > 0) {
            if (newWidth < MIN_HEIGHT) {
                let widthRatio = MIN_HEIGHT/frame.width;
                newWidth = MIN_HEIGHT;
                newHeight *= widthRatio;
            }
            
            if (newHeight < MIN_HEIGHT) {
                let heightRatio = MIN_HEIGHT/frame.height;
                newHeight = MIN_HEIGHT;
                newWidth *= heightRatio;
            }
        }
        
        if(newWidth < self.currentFrame.width || newHeight < self.currentFrame.height) {
            useMinScale = true;
        }
        
        let currentFrameSize = self.contentFrame();
        if(currentFrameSize.isInfinite) {
            FTLogError("currentFrameSize is infinite");
        }
        
        let sizeFactorX = newWidth/currentFrameSize.size.width;
        let sizeFactorY = newHeight/currentFrameSize.size.height;
        #if DEBUG
        debugPrint("touches moved: : newWidth - \(newWidth) newHeight \(newHeight)")
        #endif
        var actualScaleFactor = (sizeFactorX > sizeFactorY) ? sizeFactorX : sizeFactorY;
        if(useMinScale) {
            actualScaleFactor = (sizeFactorX < sizeFactorY) ? sizeFactorX : sizeFactorY;
        }
        #if DEBUG
        debugPrint("touches moved: : sizeFactorX - \(sizeFactorX) sizeFactorY \(sizeFactorY) actualScaleFactor:\(actualScaleFactor)")
        #endif
        self.setScale(actualScaleFactor);
    }
}

private extension CGPoint
{
    func angle(_ point1 : CGPoint) -> CGFloat
    {
        let deltaY = self.y - point1.y;
        let deltaX = self.x - point1.x;
        
        let angle = atan2(deltaY, deltaX);
        
        return angle;
    }
}

//MARK: - FTImageResizeProtocol {
extension FTImageResizeViewController : FTImageResizeProtocol {
    
    func finalFrame() -> CGRect {
        return self.contentFrame()
    }
    
}


//MARK: - UIImage helpers
@objc extension UIImage {
    
    func aspectFrame(withinScreenArea screenArea: CGRect, zoomScale scale: CGFloat) -> CGRect {
        let imageSize = CGSize(width: size.width / UIScreen.main.scale, height: size.height / UIScreen.main.scale)
        
        var sourceImageSz: CGSize = CGSizeScale(imageSize, scale)
        
        let targetSize: CGSize = screenArea.insetBy(dx: CONTROL_POINT_SIZE * 0.5, dy: CONTROL_POINT_SIZE * 0.5).size
        let ratio = aspectFittedRatio(sourceImageSz, targetSize)
        
        sourceImageSz = CGSizeScale(sourceImageSz, ratio)
        
        let startingFrame = CGRect(x: (screenArea.size.width - sourceImageSz.width) * 0.5, y: (screenArea.size.height - sourceImageSz.height) * 0.5, width: sourceImageSz.width, height: sourceImageSz.height)
        
        return startingFrame
    }
    
    func frame(inRect : CGRect,
               capToMinIfNeeded : Bool,
               contentScale : CGFloat) -> CGRect {
        
        let minSizeCap = CGSize(width: MIN_IMAGE_VIEW_HEIGHT, height: MIN_IMAGE_VIEW_HEIGHT)
        var finalFrame : CGRect = self.aspectFrame(withinScreenArea: inRect , zoomScale: contentScale)
        
        //This is to maintain Minimum size for the added image which matches the minimum size while resizing.
        var newWidth = finalFrame.size.width
        var newHeight = finalFrame.size.height
        
        if newWidth < minSizeCap.width {
            FTCLSLog("Image: width less than min width")
            let widthRatio: CGFloat = minSizeCap.width / finalFrame.size.width
            newWidth = minSizeCap.width
            newHeight *= widthRatio
        }
        
        if newHeight < minSizeCap.height {
            FTCLSLog("Image: height less than min height")
            let heightRatio: CGFloat = minSizeCap.height / finalFrame.size.height
            newHeight = minSizeCap.height
            newWidth *= heightRatio
        }
        
        let sizeFactorX: CGFloat = newWidth / finalFrame.size.width
        let sizeFactorY: CGFloat = newHeight / finalFrame.size.height
        let finalSize: CGSize = CGSizeScale(finalFrame.size, min(sizeFactorX, sizeFactorY))
        finalFrame = CGRect(x: finalFrame.origin.x, y: finalFrame.origin.y, width: finalSize.width, height: finalSize.height)
        
        return finalFrame;
    }
    
    func resizeImage(to newSize: CGSize, transform: CGAffineTransform, clippingRect clipRect: CGRect) -> UIImage? {
        let rect1 = CGRect(x: 0, y: 0, width: clipRect.size.width, height: clipRect.size.height)
        let rect = rect1.integral
        
        let scaledImageSize = CGSize(width: size.width, height: size.height)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(rect.size, _: false, _: 0.0)
        //        CGContextSetInterpolationQuality(context, CGInterpolationQuality.low)
        
        // Transform the image (as the image view has been transformed)
        context.translateBy(x: newSize.width * 0.5 - clipRect.origin.x, y: newSize.height * 0.5 - clipRect.origin.y)
        context.concatenate(transform)
        context.translateBy(x: -scaledImageSize.width * 0.5, y: -scaledImageSize.height * 0.5)
        
        context.translateBy(x: 0.0, y: scaledImageSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw view into context
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))
        // Create the new UIImage from the context
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the drawing
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func scaleAndRotateImageFor1x() -> UIImage? {
        let maxRect: CGRect = UIScreen.main.bounds
        let kMaxResolution = max(1500, max(maxRect.size.width, maxRect.size.height)) // Or whatever
        
        guard let imgRef = cgImage else {
            return self
        }
        
        let width =  imgRef.width
        let height = imgRef.height
        
        var transform: CGAffineTransform = .identity
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > Int(kMaxResolution) || height > Int(kMaxResolution) {
            let ratio: CGFloat = CGFloat(width) / CGFloat(height)
            if ratio > 1 {
                bounds.size.width = kMaxResolution
                bounds.size.height = bounds.size.width / ratio
            } else {
                bounds.size.height = kMaxResolution
                bounds.size.width = bounds.size.height * ratio
            }
        }
        
        let scaleRatio: CGFloat = bounds.size.width / CGFloat(width)
        let imageSize = CGSize(width: imgRef.width, height: imgRef.height)
        let boundHeight: CGFloat
        let orient: UIImage.Orientation = imageOrientation
        switch orient {
        case UIImage.Orientation.up /*EXIF = 1 */:
            transform = CGAffineTransform.identity
        case UIImage.Orientation.upMirrored /*EXIF = 2 */:
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case UIImage.Orientation.down /*EXIF = 3 */:
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: .pi)
        case UIImage.Orientation.downMirrored /*EXIF = 4 */:
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case UIImage.Orientation.leftMirrored /*EXIF = 5 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case UIImage.Orientation.left /*EXIF = 6 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
            transform = transform.rotated(by: 3.0 * .pi / 2.0)
        case UIImage.Orientation.rightMirrored /*EXIF = 7 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: .pi / 2.0)
        case UIImage.Orientation.right /*EXIF = 8 */:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: .pi / 2.0)
        default:
            NSException(name:NSExceptionName.internalInconsistencyException, reason:"Invalid image orientation", userInfo:nil).raise()
            break
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, _: false, _: 1.0)
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = CGInterpolationQuality.high;
        
        if orient == .right || orient == .left {
            context?.scaleBy(x: -scaleRatio, y: scaleRatio)
            context?.translateBy(x: CGFloat(-height), y: 0)
        } else if orient == .rightMirrored || orient == .leftMirrored {
            context?.scaleBy(x: scaleRatio, y: -scaleRatio)
            
            context?.translateBy(x: 0, y: CGFloat(-width))
        } else {
            context?.scaleBy(x: scaleRatio, y: -scaleRatio)
            context?.translateBy(x: 0, y: CGFloat(-height))
        }
        context?.concatenate(transform)
        
        context?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageCopy
    }
    
    func scaleDownToHalf() -> UIImage? {
        let scaledImageSize = CGSize(width: size.width * 0.5, height: size.height * 0.5)
        
        UIGraphicsBeginImageContextWithOptions(scaledImageSize, _: false, _: 1.0)
        //        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), CGInterpolationQuality.high)
        
        draw(in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))
        
        let imageCopy: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageCopy
    }
}

