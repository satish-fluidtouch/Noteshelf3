//
//  FTImageResizeViewController.swift
//  Noteshelf
//
//  Created by Matra on 06/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTImageResizeProtocol {
    func finalFrame() -> CGRect
}

@objc
protocol FTLassoContentSelectionDelegate: AnyObject {
    func lassoContentViewControllerDidEndEditing(with initialFrame : CGRect,
                                                 currentFrame : CGRect,
                                                 angle: CGFloat,
                                                 refPoint: CGPoint,
                                                 controller : FTLassoContentSelectionViewController)
    func visibleRect() -> CGRect
    func deleteLassoSelectedAnnotation(controller: FTLassoContentSelectionViewController)
}

@objcMembers
class FTLassoContentSelectionViewController: UIViewController {
    
    private var _initialFrame : CGRect?
    private weak var editorController : FTImageResizeViewController?
    weak var delegate : FTLassoContentSelectionDelegate?
    
    var initialFrame : CGRect {
        get{
            return _initialFrame!
        }
        set{
            let frame = newValue.integral
            self.editorController?.updateContentFrame(frame)
            self.editorController?.allowsEditing = true
            _initialFrame = frame
            self.editorController?.photoMode = .transform
        }
    }
    
    required init(withImage image : UIImage,
                  boundingRect : CGRect) {
        super.init(nibName: nil, bundle: nil);
        self.view.frame = boundingRect
        let editor = FTImageResizeViewController.init(withImage: image)
        self.editorController = editor
        self.addChild(editor);
        self.view.isExclusiveTouch = true
        self.view.addSubview(editor.view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func endEditing() {
        if let controller = self.editorController {
            let refPoint = CGPoint(x:controller.view.frame.midX, y:controller.view.frame.midY)
            self.delegate?.lassoContentViewControllerDidEndEditing(
                with: self.initialFrame,
                currentFrame: controller.finalFrame(),
                angle: controller.currentViewAngle(),
                refPoint: refPoint,
                controller: self)
        }
    }
    
    func deleteAnnotation() {
        self.delegate?.deleteLassoSelectedAnnotation(controller: self)
    }
    
    // MARK: - Gesture
    @objc private func singleTapGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if let controller = self.editorController {
            let refPoint = CGPoint(x:controller.view.frame.midX, y:controller.view.frame.midY)

            self.delegate?.lassoContentViewControllerDidEndEditing(
                with: self.initialFrame,
                currentFrame: controller.finalFrame(),
                angle: controller.currentViewAngle(),
                refPoint: refPoint,
                controller: self)
        }
    }
    
    func isPointInside(_ point : CGPoint) -> Bool {
        if let editController = self.editorController {
            let newPoint = self.view.convert(point, to: editController.view)
            var returnValue = editController.isPointInside(newPoint);
            if !returnValue {
                returnValue = editController.isPointInsideKnobViews(newPoint: newPoint, visibleRect: self.delegate?.visibleRect() ?? .zero)
            }
            return returnValue
        }
        return false;
    }
}
