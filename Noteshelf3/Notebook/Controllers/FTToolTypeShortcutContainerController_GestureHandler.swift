//
//  FTToolTypeShortcutContainerController_GestureHandler.swift
//  Noteshelf3
//
//  Created by Sameer on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTShortcutPlacement: String {
    case topLeft
    case centerLeft
    case bottomLeft
    case topRight
    case centerRight
    case bottomRight

    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: "FTShortcutPlacement")
        UserDefaults.standard.synchronize()
    }

    static func getSavedPlacement() -> FTShortcutPlacement {
        var placement: FTShortcutPlacement = .centerLeft
        if let value = UserDefaults.standard.string(forKey: "FTShortcutPlacement") {
            placement = FTShortcutPlacement(rawValue: value) ?? .centerLeft
        }
        return placement
    }

    func isLeftPlacement() -> Bool {
        var isLeft = false
        if self == .topLeft || self == .centerLeft || self == .bottomLeft {
            isLeft = true
        }
        return isLeft
    }
}


extension FTToolTypeShortcutContainerController {
    func configurePanGesture() {
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(recognizer:)))
        self.shortcutView.addGestureRecognizer(pan)
        self.shortcutView.translatesAutoresizingMaskIntoConstraints = true
        pan.delegate = self
    }
    
    private func checkIfViewCanBeMoved(point: CGPoint) -> Bool {
        if let superview = self.contentHolderView {
            let restrictByPoint: CGFloat = 10.0
            let superBounds = CGRect(x: superview.bounds.origin.x + restrictByPoint, y: superview.bounds.origin.y + restrictByPoint, width: superview.bounds.size.width - 2*restrictByPoint, height: superview.bounds.size.height - 2*restrictByPoint)
            if (superBounds.contains(point)) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Pan Gesture handling
        @objc func handlePan(recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
                
            case .began:
                self.isMoving = true
                self.removeSizeEditViewIfNeeded()

            case .changed:
                let touchMovementPoint = recognizer.location(in: self.contentHolderView)
                let translation = recognizer.translation(in: self.contentHolderView)
                
                if self.checkIfViewCanBeMoved(point: touchMovementPoint) {
                    recognizer.setTranslation(CGPoint.zero, in: self.contentHolderView)
                    if let recognizedView = recognizer.view, isMoving {
                        let velocity = recognizer.velocity(in: self.contentHolderView)
                        self.moveView(movingCenter: recognizedView.center, touchPoint: touchMovementPoint, velocity: velocity, translation: translation)
                        recognizer.setTranslation(CGPoint.zero, in: self.contentHolderView)
                    }
                }
                
            case .cancelled,.ended:
                if nil != recognizer.view {
                    self.viewMovementEnded()
                }
                
            default:
                break
            }
        }
    
    func moveView(movingCenter: CGPoint, touchPoint: CGPoint, velocity: CGPoint, translation: CGPoint) {
        self.panTouchPoint = touchPoint
        let center = CGPoint(x: self.shortcutView.center.x + translation.x, y: self.shortcutView.center.y + translation.y)
        self.updateShortcutViewCenter(center)
        self.updateQuadrant(quadrant: self.quadrantDetector.getQuadrant(for: center))
    }
    
    // MARK: - Gesture movement end handling
    private func viewMovementEnded() {
        let movingCenter = self.shortcutView.center
        let reqSize = self.getShortcutViewSize()

        let placement = self.contentHolderView.fetchNearstPlacement(from: movingCenter, quadrant: self.shortCutQuadrant, size: reqSize)
        let reqCenter = self.contentHolderView.shortcutViewCenter(for: placement, size: reqSize)
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.updateShortcutViewCenter(reqCenter)
        } completion: { [weak self] _ in
            placement.save()
            self?.shortcutViewPlacement = placement
            self?.delegate?.didStartPlacementChange()
        }
    }
}

// UIGestureRecognizerDelegate - shouldReceive Touch
extension FTToolTypeShortcutContainerController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if(self.presentedViewController != nil) {
            return false
        }
        return true
    }
}
