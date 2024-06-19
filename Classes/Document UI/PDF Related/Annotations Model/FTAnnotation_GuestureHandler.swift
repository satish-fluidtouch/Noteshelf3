//
//  FTAnnotation_UIHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAnnotationAction: NSObject
{
    weak var annotation: FTAnnotation?
    var URL: URL?;
//    var attributes: [NSAttributedString.Key:Any]?;
    var rect = CGRect.null;
}

protocol FTAnnotationLinkHandler {
    func hasLink(atPoint point : CGPoint) -> FTAnnotationAction?;
}

protocol FTAnnotationSingleTapHandler {
    func canHandleSingleTapEvent(atPoint point : CGPoint) -> Bool;
    func performSingleTapEvent(atPoint point : CGPoint) -> FTUndoableInfo?;
}

protocol FTAnnotationSingleTapSelector {
    func allowsSingleTapSelection(atPoint point : CGPoint) -> Bool
}

protocol FTAnnotationLongPressHandler {
    func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool;
}



//MARK:- FTAnnotationSingleTapHandler
extension FTTextAnnotation : FTAnnotationSingleTapHandler, FTAnnotationLongPressHandler, FTAnnotationSingleTapSelector,FTAnnotationLinkHandler
{
    func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool {
        return self.isPointInside(point);
    }
    
    func allowsSingleTapSelection(atPoint point: CGPoint) -> Bool {
        return self.isPointInside(point)
    }

    func canHandleSingleTapEvent(atPoint point : CGPoint) -> Bool {
        var canHandle = false;
        if(self.isPointInside(point)) {
            let pointWithinBoundary = CGPointTranslate(point, -self.boundingRect.origin.x, -self.boundingRect.origin.y);
            let checkboxHelper = FTTextAnnotationCheckBoxHelper();
            if checkboxHelper.checkIfCheckboxExists(atPoint: pointWithinBoundary, forAnnotation: self) {
                canHandle = true;
            }
            checkboxHelper.cleanUpMemory();
        }
        return canHandle;
    }
    
    func performSingleTapEvent(atPoint point : CGPoint) -> FTUndoableInfo? {
        var undoableInfo : FTUndoableInfo?;
        
        let pointWithinBoundary = CGPointTranslate(point, -self.boundingRect.origin.x, -self.boundingRect.origin.y);
        let checkboxHelper = FTTextAnnotationCheckBoxHelper();
        if checkboxHelper.checkIfCheckboxExists(atPoint: pointWithinBoundary,
                                                forAnnotation: self) {
            undoableInfo = self.undoInfo();
            checkboxHelper.toggleCheckBox(atPoint: pointWithinBoundary,
                                          annotation: self);
        }
        checkboxHelper.cleanUpMemory();
        return undoableInfo;
    }
    
    func hasLink(atPoint point: CGPoint) -> FTAnnotationAction? {
        var linkInfo: FTAnnotationAction?;
        if(self.isPointInside(point)) {
            let boundingRect = self.boundingRect;
            let pointWithinBoundary = CGPointTranslate(point, -boundingRect.origin.x, -boundingRect.origin.y);
            let linkHelper = FTTextAnnotationLinkHelper();
            linkInfo = linkHelper.linkInfo(at: pointWithinBoundary, forAnnotation: self);
            if let linkRect = linkInfo?.rect, !linkRect.isNull {
                linkInfo?.rect.origin = CGPointTranslate(linkRect.origin, boundingRect.origin.x, boundingRect.origin.y)
            }
            linkHelper.cleanUpMemory();
        }
        return linkInfo;
    }
}

extension FTAudioAnnotation : FTAnnotationSingleTapHandler,FTAnnotationLongPressHandler
{
    func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool {
        return self.isPointInside(point);
    }

    func canHandleSingleTapEvent(atPoint point: CGPoint) -> Bool {
         return self.isPointInside(point);
     }

     func performSingleTapEvent(atPoint point : CGPoint) -> FTUndoableInfo? {
         return nil;
     }
}

extension FTImageAnnotation : FTAnnotationLongPressHandler {
    func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool {
        return self.isPointInside(point);
    }
}

extension FTImageAnnotation : FTAnnotationSingleTapSelector {
    func allowsSingleTapSelection(atPoint point: CGPoint) -> Bool {
        return self.isPointInside(point)
    }
}

extension FTShapeAnnotation : FTAnnotationSingleTapSelector {
    func allowsSingleTapSelection(atPoint point: CGPoint) -> Bool {
        var result = false;
        let maxOffSet: CGFloat = 12
        for i in 0..<self.segmentCount {
            let segment = self.segmentArray[i];
            if !segment.isErased {
                var segmentBounds = segment.bounds()
                let insetx = (segmentBounds.width < maxOffSet) ? (maxOffSet - segmentBounds.width) * 0.5 : 0;
                let insety = (segmentBounds.height < maxOffSet) ? (maxOffSet - segmentBounds.height) * 0.5 : 0;
                segmentBounds = segmentBounds.insetBy(dx: -insetx, dy: -insety);
                if(segmentBounds.contains(point)) {
                    result = true;
                    break;
                }
            }
        }
        return result;
    }
}

extension FTShapeAnnotation {
    override func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool {
        return self.allowsSingleTapSelection(atPoint: point)
    }
}

extension FTStroke: FTAnnotationLongPressHandler {
    func canHandleLongPressEvent(atPoint point : CGPoint) -> Bool {
        guard nil != self.groupId
                ,self.intersectsPath(point.pathWith1Px, withScale: 1.0, withOffset: CGPoint.zero) else {
            return false
        }
        return true
    }
}

extension CGPoint {
    var pathWith1Px: CGPath {
        let largerRect = CGRect(x: self.x, y: self.y, width: 1, height: 1).insetBy(dx: -10, dy: -10)
        let path1x = CGPath(rect: largerRect, transform: nil)
        return path1x
    }
}
