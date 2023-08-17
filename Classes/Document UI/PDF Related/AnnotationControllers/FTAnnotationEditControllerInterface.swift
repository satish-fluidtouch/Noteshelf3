//
//  FTAnnotationEditControllerInterface.swift
//  Noteshelf
//
//  Created by Naidu on 07/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc enum FTAnnotationMode: Int {
    case create
    case edit
}
protocol FTTransformColorUpdate: NSObjectProtocol {
    func update(color: UIColor) -> FTUndoableInfo
    var currentColor: UIColor? { get }
}

@objcMembers class FTUndoableInfo : NSObject
{
    var boundingRect : CGRect = CGRect.zero;
    var renderingRect : CGRect = CGRect.zero;
    var annotationversion : Int = 1
    
    convenience init(withAnnotation annotation: FTAnnotation)
    {
        self.init();
        self.boundingRect = annotation.boundingRect;
        self.renderingRect = annotation.renderingRect;
        self.annotationversion = annotation.version;
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let undoInfo = object as? FTUndoableInfo else {
            return false;
        }
        return (undoInfo.boundingRect.integral == self.boundingRect.integral)
    }
    
    func canUndo(_ object : FTUndoableInfo) -> Bool {
        return !isEqual(object);
    }
}

@objc protocol FTAnnotationUndoRedo {
    func undoInfo() -> FTUndoableInfo;
    func updateWithUndoInfo(_ info: FTUndoableInfo);
}

typealias FTAnnotationEditController = UIViewController & FTAnnotationEditControllerInterface

@objc protocol FTAnnotationEditControllerDelegate : NSObjectProtocol, FTShapeAnntationEditDelegate {
    //Perform action
    func annotationController(_ controller : FTAnnotationEditController,
                              scrollToRect targetRect : CGRect)
   
    func annotationControllerDidRemoveAnnotation(_ controller : FTAnnotationEditController,
                                                 annotation : FTAnnotation);
    func annotationControllerDidAddAnnotation(_ controller : FTAnnotationEditController,
                                              annotation : FTAnnotation);
    
    //Notification-
    func annotationControllerDidChange(_ controller : FTAnnotationEditController,
                                       undoableInfo : FTUndoableInfo)
    // Layering individual annotations
    func moveAnnotationToFront(_ annotation : FTAnnotation)
    func moveAnnotationToBack(_ annotation : FTAnnotation)
    
    //Get information
    func contentScale() -> CGFloat
    
    //Get visibleRect
    func visibleRect() -> CGRect

    //Other
    func annotationControllerDidCancel(_ controller : FTAnnotationEditController)
    // Refresh Ann
    func refreshView(refreshArea: CGRect)
    func isZoomModeEnabled() -> Bool
    #if targetEnvironment(macCatalyst)
    @objc optional
    func annotationControllerWillBeginEditing(_ controller : FTTextAnnotationViewController)
    func getInputAccessoryViewController() -> FTTextToolBarViewController?
    #endif
    
    @objc optional func convertToStroke(_ controller : FTAnnotationEditController,
                                        annotation : FTAnnotation);
    //Toolbar
    func annotationControllerDidAdded(_ controller: FTTextAnnotationViewController)
    func annotationControllerDidEnded(_ controller: FTTextAnnotationViewController)
    
}

@objc protocol FTShapeAnntationEditDelegate: NSObjectProtocol {
    func shapeAnnotationOptions(perform action:FTShapeEditAction, annotation: FTAnnotation);
}

@objc protocol FTAnnotationEditControllerInterface : NSObjectProtocol {
    var delegate: FTAnnotationEditControllerDelegate? {get}
    
    var annotation : FTAnnotation {get}
    var supportOrientationChanges : Bool {get}
    init?(withAnnotation annotation: FTAnnotation,
          delegate: FTAnnotationEditControllerDelegate?,
          mode: FTAnnotationMode)

    func endEditingAnnotation()
    
    //passing CGPoint.zero will not have any effect. Currently point is untilizes only for text annotation.
    func processEvent(_ eventType : FTProcessEventType,at point:CGPoint);
    func refreshView();
    func saveChanges();
    func isPointInside(_ point : CGPoint,fromView : UIView) -> Bool;
    
    func updateViewToCurrentScale(fromScale : CGFloat);
    func annotationControllerLongPressDetected()

    #if targetEnvironment(macCatalyst)
    @objc optional func canPerformAction(_ selector: Selector) -> Bool
    @objc optional func performAction(_ selector: Selector);
    #endif
}
