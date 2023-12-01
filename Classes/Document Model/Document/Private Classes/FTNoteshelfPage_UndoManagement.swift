//
//  FTNoteshelfPage_UndoManagement.swift
//  Noteshelf
//
//  Created by Akshay on 31/03/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let pageDidUndoRedoNotification = Notification.Name("FTPageDidUndoRedoNotification")
    static let refreshPageNotification = Notification.Name("FTRefreshPageNotification")
    static let didRemoveAnnotationNotification = Notification.Name("FTDidRemoveAnnotationNotification")
    static let didChangeOrderNotification = Notification.Name("FTDidChangeOrderNotification")
    static let willPerformUndoRedoActionNotification = Notification.Name.FTWillPerformUndoRedoAction;
    static let didUpdateAnnotationNotification = Notification.Name("FTDidUpdateAnnotationNotification")
    static let shouldResignTextfieldNotification = Notification.Name("FTShouldResignTextfieldNotification")
    static let didReplaceAnnotationNotification = Notification.Name("FTDidReplaceAnnotationNotification")
}

private final class FTFilteredItem : NSObject
{
    var annotations = [FTAnnotation]();
    var refreshArea = CGRect.null;
    var undoItemsIndices = [Int]();
}

private final class FTAnnotationWithUndoInfo {
    let annotation: FTAnnotation
    var info: FTUndoableInfo
    init(annotation:FTAnnotation, info:FTUndoableInfo) {
        self.annotation = annotation
        self.info = info
    }
}

protocol FTPageUndoManagement : AnyObject {
    func addAnnotations(_ annotations: [FTAnnotation], indices: [Int]?)
    func removeAnnotations(_ annotations : [FTAnnotation])
    func moveAnnotationsToFront(_ annotations : [FTAnnotation])
    func moveAnnotationsToBack(_ annotations : [FTAnnotation])
    func eraseStroke(segmentCache:FTSegmentTransientCache, isErased: Bool)
    func update(annotation: FTAnnotation, info: FTUndoableInfo, shouldUpdate:Bool)
    func update(annotations: [FTAnnotation], color: UIColor)
    func translate(annotations:[FTAnnotation],
                   startRect: CGRect,
                   targetRect: CGRect,
                   shouldRefresh: Bool,
                   windowHash: Int);
    func translate(annotations:[FTAnnotation], offset: CGPoint, shouldRefresh: Bool)
    func rotate(annotations:[FTAnnotation], angle: CGFloat, refPoint: CGPoint, shouldRefresh: Bool)
}

extension FTNoteshelfPage: FTPageUndoManagement {

    func addAnnotations(_ annotations: [FTAnnotation], indices: [Int]?) {
        var pageModified = false;
        if let annotationsFileItem = self.sqliteFileItem() {
            let annotaionIndices: [Int]? = (indices?.count != annotations.count) ? nil : indices;

            let count = annotations.count;
            for index in 0..<count {
                let eachAnnotation = annotations[index];
                eachAnnotation.didMoveToPage();
                eachAnnotation.associatedPage = self;
                let indexToInsert = annotaionIndices?[index] ?? -1;
                annotationsFileItem.addAnnotation(eachAnnotation,atIndex :indexToInsert);
            }
            pageModified = true;
        }

        let filteredItem = filterAnnotationsSupporingUndo(annotations,
                                                          endEditing: false,
                                                          computeIndices: false)
        let undoableAnnotations = filteredItem.annotations
        if !undoableAnnotations.isEmpty {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                selfObject.removeAnnotations(undoableAnnotations)
                selfObject.postUndoRedoNotification(filteredItem.refreshArea)
            })
        }
        NotificationCenter.default.post(name: .didAddMedia, object: nil, userInfo: ["page" : self, "annotations": undoableAnnotations])
        self.isDirty = pageModified;
    }

    func removeAnnotations(_ annotations : [FTAnnotation]) {
        var pageModified = false;
        let filteredItem = filterAnnotationsSupporingUndo(annotations, endEditing: true, computeIndices: true)
        if let annotationsFileItem = self.sqliteFileItem() {
            for eachAnnotation in annotations {
                annotationsFileItem.removeAnnotation(eachAnnotation);
                self.postDidRemoveNotification(annotation: eachAnnotation);
            }
            pageModified = true;
        }
        let undoableAnnotations = filteredItem.annotations
        if !undoableAnnotations.isEmpty {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                undoableAnnotations.forEach({ $0.hidden = false })
                selfObject.addAnnotations(undoableAnnotations, indices: filteredItem.undoItemsIndices)
                selfObject.postUndoRedoNotification(filteredItem.refreshArea);
            })
        }
        NotificationCenter.default.post(name: .didRemoveMedia, object: nil, userInfo: ["page" : self, "annotations": undoableAnnotations])
        self.isDirty = pageModified;
    }

    func moveAnnotationsToFront(_ annotations: [FTAnnotation]) {
        var pageModified = false;
        let filteredItem = filterAnnotationsSupporingUndo(annotations, endEditing: true, computeIndices: true)
        if let annotationsFileItem = self.sqliteFileItem() {
            annotations.forEach { eachAnnotation in
                annotationsFileItem.move(annotation: eachAnnotation, to: -1)
                self.postDidChangeOrderNotification(annotation: eachAnnotation);
            }
            pageModified = true;
        }
        let undoableAnnotations = filteredItem.annotations
        if !undoableAnnotations.isEmpty {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                selfObject.undoAnnotationsToOriginalPosition(filteredItem: filteredItem, isFromFront: true)
                selfObject.postUndoRedoNotification(filteredItem.refreshArea);
            })
        }
        self.isDirty = pageModified;
    }

    func moveAnnotationsToBack(_ annotations: [FTAnnotation]) {
        var pageModified = false;
        let filteredItem = filterAnnotationsSupporingUndo(annotations, endEditing: true, computeIndices: true)
        if let annotationsFileItem = self.sqliteFileItem() {
            annotations.reversed().forEach { eachAnnotation in
                annotationsFileItem.move(annotation: eachAnnotation, to: 0)
                self.postDidChangeOrderNotification(annotation: eachAnnotation);
            }
            pageModified = true;
        }
        let undoableAnnotations = filteredItem.annotations
        if !undoableAnnotations.isEmpty {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                selfObject.undoAnnotationsToOriginalPosition(filteredItem: filteredItem, isFromFront: false)
                selfObject.postUndoRedoNotification(filteredItem.refreshArea);
            })
        }
        self.isDirty = pageModified;
    }
    
    private func undoAnnotationsToOriginalPosition(filteredItem: FTFilteredItem, isFromFront: Bool) {
        var pageModified = false;
        if let annotationsFileItem = self.sqliteFileItem() {
            if isFromFront {
                for (index,eachAnnotation) in filteredItem.annotations.enumerated() {
                    let indexToInsert = filteredItem.undoItemsIndices[index];
                    annotationsFileItem.move(annotation: eachAnnotation, to: indexToInsert)
                    self.postDidChangeOrderNotification(annotation: eachAnnotation);
                }
            } else {
                //We're using reveresed array for undoing the annotations which were restoring from Send to Back Action
                for (index,eachAnnotation) in filteredItem.annotations.reversed().enumerated() {
                    let indexToInsert = filteredItem.undoItemsIndices.reversed()[index];
                    annotationsFileItem.move(annotation: eachAnnotation, to: indexToInsert)
                    self.postDidChangeOrderNotification(annotation: eachAnnotation);
                }
            }
            pageModified = true;
        }
        let undoableAnnotations = filteredItem.annotations
        if !undoableAnnotations.isEmpty {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                if isFromFront {
                    selfObject.moveAnnotationsToFront(undoableAnnotations)
                } else {
                    selfObject.moveAnnotationsToBack(undoableAnnotations)
                }
                selfObject.postUndoRedoNotification(filteredItem.refreshArea);
            })
        }
        self.isDirty = pageModified;
    }

    //MARK:- Edit Annotation
    func update(annotation: FTAnnotation, info: FTUndoableInfo, shouldUpdate:Bool) {
        let currentInfo = annotation.undoInfo()
        if info.canUndo(currentInfo) {
            let infoToUndo = shouldUpdate ? currentInfo : info;
            self.undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                selfObject.update(annotation: annotation, info: infoToUndo, shouldUpdate: true)
                let rect = currentInfo.renderingRect.union(info.renderingRect)
                selfObject.postUndoRedoNotification(rect);
            })
            if shouldUpdate {
                annotation.updateWithUndoInfo(info)
                NotificationCenter.default.post(name: Notification.Name.didUpdateAnnotationNotification,
                                                object: annotation);
            }
            NotificationCenter.default.post(name: Notification.Name.didUpdateMedia,
                                            object: nil, userInfo: ["page" : self, "annotation": annotation])
            self.isDirty = true
        }
    }

    //MARK:- Eraser
    func eraseStroke(segmentCache:FTSegmentTransientCache, isErased: Bool) {
        self._eraseStroke(segmentCache: segmentCache, isErased: isErased);
        replaceShapeAnnotationsIfNeeded(segmentCache: segmentCache)
    }
    
    private func replaceShapeAnnotationsIfNeeded(segmentCache:FTSegmentTransientCache) {
        let cacheCount = segmentCache.cacheItemCount()
        var shapeAnnotations = Array<FTStroke>()
        var convertedStrokes = Array<FTStroke>()
        
        for index in 0..<cacheCount {
            if let item =  segmentCache.cache(at: index) {
                if let shapeItem = item.stroke as? FTShapeAnnotation, !shapeAnnotations.contains(shapeItem) {
                    shapeAnnotations.append(shapeItem)
                    convertedStrokes.append(shapeItem.asStroke());
                }
            }
        }
        if !convertedStrokes.isEmpty {
            replaceAnnotations(shapeAnnotations, with: convertedStrokes);
        }
    }
    
    private func replaceAnnotations(_ inannotations: [FTAnnotation], with toAnnotations: [FTAnnotation]) {
        guard let annotationsFileItem = self.sqliteFileItem() , inannotations.count == toAnnotations.count else {
            return;
        }
        var indices = [Int]();
        let pageAnnotations = annotations();
        for eachAnnotation in inannotations {
            if let index = pageAnnotations.index(of: eachAnnotation) {
                indices.append(index);
            }
        }
        guard indices.count == toAnnotations.count else {
            return;
        }
        
        var annotationsToAdd = toAnnotations;
        for eachItem in inannotations {
            annotationsFileItem.removeAnnotation(eachItem);
            let index = indices.removeFirst();
            let item = annotationsToAdd.removeFirst();
            annotationsFileItem.addAnnotation(item, atIndex: index);
            NotificationCenter.default.post(name: Notification.Name.didReplaceAnnotationNotification, object: eachItem);
        }
        self.undoManager?.registerUndo(withTarget: self, handler: { (selfOject) in
            selfOject.replaceAnnotations(toAnnotations, with: inannotations);
        })
    }
    
    private func _eraseStroke(segmentCache:FTSegmentTransientCache, isErased: Bool) {

        let cacheCount = segmentCache.cacheItemCount()
        if cacheCount > 0 {
            let undoableCache = FTSegmentTransientCache()
            var rectToRefresh = CGRect.null
            for index in 0..<cacheCount {
                if let item =  segmentCache.cache(at: index) {
                    item.stroke.setErase(isErased: isErased, index: item.index)
                    undoableCache.addEraseCache(item)
                    var bounds = item.stroke.segmentBounds(index: item.index)
                    bounds = bounds.insetBy(dx: -10, dy:  -10)
                    rectToRefresh = rectToRefresh.union(bounds)
                }
            }

            self.undoManager?.registerUndo(withTarget: self, handler: { (selfOject) in
                selfOject._eraseStroke(segmentCache: undoableCache, isErased: !isErased)
                selfOject.postUndoRedoNotification(rectToRefresh);
            })
        }
    }

    //MARK: Color update
    func update(annotations: [FTAnnotation], color: UIColor) {
        var rectToRefresh = CGRect.null

        let annotationsWithColors = annotations.compactMap { annotation -> FTAnnotationWithUndoInfo? in
            if let undoInfo = (annotation as? FTTransformColorUpdate)?.update(color: color) {
                rectToRefresh = rectToRefresh.union(annotation.renderingRect)
                return FTAnnotationWithUndoInfo(annotation:annotation, info:undoInfo)
            } else {
                return nil
            }
        }
        undoManager?.registerUndo(withTarget: self, handler: { selfObject in
            selfObject.updateColorFor(annotationsWithColors: annotationsWithColors)
            selfObject.postUndoRedoNotification(rectToRefresh);
        })
        self.isDirty = !annotationsWithColors.isEmpty;
    }

    private func updateColorFor(annotationsWithColors: [FTAnnotationWithUndoInfo]) {
        var rectToRefresh = CGRect.null
        annotationsWithColors.forEach { item in
                let currentUndoInfo = item.annotation.undoInfo()
                item.annotation.updateWithUndoInfo(item.info)
                rectToRefresh = rectToRefresh.union(item.annotation.renderingRect)

                //Update `item` color here to use it in undo
                item.info = currentUndoInfo
        }
        undoManager?.registerUndo(withTarget: self, handler: { selfObject in
            selfObject.updateColorFor(annotationsWithColors: annotationsWithColors)
            selfObject.postUndoRedoNotification(rectToRefresh);
        })
        self.isDirty = !annotationsWithColors.isEmpty;
    }

    //MARK:- Translation
    func translate(annotations:[FTAnnotation],
                   startRect: CGRect,
                   targetRect: CGRect,
                   shouldRefresh: Bool,
                   windowHash: Int) {
        if startRect != targetRect {
            undoManager?.registerUndo(withTarget: self, handler: { selfObject in
                selfObject.translate(annotations: annotations,
                                     startRect: targetRect,
                                     targetRect:startRect,
                                     shouldRefresh: true,
                                     windowHash: windowHash)
            })
        }
        
        let scale = min(targetRect.width/startRect.width,targetRect.height/startRect.height);
        let translateX = targetRect.origin.x - startRect.origin.x;
        let translateY = targetRect.origin.y - startRect.origin.y;

        var rectToRefresh = CGRect.null;
        annotations.forEach { annotation in
            rectToRefresh = rectToRefresh.union(annotation.renderingRect);
            let xOffsetfromref = (annotation.boundingRect.origin.x - startRect.origin.x)*(scale-1);
            let yOffsetfromref = (annotation.boundingRect.origin.y - startRect.origin.y)*(scale-1);

            let offset = CGPoint(x:translateX+xOffsetfromref, y:translateY+yOffsetfromref);
            annotation.apply(scale)
            annotation.setOffset(offset)
            annotation.setSelected(false, for: windowHash);
            rectToRefresh = rectToRefresh.union(annotation.renderingRect);
        }
        if shouldRefresh {
            self.postUndoRedoNotification(rectToRefresh);
        }
        self.isDirty = !annotations.isEmpty;
    }

    func translate(annotations:[FTAnnotation], offset: CGPoint, shouldRefresh: Bool) {
        annotations.forEach { annotation in
            annotation.setOffset(offset)
        }
        undoManager?.registerUndo(withTarget: self, handler: { selfObject in
            selfObject.translate(annotations: annotations, offset: CGPoint(x:-offset.x, y: -offset.y), shouldRefresh: true)
        })
        if shouldRefresh {
            self.postUndoRedoNotification();
        }
    }

    func rotate(annotations:[FTAnnotation], angle: CGFloat, refPoint: CGPoint, shouldRefresh: Bool) {
        annotations.forEach { annotation in
            annotation.setRotation(angle, refPoint: refPoint)
        }
        undoManager?.registerUndo(withTarget: self, handler: { selfObject in
            selfObject.rotate(annotations: annotations, angle: -angle, refPoint: refPoint, shouldRefresh: true)
        })
        if shouldRefresh {
            self.postUndoRedoNotification();
        }
    }
}

private extension FTNoteshelfPage {

    private func postUndoRedoNotification(_ rect: CGRect = .null) {
        var userInfo: [String:Any]?;
        if(!rect.isNull) {
            userInfo = [FTRefreshRectKey:rect]
        }
        NotificationCenter.default.post(name: .pageDidUndoRedoNotification,
                                        object: self,
                                        userInfo: userInfo)
    }
    
    private func filterAnnotationsSupporingUndo(_ annotations : [FTAnnotation],
                                                endEditing: Bool,
                                                computeIndices: Bool) -> FTFilteredItem {
        let filteredItem = FTFilteredItem();

        let pageAnnotations = self.annotations();
        var annotationWithIndices = [Int:FTAnnotation]()
        for eachAnnotation in annotations {
            if(eachAnnotation.supportsUndo) {
                if let index = pageAnnotations.index(of: eachAnnotation) {
                    annotationWithIndices[index] = eachAnnotation
                }
            }
            filteredItem.refreshArea = filteredItem.refreshArea.union(eachAnnotation.renderingRect);
        }
        ///`key` is the `index` and `value` is the `annotation`
        let sortedAnnotations = annotationWithIndices.sorted(by: {$0.key < $1.key})
        filteredItem.undoItemsIndices = sortedAnnotations.map{$0.key}
        filteredItem.annotations = sortedAnnotations.map{$0.value}
        return filteredItem;
    }
    
    func postDidRemoveNotification(annotation: FTAnnotation) {
        NotificationCenter.default.post(name: .didRemoveAnnotationNotification,
                                        object: self,
                                        userInfo: ["annotation" : annotation])
    }
    
    func postDidChangeOrderNotification(annotation: FTAnnotation) {
        NotificationCenter.default.post(name: .didChangeOrderNotification,
                                        object: self,
                                        userInfo: ["annotation" : annotation])
    }

}
