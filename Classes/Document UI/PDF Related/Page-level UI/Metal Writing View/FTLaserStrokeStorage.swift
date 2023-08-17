//
//  FTLaserStrokeStorage.swift
//  Noteshelf
//
//  Created by Amar on 22/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let refreshPresentation = Notification.Name(rawValue: "RefreshPresentationNotification");
}

@objcMembers class FTLaserStrokeStorage: NSObject {
    private(set) var undoManager = UndoManager();
    private weak var parentView: UIView?;
    private var strokeInfo = [String: [FTAnnotation]]();
    
    init(parentView inView: UIView?) {
        parentView = inView;
    }
    
    func resetAll() {
        self.undoManager.removeAllActions();
        self.strokeInfo.removeAll();
        
        var userInfo = [String:Any]();
        if let window = self.parentView?.window {
            userInfo[FTRefreshWindowKey] = window;
        }
        NotificationCenter.default.post(name: .didResetLaserAnnotations,
                                        object: nil,
                                        userInfo: userInfo);

    }
    
    func laserAnnotations(for page: FTPageProtocol) -> [FTAnnotation] {
        return self.laserAnnotations(for: page.uuid);
    }
    
    private func laserAnnotations(for pageID: String) -> [FTAnnotation] {
        return strokeInfo[pageID] ?? [FTAnnotation]();
    }

    func addLaserAnnotation(_ annotation: FTAnnotation,for page:FTPageProtocol,isUndoOperation: Bool = false) {
        var laserAnnotations = self.laserAnnotations(for: page)
        undoManager.registerUndo(withTarget: self) { selfObject in
            selfObject.removeLaserAnnotation(annotation, for: page,isUndoOperation: true);
        }
        laserAnnotations.append(annotation);
        strokeInfo[page.uuid] = laserAnnotations;
        if(isUndoOperation) {
            self.postRefreshNotification(rect: annotation.renderingRect, pageID: page.uuid);
        }
        self.postValidateNotification();
    }
    
    func removeLaserAnnotation(_ annotation: FTAnnotation,for page:FTPageProtocol,isUndoOperation: Bool = false) {
        var laserAnnotations = self.laserAnnotations(for: page)
        guard let index = laserAnnotations.firstIndex(of: annotation) else {
            return;
        }
        undoManager.registerUndo(withTarget: self) { selfObject in
            selfObject.addLaserAnnotation(annotation, for: page,isUndoOperation: true);
        }
        laserAnnotations.remove(at: index);
        strokeInfo[page.uuid] = laserAnnotations;
        if(isUndoOperation) {
            self.postRefreshNotification(rect: annotation.renderingRect, pageID: page.uuid);
        }
        self.postValidateNotification();
    }
    
    func clearAllAnnotations(isUndoOperation: Bool  = false) {
        let keys = self.strokeInfo.keys;
        keys.forEach { eachKey in
            self.removeAllAnnotation(for: eachKey);
        }
    }
}

private extension FTLaserStrokeStorage {

    func removeAllAnnotation(for pageID: String,isUndoOperation: Bool = false) {
        var laserAnnotations = self.laserAnnotations(for: pageID)
        undoManager.registerUndo(withTarget: self) { [lastImage = laserAnnotations] selfObject in
            selfObject.addAllAnnotation(lastImage, for: pageID,isUndoOperation: true);
        }
        laserAnnotations.removeAll()
        strokeInfo[pageID] = laserAnnotations;
        if(isUndoOperation) {
            self.postRefreshNotification(rect: nil, pageID: pageID);
        }
        self.postValidateNotification();
    }
    
    func addAllAnnotation(_ annotations: [FTAnnotation],for pageID: String,isUndoOperation: Bool = false) {
        var laserAnnotations = self.laserAnnotations(for: pageID)
        undoManager.registerUndo(withTarget: self) { selfObject in
            selfObject.removeAllAnnotation(for: pageID,isUndoOperation: true);
        }
        laserAnnotations.append(contentsOf: annotations);
        strokeInfo[pageID] = laserAnnotations;
        if(isUndoOperation) {
            self.postRefreshNotification(rect: nil, pageID: pageID);
        }
        self.postValidateNotification();
    }
}

private extension FTLaserStrokeStorage {
    func postValidateNotification() {
        if let window = self.parentView?.window {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTValidateToolBarNotificationName), object: window);
        }
    }
    
    func postRefreshNotification(rect: CGRect?,pageID: String) {
        var userInfo = [String:Any]();
        if let _rect = rect {
            userInfo[FTRefreshRectKey] = _rect;
        }
        if let window = self.parentView?.window {
            userInfo[FTRefreshWindowKey] = window;
        }
        userInfo[FTRefreshPageIDKey] = pageID;
        NotificationCenter.default.post(name: .refreshPresentation,
                                        object: nil,
                                        userInfo: userInfo);
    }
}
