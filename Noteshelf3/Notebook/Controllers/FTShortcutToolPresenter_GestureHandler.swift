//
//  FTShortcutToolPresenter_GestureHandler.swift
//  Noteshelf3
//
//  Created by Sameer on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTShortcutToolPresenter {
    func configurePanGesture() {
        guard let shortcutView = self.shortcutView else {
            return;
        }
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(recognizer:)))
        shortcutView.addGestureRecognizer(pan)
        shortcutView.translatesAutoresizingMaskIntoConstraints = true
        pan.delegate = self
    }
    
    // MARK: - Pan Gesture handling
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
            
        case .began:
            self.isMoving = true
            self.removeSizeEditViewIfNeeded()
            
        case .changed:
            let contentHolderView = recognizer.view;
            let touchMovementPoint = recognizer.location(in: contentHolderView)
            let translation = recognizer.translation(in: contentHolderView)
            let parentView = contentHolderView?.superview;
            
            if self.checkIfViewCanBeMoved(point: recognizer.location(in: parentView),parentView: parentView) {
                recognizer.setTranslation(CGPoint.zero, in: contentHolderView)
                if let recognizedView = recognizer.view, isMoving {
                    let velocity = recognizer.velocity(in: contentHolderView)
                    self.moveView(movingCenter: recognizedView.center, touchPoint: touchMovementPoint, velocity: velocity, translation: translation)
                    recognizer.setTranslation(CGPoint.zero, in: contentHolderView)
                }
            }
            
        case .cancelled,.ended:
            self.viewMovementEnded()
        default:
            break
        }
    }
}

// UIGestureRecognizerDelegate - shouldReceive Touch
extension FTShortcutToolPresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if(self.toolbarVc?.presentedViewController != nil) {
            return false
        }
        return true
    }
}

private extension FTShortcutToolPresenter {
    func checkIfViewCanBeMoved(point: CGPoint,parentView: UIView?) -> Bool {
        if let superview = parentView {
            let restrictByPoint: CGFloat = 10.0
            let superBounds = CGRect(x: superview.bounds.origin.x + restrictByPoint, y: superview.bounds.origin.y + restrictByPoint, width: superview.bounds.size.width - 2*restrictByPoint, height: superview.bounds.size.height - 2*restrictByPoint)
            if (superBounds.contains(point)) {
                return true
            }
        }
        return false
    }
    
    func moveView(movingCenter: CGPoint, touchPoint: CGPoint, velocity: CGPoint, translation: CGPoint) {
        guard let shortcutView = self.shortcutView else {
            return;
        }
        let center = CGPoint(x: shortcutView.center.x + translation.x, y: shortcutView.center.y + translation.y)
        self.updateShortcutViewCenter(center)
        self.updateQuadrant(quadrant: self.quadrantDetector.getQuadrant(for: center))
    }
    
    // MARK: - Gesture movement end handling
    func viewMovementEnded() {
        guard let shortcutView = self.shortcutView else {
            return;
        }
        let placement = self.shortCutQuadrant.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset);
        placement.save()
        let reqCenter = placement.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: toolbarOffset);
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.updateShortcutViewCenter(reqCenter)
        } completion: { [weak self] _ in
            self?.delegate?.didStartPlacementChange()
        }
    }
}
