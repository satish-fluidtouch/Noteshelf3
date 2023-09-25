//
//  FTPageUndoRedoGestureDetector.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 22/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc protocol FTUndoRedoDelegate: NSObjectProtocol {
    func performUndoOperation()
    func performRedoOperation()
}

@objcMembers class FTPageUndoRedoGestureDetector: NSObject, UIGestureRecognizerDelegate {
    private var undoGesture: UITapGestureRecognizer?
    private var redoGesture: UITapGestureRecognizer?
    private var pinchGestureToFail: UIPinchGestureRecognizer?
    private var contentHolderView: UIView?
    private weak var undoDelegate: FTUndoRedoDelegate?
    
    init(delegate: FTUndoRedoDelegate, contentHolderView: UIView) {
        self.undoDelegate = delegate
        self.contentHolderView = contentHolderView
    }
    
    func addGestures() {
        undoGesture = UITapGestureRecognizer(target: self, action: #selector(undoGestureTriggered))
        undoGesture?.numberOfTouchesRequired = 2
        undoGesture?.delegate = self
        self.contentHolderView?.addGestureRecognizer(undoGesture!)
        
        redoGesture = UITapGestureRecognizer(target: self, action: #selector(redoGestureTriggered))
        redoGesture?.numberOfTouchesRequired = 3
        redoGesture?.delegate = self
        self.contentHolderView?.addGestureRecognizer(redoGesture!)
        
        pinchGestureToFail = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureTriggered))
        pinchGestureToFail?.cancelsTouchesInView = false
        pinchGestureToFail?.delaysTouchesBegan = false;
        pinchGestureToFail?.delaysTouchesEnded = false;
        pinchGestureToFail?.delegate = self
        self.contentHolderView?.addGestureRecognizer(pinchGestureToFail!)
        self.undoGesture?.require(toFail: pinchGestureToFail!)
        self.redoGesture?.require(toFail: pinchGestureToFail!)
    }
    
    @objc func undoGestureTriggered() {
        self.undoDelegate?.performUndoOperation()
    }
    
    @objc func redoGestureTriggered() {
        self.undoDelegate?.performRedoOperation()
    }
    
    @objc func pinchGestureTriggered() {
    }
    
    func isUndoRedoGestureRecognized(gesture : UIGestureRecognizer) -> Bool {
        return (self.undoGesture == gesture || self.redoGesture == gesture)
    }
    
    @objc func enableDisableUndoGestures(value: Bool) {
        self.undoGesture?.isEnabled = value
        self.redoGesture?.isEnabled = value
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer == self.undoGesture || self.undoGesture == otherGestureRecognizer) {
            return true;
        }
        
        if(gestureRecognizer == self.redoGesture || self.redoGesture == otherGestureRecognizer) {
            return true;
        }
        
        if(gestureRecognizer == self.pinchGestureToFail || self.pinchGestureToFail == otherGestureRecognizer) {
            return true;
        }
        return false
    }
}
