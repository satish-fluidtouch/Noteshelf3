//
//  FTImageResizeViewController.swift
//  Noteshelf
//
//  Created by Matra on 06/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTPhotoMode {
    case normal
    case transform
    case clipBoard
}

private let MIN_IMAGE_VIEW_HEIGHT : CGFloat = 30;
private let MIN_IMAGE_VIEW_WIDTH : CGFloat = 30;

private let CONTROL_POINT_SIZE : CGFloat = 40

public let RADIANS_TO_DEGREE : CGFloat = 180.0/CGFloat.pi;
public let DEGREE_TO_RADIANS : CGFloat = CGFloat.pi/180.0;
let THRESHOLD_ANGLE : CGFloat = 0
let ANGLE_JUMP : CGFloat = 90

class FTLineDashView : UIView
{
    private weak var drawLineLayer : CAShapeLayer?;
    
    private var shapeLayer : CAShapeLayer {
        if(nil == drawLineLayer) {
            let shapelayer = CAShapeLayer.init();
            self.layer.addSublayer(shapelayer);
            self.drawLineLayer = shapelayer;
            self.drawLineLayer?.masksToBounds=true
            self.drawLineLayer?.strokeColor = UIColor(hexString: "#EE0C6B").cgColor
//            self.drawLineLayer?.lineDashPattern = [4, 4]
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

 enum FTControlPoint: Int {
    case none = 0
    case topLeft
    case topMid
    case topRight
    case leftSideMid
    case rightSideMid
    case bottomLeft
    case bottomMid
    case bottomRight
    case smoothRotate
    case snapRotate
     
     func canScaleProportinally() -> Bool {
         var scaleProportinally = true
         switch self {
         case .bottomMid, .topMid, .leftSideMid, .rightSideMid:
             scaleProportinally = false
         default:
             scaleProportinally = true
         }
         return scaleProportinally
     }
}

@objcMembers public class FTImageResizeViewController: UIViewController {
    
    @IBOutlet weak var leftTopKnob : UIView?;
    @IBOutlet weak var rightTopKnob : UIView?;
    @IBOutlet weak var leftBottomKnob : UIView?;
    @IBOutlet weak var rightBottomKnob : UIView?;
    @IBOutlet weak var rotationKnob : UIImageView?;
    @IBOutlet weak var deleteButton : UIButton?;
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var leftSideMidKnob: UIView?
    @IBOutlet weak var rightSideMidKnob: UIView?
    @IBOutlet weak var topMidKnob: UIView?
    @IBOutlet weak var bottomMidKnob: UIView?
    @IBOutlet var menuTapGesture: UITapGestureRecognizer!
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
    
    private var activeControlPoint : FTControlPoint = .none;
    private var currentFrame : CGRect = CGRect.zero;
    private var startPoint : CGPoint = CGPoint.zero;
    private var isMoving  = false;
    private var isRotating  = false;
    private var isScaling  = false;
    public var sourceImage: UIImage = UIImage()
    var doubleTapGesture : UITapGestureRecognizer?;
    
    var lastPrevPointInRotation : CGPoint = CGPoint.zero;
    var allowsResizing = true {
        didSet{
            self.pinchGesture?.isEnabled = self.allowsResizing;
        }
    }
    var photoMode: FTPhotoMode = .normal {
        didSet {
            showControlPoints(animate: true)
            borderView?.photoMode = photoMode
        }
    }
    ///In future, it'll be better to separate rotation from `allowsEditing` to avoid confusion.
    var allowsEditing = true {
        didSet {
            self.rotateGesture?.isEnabled = self.allowsEditing;
            self.tapGesture?.isEnabled = self.allowsEditing;
            self.doubleTapGesture?.isEnabled = self.allowsEditing
            self.contentImageView?.image = self.sourceImage;
            #if !targetEnvironment(macCatalyst)
            self.setupMenuItems();
            #endif
            _ = self.becomeFirstResponder()
        }
    };

    var allowsLocking = false
    
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
        self.doubleTapGesture = doubleTapGesture1
        
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
        self.leftTopKnob?.tag = FTControlPoint.topLeft.rawValue;
        self.rightTopKnob?.tag = FTControlPoint.topRight.rawValue;
        self.leftBottomKnob?.tag = FTControlPoint.bottomLeft.rawValue;
        self.rightBottomKnob?.tag = FTControlPoint.bottomRight.rawValue;
        self.topMidKnob?.tag = FTControlPoint.topMid.rawValue;
        self.bottomMidKnob?.tag = FTControlPoint.bottomMid.rawValue;
        self.leftSideMidKnob?.tag = FTControlPoint.leftSideMid.rawValue;
        self.rightSideMidKnob?.tag = FTControlPoint.rightSideMid.rawValue;

        self.rotationKnob?.tag = FTControlPoint.smoothRotate.rawValue;
        
        self.contentImageView?.layer.allowsEdgeAntialiasing = true;
        
        if(!self.allowsResizing) {
            self.hideControlPoints(animate: false);
        }
        self.angleIndicatorView?.isHidden = true;
        
        self.angleInfoHolderView?.layer.shadowColor = UIColor.black.cgColor;
        self.angleInfoHolderView?.layer.shadowRadius = 5;
        self.angleInfoHolderView?.layer.shadowOpacity = 0.12;
        self.angleInfoHolderView?.layer.shadowOffset = CGSize(width: 0.0, height: 2.0);
        angleInfoHolderView?.layer.cornerRadius = 10
        if let angleview = self.angleInfoView {
//            angleview.layer.cornerRadius = angleview.bounds.height*0.5;
        }
         leftSideMidKnob?.isHidden = true
         rightSideMidKnob?.isHidden = true
         topMidKnob?.isHidden = true
         bottomMidKnob?.isHidden = true
        angleInfoHolderView?.backgroundColor = UIColor.init(hexString: "#3C3C43")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showControlPoints(animate: true)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        self.angleInfoHolderView?.transform = self.view.transform.inverted();
        if let angleview = self.angleInfoView {
//            angleview.layer.cornerRadius = angleview.bounds.height*0.5;
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
    
    @IBAction func didTapOnImage(tapGesture: UITapGestureRecognizer) {
        if tapGesture.state == .recognized {
            showMenu(true)
        }
    }

    func doubleTapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        //overriding it in subclass(FTImageAnnotationViewController)
    }
    
    public func showMenu(_ show: Bool) {
        #if !targetEnvironment(macCatalyst)
        _ = self.becomeFirstResponder()
        let theMenu = UIMenuController.shared
        if show {
            theMenu.update()
            if let superview = self.view.superview {
                let rect = self.view.frame.insetBy(dx: 0, dy: 30)
                theMenu.showMenu(from: superview, rect: rect)
            }
        } else {
            theMenu.hideMenu()
        }
        #endif
    }

        #if !targetEnvironment(macCatalyst)
        private func setupMenuItems() {
        let theMenu = UIMenuController.shared
        let editMenuItem = UIMenuItem(title: NSLocalizedString("Edit", comment: "Edit"), action: #selector(editMenuAction(_:)))
        let editClip = UIMenuItem(title: NSLocalizedString("EditClip", comment: "Edit Clip"), action: #selector(editClipAnnotation(_:)));
        let cutMenuItem = UIMenuItem(title: NSLocalizedString("Cut", comment: "Cut"), action: #selector(cutMenuAction(_:)))
        let copyMenuItem = UIMenuItem(title: NSLocalizedString("Copy", comment: "Copy"), action: #selector(copyMenuAction(_:)))
        let deleteMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(deleteMenuAction(_:)))
        let lockMenuItem = UIMenuItem(title: NSLocalizedString("Lock", comment: "Lock"), action: #selector(lockMenuAction(_:)))
        let moveToFrontItem = UIMenuItem(title: NSLocalizedString("BringToFront", comment: "BringToFront"), action: #selector(self.moveToFrontAction(_:)));
        let moveToBackItem = UIMenuItem(title: NSLocalizedString("SendToBack", comment: "SendToBack"), action: #selector(self.moveToBackAction(_:)));
        theMenu.menuItems = [editMenuItem,
                             editClip,
                             cutMenuItem,
                             copyMenuItem,
                             deleteMenuItem,
                             lockMenuItem,
                             moveToFrontItem,
                             moveToBackItem]
    }
    
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let returnvalue : Bool
        if action == #selector(self.deleteMenuAction(_:)) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        } else if action == #selector(self.editMenuAction(_:)) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = self.allowsEditing
            }
        } else if action == #selector(self.cutMenuAction(_:)){
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        }
        else if action == #selector(self.lockMenuAction(_:)) {
            returnvalue = self.allowsLocking
        } else if action == #selector(self.copyMenuAction(_:)) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        } else if(action == #selector(self.moveToFrontAction(_:))) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        } else if(action == #selector(self.moveToBackAction(_:))) {
            if photoMode == .transform {
                returnvalue = false
            } else {
                returnvalue = true
            }
        } else {
            returnvalue = false
        }
        return returnvalue
    }
    #endif

    //MARK: - Menu Action
    
    @objc private func cutMenuAction(_ sender: Any?){
        cutAnnotation()
    }
    @objc func editMenuAction(_ sender: Any?) {
        FTCLSLog("Image Edit Enter (menu): \(NSCoder.string(for: sourceImage.size))")
        displayEditImageView(sourceImage)
        track("Media_Edit", params: [:], screenName: FTScreenNames.media)
    }
    
    @objc private func deleteMenuAction(_ sender: Any?) {
        FTCLSLog("Image Delete (menu)")
        deleteAnnotation()
         track("Media_Delete", params: [:], screenName: FTScreenNames.media)
    }
    
    @objc private func copyMenuAction(_ sender: Any?) {
        FTCLSLog("Image Copy (menu)")
        copyAnnotation()
    }

    @objc private func lockMenuAction(_ sender: Any?) {
        FTCLSLog("Image Lock (menu)")
        lockAnnotation()
        track("Media_Lock", params: [:], screenName: FTScreenNames.media)
    }
    
    @objc private func moveToFrontAction(_ sender: Any?) {
        FTCLSLog("Image move to front (menu)")
        moveAnnotationToFront()
         track("Media_BringToFront", params: [:], screenName: FTScreenNames.media)
    }

    @objc private func moveToBackAction(_ sender: Any?) {
        FTCLSLog("Image move to back (menu)")
        moveAnnotationToBack()
         track("Media_BringToBack", params: [:], screenName: FTScreenNames.media)
    }
    
    @objc func editClipAnnotation(_ sender: Any?) {
        FTCLSLog("Edit Clip")
        editWebClip()
    }
    
    
    public func editWebClip() {
        // overriding this in FTImageAnnotationViewController
    }
    public func cutAnnotation() {
        // overriding this in FTImageAnnotationViewController
    }

    public func deleteAnnotation() {
        if photoMode == .transform, let lassoController = self.parent as? FTLassoContentSelectionViewController {
            lassoController.deleteAnnotation()
        }
        // overriding this in FTImageAnnotationViewController
    }

    public func lockAnnotation() {
        // overriding this in FTImageAnnotationViewController
    }
    
    public func copyAnnotation() {
        // overriding this in FTImageAnnotationViewController
    }
    
    public func moveAnnotationToFront() {
        // overriding this in FTImageAnnotationViewController
    }
    
    public func moveAnnotationToBack() {
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
            self.topMidKnob?.isHidden = true;
            self.bottomMidKnob?.isHidden = true;
            self.leftSideMidKnob?.isHidden = true;
            self.rightSideMidKnob?.isHidden = true;
            self.stackView.isHidden = true;
//            self.rotationKnob?.isHidden = true;
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
            self.stackView.isHidden = false;
            let hideSideKnobs = (photoMode == .transform)
            self.topMidKnob?.isHidden = hideSideKnobs;
            self.bottomMidKnob?.isHidden = hideSideKnobs;
            self.leftSideMidKnob?.isHidden = hideSideKnobs;
            self.rightSideMidKnob?.isHidden = hideSideKnobs;
            self.borderView?.isHidden = false;
        }
    }
}

//MARK: - Touch delegates
extension FTImageResizeViewController {
    func setAnchorPoint() {
        var anchorPoint = CGPoint(x: 1, y: 1)
        switch activeControlPoint {
        case .topLeft, .topMid, .leftSideMid:
            anchorPoint = CGPoint(x: 1, y: 1)
        case .topRight:
            anchorPoint = CGPoint(x: 0, y: 1)
        case .bottomLeft:
            anchorPoint = CGPoint(x: 1, y: 0)
        case .bottomRight, .bottomMid, .rightSideMid:
            anchorPoint = CGPoint.zero
        default:
            anchorPoint = CGPoint(x: 1, y: 1)
        }
        self.view.setAnchorPoint(anchorPoint: anchorPoint)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touchesCount = touches.count;
        if let touchEvent = event {
            let localTouches = touchEvent.allTouches;
            touchesCount = (localTouches != nil) ? localTouches!.count : touchesCount;
        }
        track("Media_LongPressRotate", params: [:], screenName: FTScreenNames.media)
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
                self.activeControlPoint = FTControlPoint.init(rawValue: hitView.tag)!;
                self.lastPrevPointInRotation = currentTouch!.location(in: self.view.superview);
            }
            else {
                if photoMode == .normal {
                    self.activeControlPoint = FTControlPoint.init(rawValue: hitView.tag)!;
                    if(hitView != self.rotationKnob! && !self.activeControlPoint.canScaleProportinally()) {
                        setAnchorPoint()
                    } else {
                        self.activeControlPoint = self.activeKnobAtTouch(currentTouch!);
                    }
                } else {
                    self.activeControlPoint = self.activeKnobAtTouch(currentTouch!);
                }
            }
            self.currentFrame = self.contentFrame();
            self.startPoint = currentTouch!.location(in: self.view.superview);
        }
        else {
            self.activeControlPoint = FTControlPoint.none;
            if(self.isPointInside(currentPoint)) {
                self.isMoving = true;
            }
        }
        self.hideControlPoints(animate: true)
        self.showMenu(false)
        NotificationCenter.default.post(name: Notification.Name(FTPDFDisableGestures), object: self.view.window);
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
        
        if(self.activeControlPoint != .none) {
            if(self.activeControlPoint == FTControlPoint.smoothRotate) {
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
                if photoMode == .normal && !self.activeControlPoint.canScaleProportinally() {
                    if  let resizeObj = FTShapeResizing.shapeResizeObject(shapeType: .rectangle) {
                        resizeObj.capToSizeIfNeeded = true
                        var frame  = resizeObj.resizedBoundingRect(for: touch, in: self.view, rect: self.contentFrame(), scale: 1, activeControlPoint: activeControlPoint)
                        if frame.width < minSizeToMaintain {
                            frame.size.width = minSizeToMaintain
                        }
                        if frame.height < minSizeToMaintain {
                            frame.size.height = minSizeToMaintain
                        }
                        self.updateContentFrame(frame, updateCenter: true)
                    }
                } else {
                    self.performKnobMovedUsingScalingApproach(touch: touch);
                }
           
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
        self.view.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        NotificationCenter.default.post(name: Notification.Name(FTPDFEnableGestures), object: self.view.window);
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
        default:
            break;
        }
    }
    
    @IBAction func didTapOnDelete(_ sender: Any) {
        self.deleteAnnotation()
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
        track("Media_TapRotate", params: [:], screenName: FTScreenNames.media)
    }

    func currentViewAngle() -> CGFloat {
        return self.view.transform.angle
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
            self.angleInfoView?.text = "\(angle)º";
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
        guard let superView = self.view.superview else { return point };
        var newPoint = point;
        let boundaryRect = superView.bounds;
        
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
        guard let superView = self.view.superview else { return center };
        let superViewBounds = superView.bounds;
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
        let anchorPoint = self.view.layer.anchorPoint
        self.view.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        self.view.transform = CGAffineTransform.identity;
        var frame = self.view.frame;
        frame = frame.insetBy(dx: 20, dy: 40);
        self.view.transform = transform;
        self.view.setAnchorPoint(anchorPoint: anchorPoint)
        return frame;
    }
    
    func updateContentFrame(_ frame : CGRect, updateCenter: Bool = false)
    {
        if !(frame.isInfinite) {
            let transform = self.view.transform;
            let center = self.view.center;
            self.view.transform = CGAffineTransform.identity;
            var frameToSet = frame;
            frameToSet = frameToSet.insetBy(dx: -20, dy: -40);
            if(frameToSet.isInfinite) {
                FTLogError("frameToSet is isInfinite");
            }
            self.view.frame = frameToSet;
            self.view.transform = transform;
            if updateCenter {
                self.view.center = center
            }
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
            var contains = bezierPath.contains(point)
            if !contains {
                //Allow touches for rotate and delete button
                contains = self.stackView.frame.contains(point)
            }
            return contains
        }
        else {
            return self.contentImageView!.frame.contains(point);
        }
    }
    
    func isPointInsideKnobViews(newPoint: CGPoint, visibleRect: CGRect)-> Bool {
        var returnValue = false
        for eachView in stackView.subviews {
           let convertedPoint = self.stackView.convert(eachView.frame.origin, to: view)
            let frame = CGRect(origin: convertedPoint, size: CGSize(width: 28, height: 28))
            let convertedFrame = convertedViewFrame(frame, visibleRect: visibleRect)
            if convertedFrame.contains(newPoint) {
                returnValue = true
                break
            }
        }
        return returnValue
    }
    
    private func convertedViewFrame(_ frame: CGRect, visibleRect: CGRect) -> CGRect {
        let contentOffset = (visibleRect.origin)
        let newOriginPoint = CGPointTranslate(frame.origin, contentOffset.x, contentOffset.y)
        return CGRect(origin: newOriginPoint, size: frame.size)
    }
}

private extension FTImageResizeViewController
{
    func activeKnobAtTouch(_ touch : UITouch) -> FTControlPoint
    {
        var controlPoint = FTControlPoint.none;
        
        let currentPointWrtView = touch.location(in: self.view.superview);
        let center = self.view.center;
        
        if(center.x > currentPointWrtView.x && center.y > currentPointWrtView.y) {
            controlPoint = FTControlPoint.topLeft;
        }
        else if(center.x > currentPointWrtView.x && center.y < currentPointWrtView.y) {
            controlPoint = FTControlPoint.bottomLeft;
        }
        if(center.x < currentPointWrtView.x && center.y > currentPointWrtView.y) {
            controlPoint = FTControlPoint.topRight;
        }
        if(center.x < currentPointWrtView.x && center.y < currentPointWrtView.y) {
            controlPoint = FTControlPoint.bottomRight;
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
        
        if(self.activeControlPoint == .bottomRight) {
            newWidth = frame.size.width  + xOffset;
            newHeight = frame.size.height + yOffset;
        }
        else  if(self.activeControlPoint == .topRight) {
            newWidth = frame.size.width  + xOffset;
            newHeight = frame.size.height - yOffset;
        }
        else if(self.activeControlPoint == .topLeft){
            newWidth = frame.size.width  - xOffset;
            newHeight = frame.size.height - yOffset;
        }
        else if(self.activeControlPoint == .bottomLeft){
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
            print(newHeight, "newHeight")
            
            if (newHeight < MIN_HEIGHT) {
                let heightRatio = MIN_HEIGHT/frame.height;
                newHeight = MIN_HEIGHT;
                newWidth *= heightRatio;
            }
            print(newWidth, "newWidth")
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

extension CGPoint
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
}
#if targetEnvironment(macCatalyst)
extension FTImageResizeViewController: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            var actions = [UIMenuElement]()
            if self.allowsEditing {
                let editAction = UIAction(title: NSLocalizedString("Edit", comment: "Edit")) { [weak self] _ in
                    guard let `self` = self else {
                        return
                    }
                    self.editMenuAction(nil)
                }
                actions.append(editAction)
            }
            let cutAction = UIAction(title: NSLocalizedString("Cut", comment: "Cut")) { [weak self] _ in
                self?.cutMenuAction(nil);
            }
            actions.append(cutAction)

            let copyAction = UIAction(title: NSLocalizedString("Copy", comment: "Copy")) { [weak self] _ in
                self?.copyMenuAction(nil);
            }
            actions.append(copyAction)

            let deleteAction = UIAction(title: NSLocalizedString("Delete", comment: "Delete")) { [weak self] _ in
                self?.deleteMenuAction(nil)
            }
            deleteAction.attributes = .destructive;
            actions.append(deleteAction)

            if self.allowsLocking {
                let lockAction = UIAction(title: NSLocalizedString("Lock", comment: "Lock")) { [weak self] _ in
                    self?.lockMenuAction(nil)
                }
                actions.append(lockAction)
            }
            
            let bringToFrontAction = UIAction(title: NSLocalizedString("BringToFront", comment: "BringToFront")) { [weak self] _ in
                self?.moveToFrontAction(nil)
            }
            actions.append(bringToFrontAction)

            let sendToBackAction = UIAction(title: NSLocalizedString("SendToBack", comment: "SendToBack")) { [weak self] _ in
                self?.moveToBackAction(nil)
            }
            actions.append(sendToBackAction)
            
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}
#endif
