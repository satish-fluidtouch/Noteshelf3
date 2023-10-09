//
//  FTShortcutToolPresenter_GestureHandler.swift
//  Noteshelf3
//
//  Created by Sameer on 13/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTShortcutToolPresenter {
    func configurePanGesture() {
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
            self.removeSizeEditViewController()
            
        case .changed:
            let contentHolderView = recognizer.view
            let parentView = contentHolderView?.superview
            let touchMovementPoint = recognizer.location(in: parentView)
            let translation = recognizer.translation(in: parentView)

            if self.checkIfViewCanBeMoved(point: recognizer.location(in: parentView),parentView: parentView) {
                recognizer.setTranslation(CGPoint.zero, in: parentView)
                if let recognizedView = recognizer.view, isMoving {
                    let velocity = recognizer.velocity(in: parentView)
                    self.moveView(movingCenter: recognizedView.center, touchPoint: touchMovementPoint, velocity: velocity, translation: translation)
                    recognizer.setTranslation(CGPoint.zero, in: parentView)
                }
            }
            
        case .cancelled,.ended:
            if self.hasAddedSlots {
                self.hasAddedSlots = false
                self.viewMovementEnded()
            }
        default:
            break
        }
    }
}

// UIGestureRecognizerDelegate - shouldReceive Touch
extension FTShortcutToolPresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if(self.toolbarVc.presentedViewController != nil) {
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

    func addSlots() {
        if let parentView = self.parentVC?.view {
            var placements: [FTShortcutPlacement] = FTShortcutPlacement.allCases
            if self.zoomModeInfo.isEnabled {
                placements = FTShortcutPlacement.zoomModePlacements
            }
            placements.forEach { placement in
                addSlotView(for: placement)
            }
            shortcutView.superview?.bringSubviewToFront(shortcutView)

            func addSlotView(for placement: FTShortcutPlacement) {
                let slotView = FTSlotVisualEffectView()
                slotView.stylePanel()
                slotView.frame.size = placement.slotSize
                slotView.center = shortcutView.center
                parentView.addSubview(slotView)
                slotView.alpha = 0.0
                let reqCenter = placement.slotCenter(forSlotView: slotView, topOffset: toolbarOffset, zoomModeInfo: self.zoomModeInfo)
                slotView.center = reqCenter
                slotView.tag = placement.slotTag
                slotView.layer.cornerRadius = 19.0
                slotView.clipsToBounds = true
                UIView.animate(withDuration: animDuration) {
                    slotView.alpha = 1.0
                }
            }
        }
    }

    func removeAllSlots() {
        var reqSlotViews: [UIView] = []
        FTShortcutPlacement.allCases.forEach { placement in
            for subview in self.parentVC?.view.subviews ?? [] {
                if subview.tag == placement.slotTag {
                    reqSlotViews.append(subview)
                }
            }
        }
        reqSlotViews.forEach { slotView in
            UIView.animate(withDuration: animDuration, delay: 0.1) {
                slotView.alpha = 0.0
            } completion: { _ in
                slotView.removeFromSuperview()
            }
        }
    }

    func highlightNearstSlotView() {
        guard let parentView = self.parentVC?.view else {
            return
        }
        let currentPlacement = FTShortcutPlacement.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset, in: parentView)

        FTShortcutPlacement.allCases.forEach { placement in
            let tagToSearch = placement.slotTag
            for subview in parentView.subviews {
                if let dashedBorderView = subview as? FTSlotVisualEffectView {
                    if dashedBorderView.tag == currentPlacement.slotTag {
                        if !dashedBorderView.isHighlighted {
                            dashedBorderView.isHighlighted = true
                        }
                    } else if dashedBorderView.tag == tagToSearch {
                        if dashedBorderView.isHighlighted {
                            dashedBorderView.isHighlighted = false
                        }
                    }
                }
            }
        }
    }

    func moveView(movingCenter: CGPoint, touchPoint: CGPoint, velocity: CGPoint, translation: CGPoint) {
        let center = CGPoint(x: shortcutView.center.x + translation.x, y: shortcutView.center.y + translation.y)
        self.updateShortcutViewCenter(center)

        let currentPlacementCenter = self.shortcutViewPlacement.placementCenter(forShortcutView: shortcutView, topOffset: self.toolbarOffset, zoomModeInfo: self.zoomModeInfo)
        if abs(center.x - currentPlacementCenter.x) > 10.0 || abs(center.y - currentPlacementCenter.y) > 10.0 {
            if !self.hasAddedSlots {
                self.addSlots()
                self.hasAddedSlots = true
            }
        }
        self.highlightNearstSlotView()
    }
    
    // MARK: - Gesture movement end handling
    func viewMovementEnded() {
        var placement: FTShortcutPlacement = .topLeft
        if let parent = self.parentVC?.view {
            placement = FTShortcutPlacement.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset, in: parent)
            placement.save()
        }
        UIView.animate(withDuration: animDuration) { [weak self] in
            guard let self else {
                return
            }
            self.shortcutView.transform = .identity
            if placement == .top || placement == .bottom {
                self.shortcutView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            }
            let reqCenter = placement.slotCenter(forSlotView: shortcutView, topOffset: toolbarOffset, zoomModeInfo: self.zoomModeInfo)
            self.updateShortcutViewCenter(reqCenter)
            self.removeAllSlots()
        } completion: { [weak self] _ in
            guard let self else {
                return
            }
            if self.zoomModeInfo.isEnabled {
                self.shortcutZoomMode = .manual
            } 
        }
    }
}

class FTSlotVisualEffectView: UIVisualEffectView {
    private let cornerRadius: CGFloat = 19.0
    private let bgColor = UIColor.appColor(.shortcutSlotBgColor)
    private let borderView = UIView()

    override var frame: CGRect {
        didSet {
            let borderViewFrame =  self.contentView.frame
            self.borderView.frame = borderViewFrame
            self.borderView.layer.cornerRadius = cornerRadius
        }
    }

    var isHighlighted: Bool = false {
        didSet {
            if isHighlighted {
                self.borderView.backgroundColor = UIColor.appColor(.shortcutSlotHighlightColor)
                self.borderView.layer.borderWidth = 1.5
                self.borderView.layer.borderColor = UIColor.appColor(.shortcutSlotHighlightBorderColor).cgColor
            } else {
                self.borderView.backgroundColor = bgColor
                self.borderView.layer.borderWidth = 1.0
                self.borderView.layer.borderColor = UIColor.appColor(.shortcutSlotBorderColor).cgColor
            }
        }
    }

    func stylePanel() {
        let blurEffect = UIBlurEffect(style: .regular)
        self.effect = blurEffect
        self.backgroundColor = .clear
        self.layer.cornerRadius = cornerRadius

        // add border view
        let borderViewFrame = self.contentView.frame
        self.borderView.frame = borderViewFrame
        self.borderView.backgroundColor = bgColor
        self.borderView.layer.cornerRadius = cornerRadius
        self.contentView.addSubview(borderView)
        self.layoutIfNeeded()
        self.isHighlighted = false
    }
}

class FTZoomModeInfo {
    private(set) var isEnabled: Bool = false
    private(set) var overlayHeight: CGFloat = 0.0

    init(isEnabled: Bool = false, overlayHeight: CGFloat = 0.0) {
        self.isEnabled = isEnabled
        self.overlayHeight = overlayHeight
    }
}
