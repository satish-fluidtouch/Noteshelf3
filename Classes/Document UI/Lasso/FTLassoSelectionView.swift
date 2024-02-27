//
//  FTLassoSelectionView.swift
//  Noteshelf
//
//  Created by Amar on 15/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objc enum FTLassoAction: Int {
    case copy,cut,takeScreenshot,delete,resize,color,convertToText, moveToFront, moveToBack,openAI, saveClip, group, ungroup
}

@objc enum FTLassoSelectionType: Int {
    case freeForm, rectangularForm
}

private let layerName = "notebook.rectangular.layer"

@objc protocol FTLassoSelectionViewDelegate: NSObjectProtocol {
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, selectionAreaMovedByOffset offset: CGPoint);
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView, initiateSelection cutPath: CGPath);
    func lassoSelectionViewFinalizeMoves(_ lassoSelectionView: FTLassoSelectionView);
    
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,canPerform action:FTLassoAction) -> Bool;
    func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,perform action:FTLassoAction);
    
    @objc optional func lassoSelectionView(_ lassoSelectionView: FTLassoSelectionView,
                                     didBeganTouch touch: UITouch?);
    @objc optional func lassoSelectionViewDidEndTouch(_ lassoSelectionView: FTLassoSelectionView);
    @objc optional func lassoSelectionViewDidCompleteMove(_ lassoSelectionView: FTLassoSelectionView);
    #if targetEnvironment(macCatalyst)
    @objc optional func lassoSelectionViewPasteCommand(_ lassoSelectionView: FTLassoSelectionView, at touchedPoint: CGPoint);
    #endif
}

enum FTLassoSelectionMode: Int {
    case `default`,imageEdit;
}

class FTLassoSelectionView: UIView {
    private var lineColor = UIColor.appColor(.ftBlue);
    private var lineWidth: CGFloat = 2;
    var selectionMode: FTLassoSelectionMode = .default;
    
    var selectionRect: CGRect {
        return self.antsView?.frame ?? .zero;
    }
    
    var isSelectionActive: Bool {
        if nil != self.antsView {
            return true;
        }
        return false;
    };
    
    var editingImage = false;
    weak var delegate: FTLassoSelectionViewDelegate?
    weak var antsView: FTMarchingAntsView?;
    private var selectionType: FTLassoSelectionType = .freeForm
    private var shapelayer: CAShapeLayer?
    private var currentPoint: CGPoint = .zero;
    private var previousPoint1: CGPoint = .zero;
    private var previousPoint2: CGPoint = .zero;
    
    private var pointsArray = [CGPoint]();

    private var drawingInProgress = false;
    private var moveInProgress = false;
    private var didMove = false;
    private var pasteCommandMode = false;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.initialize();
    }
    
    convenience init(frame: CGRect, type: FTLassoSelectionType) {
        self.init(frame: frame);
        self.selectionType = type
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.initialize();
    }
    
    private func initialize() {
        #if targetEnvironment(macCatalyst)
        let interaction = UIContextMenuInteraction(delegate: self);
        self.addInteraction(interaction);
        #endif
        self.layer.zPosition=100;
        self.clipsToBounds = true;
        self.isUserInteractionEnabled = false;
        addObserverForLassoSelectionType()
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "selectionTypeLasso");
    }

    func finalizeMove() {
        guard let _antsView = self.antsView else {return};
        self.delegate?.lassoSelectionViewFinalizeMoves(self);
        _antsView.removeMovingAntsPath();
        _antsView.removeFromSuperview();
        self.hideMenu();
        self.antsView = nil;
        self.shapelayer?.removeFromSuperlayer()
        self.shapelayer = nil
    }
    
    override var canBecomeFirstResponder: Bool {
        return true;
    }

    func showMenuFrom(rect: CGRect) {
        #if !targetEnvironment(macCatalyst)
        self.becomeFirstResponder();
        let theMenu = UIMenuController.shared;
        
        let screenshotMenuItem = UIMenuItem(title: NSLocalizedString("TakeScreenshot", comment: "Take Screenshot"), action: #selector(self.screenshotMenuAction(_:)));
        let cutMenuItem = UIMenuItem(title: NSLocalizedString("Cut", comment: "Cut"), action: #selector(self.cutMenuAction(_:)));
        let copyMenuItem = UIMenuItem(title: NSLocalizedString("Copy", comment: "Copy"), action: #selector(self.copyMenuAction(_:)));
        let deleteMenuItem = UIMenuItem(title: NSLocalizedString("Delete", comment: "Delete"), action: #selector(self.deleteMenuAction(_:)));
        let resizeMenuItem = UIMenuItem(title: NSLocalizedString("Resize", comment: "Resize"), action: #selector(self.resizeMenuAction));
        let colorMenuItem = UIMenuItem(title: NSLocalizedString("Color", comment: "Color"), action: #selector(self.colorMenuAction(_:)));
        let convertToText = UIMenuItem(title: NSLocalizedString("ConvertToText", comment: "Convert To Text"), action: #selector(self.convertToTextAction(_:)));
        let moveToFront = UIMenuItem(title: NSLocalizedString("BringToFront", comment: "BringToFront"), action: #selector(self.moveToFrontAction(_:)));
        let moveToBack = UIMenuItem(title: NSLocalizedString("SendToBack", comment: "SendToBack"), action: #selector(self.moveToBackAction(_:)));
        let openAI = UIMenuItem(title: "noteshelf.ai.noteshelfAI".aiLocalizedString, action: #selector(self.openAIAction(_:)));
        let saveClip = UIMenuItem(title: "clip.saveClip".localized, action: #selector(self.saveClip(_:)));

// (AK): Hiding these items temporarily, these will provide the behind the scenes functionality.
//        let groupMenuItem = UIMenuItem(title: NSLocalizedString("Group", comment: "Group"), action: #selector(self.groupMenuAction(_:)));
//        let ungroupMenuItem = UIMenuItem(title: NSLocalizedString("Ungroup", comment: "Group"), action: #selector(self.ungroupMenuAction(_:)));

        var options = [cutMenuItem
                       ,copyMenuItem
                       ,deleteMenuItem
                       ,resizeMenuItem
                       ,saveClip
                       ,colorMenuItem
                       ,screenshotMenuItem
                       ,convertToText
                       ,moveToFront
                       ,moveToBack
        ]
        if FTNoteshelfAI.supportsNoteshelfAI {
            options.insert(openAI, at: 3);
        }
        
        theMenu.menuItems = options;
        self.window?.makeKey()
        theMenu.showMenu(from: self, rect: rect)
        #endif
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        var retValue = super.canPerformAction(action, withSender: sender);
        if action == #selector(FTLassoSelectionView.cutMenuAction(_:))
            || action == #selector(FTLassoSelectionView.copyMenuAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .cut)
        }
        else if action == #selector(FTLassoSelectionView.resizeMenuAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .resize)
        }
        else if action == #selector(FTLassoSelectionView.deleteMenuAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .delete)
        }
        else if action == #selector(FTLassoSelectionView.screenshotMenuAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .takeScreenshot)
        }
        else if action == #selector(FTLassoSelectionView.colorMenuAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .color)
        }
        else if action == #selector(FTLassoSelectionView.convertToTextAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .convertToText)
        }
        else if action == #selector(FTLassoSelectionView.moveToFrontAction(_:)) {
            retValue = delegate.lassoSelectionView(self, canPerform: .moveToFront)
        }
        else if action == #selector(FTLassoSelectionView.moveToBackAction(_:)) {
                 retValue = delegate.lassoSelectionView(self, canPerform: .moveToBack)
        }
        else if action == #selector(FTLassoSelectionView.saveClip(_:)) {
                 retValue = delegate.lassoSelectionView(self, canPerform: .saveClip)
        }
        else if action == #selector(FTLassoSelectionView.openAIAction(_:)) {
            retValue = !FTNoteshelfAI.supportsNoteshelfAI ? false : delegate.lassoSelectionView(self, canPerform: .openAI)
        }
        else if action == #selector(FTLassoSelectionView.groupMenuAction(_:)) {
            retValue = self.delegate?.lassoSelectionView(self, canPerform: .group) ?? true;
        }
        else if action == #selector(FTLassoSelectionView.ungroupMenuAction(_:)) {
            retValue = self.delegate?.lassoSelectionView(self, canPerform: .ungroup) ?? true;
        }
        return retValue;
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        self.processTouchesBegan(touches, with: event);
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        self.processTouchesMoved(touches, with: event);
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        self.processTouchesEnded(touches, with: event);
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event);
        self.processTouchesCancelled(touches, with: event);
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect);
        if(self.drawingInProgress || moveInProgress || self.pointsArray.count < 3) {
            return;
        }
        // Setup the path
        var path = self.pathFrom(points: self.pointsArray);
        if selectionType == .rectangularForm {
            path = shapelayer?.path ?? CGPath(rect: .zero, transform: .none)
        }
        self.pointsArray.removeAll();

        let rect = path.boundingBoxOfPath;
        var t = CGAffineTransform(translationX: -rect.origin.x, y: -rect.origin.y);
        if let transPath = path.copy(using: &t) {
            self.antsView?.removeFromSuperview();
            let _antsView = FTMarchingAntsView(frame: rect);
            self.addSubview(_antsView);
            _antsView.setMarchingAntsPath(transPath);
            self.antsView = _antsView;
        }
        self.delegate?.lassoSelectionView(self, initiateSelection: path);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "selectionTypeLasso" {
            let type: FTLassoSelectionType = FTRackPreferenceState.lassoSelectionType == 0 ? .freeForm : .rectangularForm
            self.selectionType = type
        }
    }
    
    private func addObserverForLassoSelectionType() {
        UserDefaults.standard.addObserver(self, forKeyPath: "selectionTypeLasso", options: .new, context: nil)
    }
}

private extension FTLassoSelectionView {
    func validTouchFrom(touches: Set<UITouch>) -> UITouch? {
        var touch: UITouch?;
        if(UserDefaults.isApplePencilEnabled()) {
            for eachTouch in touches where eachTouch.type == .pencil {
                touch = eachTouch;
                break;
            }
        }
        else {
            touch = touches.first;
        }

        if self.selectionMode == .imageEdit,nil == touch {
            touch = touches.first;
        }

        if nil == touch,
            let touch2 = touches.first,
            let _antsview = self.antsView,
            _antsview.frame.contains(touch2.location(in: self)) {
            touch = touch2;
        }
        return touch;
    }
    
    func pathFrom(points: [CGPoint]) -> CGPath {
        let path = CGMutablePath();
        
        let pPoint2 = points[0];
        var pPoint1 = points[1];
        var currentPoint = points[2];
        
        let mid1 = pPoint2.midPoint(pPoint1);
        path.move(to: mid1);
        
        for i in 3...points.count {
            let mid2 = currentPoint.midPoint(pPoint1);
            
            path.addQuadCurve(to: mid2, control: pPoint1)
            pPoint1  = currentPoint;
            
            if (i != points.count) {
                currentPoint = points[i];
            }
        }
        path.closeSubpath();
        return path;
    }
}

extension FTLassoSelectionView : FTTouchEventsHandling {
    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.hideMenu();
        
        let touch = self.validTouchFrom(touches: touches);
        self.delegate?.lassoSelectionView?(self, didBeganTouch: touch);
        
        guard let _touch = touch else {
            if let _antsView = antsView {
                self.delegate?.lassoSelectionViewFinalizeMoves(self);
                _antsView.removeMovingAntsPath();
                _antsView.removeFromSuperview();
                self.antsView = nil;
                self.shapelayer?.removeFromSuperlayer()
                self.shapelayer = nil
            }
            return;
        }
        
        self.previousPoint1 = _touch.previousLocation(in: self);
        self.previousPoint2 = _touch.previousLocation(in: self);
        self.currentPoint = _touch.location(in: self);
        
        self.drawingInProgress = false;
        self.moveInProgress = false;
        self.didMove = false;
        self.pasteCommandMode = false;
        
        NotificationCenter.default.post(name: Notification.Name(FTPDFDisableGestures), object: self.window);

        if let _antsView = self.antsView {
            let currentAntsViewPoint = self.convert(currentPoint, to: _antsView);
            if(_antsView.isPointInsidePath(currentAntsViewPoint)) {
                self.moveInProgress = true;
                return;
            }
            self.delegate?.lassoSelectionViewFinalizeMoves(self);
            _antsView.removeMovingAntsPath();
            _antsView.removeFromSuperview();
            self.antsView = nil;
            self.shapelayer?.removeFromSuperlayer()
            self.shapelayer = nil
            return;
        }
        
        self.drawingInProgress = true;
        self.pointsArray.removeAll();
        self.pointsArray.append(currentPoint);
    }
    
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = self.validTouchFrom(touches: touches) else {
            return;
        }
        
        let newPoint = touch.location(in: self);
        let distance = currentPoint.distanceTo(p: newPoint);

        if(distance <= 0) {
            return;
        }

        self.previousPoint2  = previousPoint1;
        self.previousPoint1  = currentPoint;
        self.currentPoint    = newPoint;
        
        if (self.moveInProgress) {
            let xOffset = currentPoint.x - previousPoint1.x; //Rounding to fix the blurring issue
            let yOffset = currentPoint.y - previousPoint1.y; //Rounding to fix the blurring issue
            
            if(!self.didMove) {
                self.didMove = true;
            }
            
            if let _antsView = self.antsView {
                _antsView.frame = _antsView.frame.applying(CGAffineTransform(translationX: xOffset, y: yOffset));
            }
            
            self.delegate?.lassoSelectionView(self, selectionAreaMovedByOffset: CGPoint(x: xOffset, y: yOffset));
            self.hideMenu();
        }
        
        if (self.drawingInProgress) {
            self.pointsArray.append(currentPoint);
            switch self.selectionType {
            case .freeForm:
                self.drawFreePathWith(previousPoint1: previousPoint1, previouPoint2: previousPoint2, currentPoint: self.currentPoint)
            case .rectangularForm:
                self.drawRectangularPathWithTouch(touch)
            default:
                break
            }
        }
    }
    
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.lassoSelectionViewDidEndTouch?(self);
        let touch = self.validTouchFrom(touches: touches);
        if let _touch = touch, _touch.tapCount != 0 {
            if(self.pointsArray.count > 3) {
                let path = self.pathFrom(points: self.pointsArray);
                let rect = path.boundingBoxOfPath;
                if(rect.width < 10 || rect.height < 10) {
                    self.pointsArray.removeAll();
                }
            }
            else {
                self.pointsArray.removeAll();
            }
        }

        if (self.moveInProgress && self.didMove) {
            self.delegate?.lassoSelectionViewDidCompleteMove?(self);
        }
        
        if (self.drawingInProgress) {
            //Remove any shape layers added by the lasso drawing
            let layersArray = self.layer.sublayers;
            layersArray?.forEach({ (eachLayer) in
                if(eachLayer is CAShapeLayer) {
                    eachLayer.removeFromSuperlayer();
                }
            })
        }
        
        if (!self.editingImage) {
            if ((moveInProgress && (nil != antsView)) || drawingInProgress) {
                runInMainThread(0.001) { [weak self] in
                    if let _antsView = self?.antsView {
                        self?.showMenuFrom(rect: _antsView.frame);
                    }
                }
            }
        }

        self.drawingInProgress = false;
        self.moveInProgress = false;
        self.didMove = false;
        self.pasteCommandMode = false;
        self.setNeedsDisplay();
    }
    
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.lassoSelectionViewDidEndTouch?(self);
        if (self.drawingInProgress) {
            //Remove any shape layers added by the lasso drawing
            let layers = self.layer.sublayers;
            layers?.forEach({ (eachLayer) in
                if(eachLayer is CAShapeLayer) {
                    eachLayer.removeFromSuperlayer();
                }
            })
        }
        self.drawingInProgress = false;
        self.moveInProgress = false;
        self.didMove = false;
        self.pasteCommandMode = false;
        self.pointsArray.removeAll();
        self.setNeedsDisplay();
    }
}

extension FTLassoSelectionView {
    private func drawFreePathWith(previousPoint1: CGPoint, previouPoint2: CGPoint, currentPoint: CGPoint) {
        // calculate mid point
        let mid1 = previousPoint1.midPoint(previouPoint2);
        let mid2 = currentPoint.midPoint(previousPoint1);
        
        //Create a path and evaluate its bounds
        let path = CGMutablePath();
        path.move(to: mid1);
        path.addQuadCurve(to: mid2, control: previousPoint1);
        let bounds = path.boundingBoxOfPath;
        
        //Translate the path to (0,0) so a shape layer can be created with it
        var transform = CGAffineTransform(translationX: -bounds.origin.x, y: -bounds.origin.y);
        let draPath = path.copy(using: &transform);
        
        //Create a shape layer and add it to the view's layer
        let curveLayer = CAShapeLayer();
        curveLayer.path = draPath;
        curveLayer.frame = bounds;
        curveLayer.strokeColor = self.lineColor.cgColor;
        curveLayer.fillColor = UIColor.clear.cgColor;
        curveLayer.lineCap = .round;
        curveLayer.lineWidth = self.lineWidth;
        self.layer.addSublayer(curveLayer);
    }
    
    private func drawRectangularPathWithTouch(_ touch: UITouch) {
        let currentPoint = touch.location(in: self);
        let pointA = self.pointsArray[0]
        let pointB = CGPoint(x: currentPoint.x, y: pointA.y)
        let pointC = currentPoint
        let pointD = CGPoint(x: pointA.x, y: currentPoint.y)
        
        
        let pathRect = UIBezierPath()
        pathRect.move(to: pointA)
        pathRect.addLine(to:pointB)
        pathRect.addLine(to: pointC)
        pathRect.addLine(to: pointD)
        pathRect.close()
        if shapelayer == nil {
            shapelayer = CAShapeLayer()
        }
        guard let rectLayer = shapelayer else { return }
        rectLayer.name = layerName
        rectLayer.path = pathRect.cgPath;
        rectLayer.strokeColor = self.lineColor.cgColor;
        rectLayer.fillColor = UIColor.clear.cgColor;
        rectLayer.lineCap = .round;
        rectLayer.lineDashPattern = [NSNumber(value: 10),NSNumber(value: 5)];
        rectLayer.lineWidth = self.lineWidth;
        let layer = self.layer.sublayers?.last(where: {$0.name == layerName})
        layer?.removeFromSuperlayer()
        self.layer.addSublayer(rectLayer);
    }
}

@objc private extension FTLassoSelectionView {
    func screenshotMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .takeScreenshot)
        track("lasso_screenshot_tapped", params: [:], screenName: FTScreenNames.lasso)
    }
    
    func cutMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .cut)
        track("lasso_cut_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func copyMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .copy)
        track("lasso_copy_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func deleteMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .delete)
        track("lasso_delete_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func resizeMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .resize)
        track("lasso_resize_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func colorMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .color)
        track("lasso_color_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func convertToTextAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .convertToText)
        track("lasso_converttext_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func moveToFrontAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .moveToFront)
        track("lasso_bringtofront_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func moveToBackAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .moveToBack)
        track("lasso_sendtoback_tapped", params: [:], screenName: FTScreenNames.lasso)
    }
    
    func openAIAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .openAI)
        track("lasso_openAI_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func groupMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .group)
        track("lasso_group_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func ungroupMenuAction(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .ungroup)
        track("lasso_ungroup_tapped", params: [:], screenName: FTScreenNames.lasso)
    }

    func hideMenu() {
        #if !targetEnvironment(macCatalyst)
        UIMenuController.shared.hideMenu()
        #endif
    }

    func saveClip(_ sender:Any?) {
        self.delegate?.lassoSelectionView(self, perform: .saveClip)
        track("lasso_snippet_tapped", params: [:], screenName: FTScreenNames.lasso)
    }
}

#if targetEnvironment(macCatalyst)
extension UIAction {
    convenience init(title: String,handler : @escaping (UIAction) -> ()) {
        self.init(title: title,
                  image: nil,
                  identifier: nil,
                  discoverabilityTitle: nil,
                  attributes: UIMenuElement.Attributes.init(rawValue: 0),
                  state: .off,
                  handler: handler);
    }
}

extension FTLassoSelectionView
{
    func getContextMenuFor(interaction: UIContextMenuInteraction) -> UIMenu {
        let isLassoActive = (nil != self.antsView);
        var menuItems = [UIMenuElement]();
        if(isLassoActive) {
            if self.delegate?.lassoSelectionView(self, canPerform: .cut) ?? true {
                let cut = UIAction(title: NSLocalizedString("Cut", comment: "Cut")) { [weak self] (_) in
                    self?.cutMenuAction(nil);
                }
                menuItems.append(cut);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .copy) ?? true {
                let copy = UIAction(title: NSLocalizedString("Copy", comment: "Copy")) { [weak self] (_) in
                    self?.copyMenuAction(nil);
                }
                menuItems.append(copy);
            }
        }

        if(!isLassoActive && UIPasteboard.canPasteContent()) {
            let paste = UIAction(title: NSLocalizedString("Paste", comment: "Paste")) { [weak self] (_) in
                guard let strongSelf = self else { return }
                self?.delegate?.lassoSelectionViewPasteCommand?(strongSelf,
                                                                at: interaction.location(in: strongSelf));
                strongSelf.resignFirstResponder();
            }
            menuItems.append(paste);
        }
        
        if(isLassoActive) {
            if self.delegate?.lassoSelectionView(self, canPerform: .delete) ?? true {
                let delete = UIAction(title: NSLocalizedString("Delete", comment: "Delete")) { [weak self] (_) in
                    self?.deleteMenuAction(nil);
                }
                menuItems.append(delete);
            }

            if FTNoteshelfAI.supportsNoteshelfAI,
               self.delegate?.lassoSelectionView(self, canPerform: .openAI) ?? true {
                let action = UIAction(title: "noteshelf.ai.noteshelfAI".aiLocalizedString) { [weak self] (_) in
                    self?.openAIAction(nil);
                }
                menuItems.append(action);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .resize) ?? true {
                let resize = UIAction(title: NSLocalizedString("Resize", comment: "Resize")) { [weak self] (_) in
                    self?.resizeMenuAction(nil);
                }
                menuItems.append(resize);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .saveClip) ?? true {
                let saveClip = UIAction(title: "clip.saveClip".localized) { [weak self] (_) in
                    self?.saveClip(nil);
                }
                menuItems.append(saveClip);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .takeScreenshot) ?? true {
                let takeScreenshot = UIAction(title: NSLocalizedString("TakeScreenshot", comment: "Take screenshot")) { [weak self] (_) in
                    self?.screenshotMenuAction(nil);
                }
                menuItems.append(takeScreenshot);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .color) ?? true {
                let color = UIAction(title: NSLocalizedString("Color", comment: "Color")) { [weak self] (_) in
                    self?.colorMenuAction(nil);
                }
                menuItems.append(color);
            }
            
            if supportsHWRecognition, self.delegate?.lassoSelectionView(self, canPerform: .convertToText) ?? true {
                let action = UIAction(title: NSLocalizedString("ConvertToText", comment: "Convert To Text")) { [weak self] (_) in
                    self?.convertToTextAction(nil)
                }
                menuItems.append(action);
            }
            
            if self.delegate?.lassoSelectionView(self, canPerform: .moveToFront) ?? true {
                let action = UIAction(title: NSLocalizedString("BringToFront", comment: "BringToFront")) { [weak self] (_) in
                    self?.moveToFrontAction(nil);
                }
                menuItems.append(action);
            }

            if self.delegate?.lassoSelectionView(self, canPerform: .moveToBack) ?? true {
                let action = UIAction(title: NSLocalizedString("SendToBack", comment: "SendToBack")) { [weak self] (_) in
                    self?.moveToBackAction(nil);
                }
                menuItems.append(action);
            }
        }
        let menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: menuItems);
        return menu;
    }
}

extension FTLassoSelectionView: UIContextMenuInteractionDelegate
{
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if (self.editingImage) {
            return nil
        }
        let actionProvider : ([UIMenuElement]) -> UIMenu? = {[weak self] _ in
            return self?.getContextMenuFor(interaction: interaction);
        }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
        return config
    }
}

#endif

extension CGPoint {
    func midPoint(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x+point.x)*0.5, y: (self.y+point.y)*0.5)
    }
}
