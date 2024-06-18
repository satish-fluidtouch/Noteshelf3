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
            var placements: [FTShortcutPlacement] = FTShortcutPlacement.supportedPlacements
            if self.zoomModeInfo.isEnabled {
                placements = FTShortcutPlacement.zoomModePlacements
            }
            placements.forEach { placement in
                addSlotView(for: placement)
            }
            shortcutView.superview?.bringSubviewToFront(shortcutView)

            func addSlotView(for placement: FTShortcutPlacement) {
                let slotView = FTSlotView()
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
                if let dashedBorderView = subview as? FTSlotView {
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
        var placement: FTShortcutPlacement = .centerLeft
        if let parent = self.parentVC?.view {
            placement = FTShortcutPlacement.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset, in: parent)
            placement.save(activity: self.activity)
        }
        NotificationCenter.default.post(name: NSNotification.Name("ViewMovementEnded"), object: nil)
        UIView.animate(withDuration: animDuration) { [weak self] in
            guard let self else {
                return
            }
            self.shortcutView.transform = .identity
            if !placement.isHorizantalPlacement() {
                self.shortcutView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
            }
            if let favBarVc = self.toolbarVc as? FTFavoriteShortcutViewController {
                favBarVc.handleEndMovement()
            }
            let reqCenter = placement.slotCenter(forSlotView: self.shortcutView, topOffset: self.toolbarOffset, zoomModeInfo: self.zoomModeInfo)
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

class FTSlotView: UIView {
    private let cornerRadius: CGFloat = 19.0
    private let borderView = UIView()
    private let dashedBorder = CAShapeLayer()

    override var frame: CGRect {
        didSet {
            self.updateBorderViewAppearance()
        }
    }

    var isHighlighted: Bool = false {
        didSet {
            self.updateBorderViewAppearance()
        }
    }

    func stylePanel() {
        self.backgroundColor = .clear
        self.layer.cornerRadius = cornerRadius
        self.borderView.frame = self.frame
        self.borderView.layer.cornerRadius = cornerRadius
        self.borderView.layer.addSublayer(dashedBorder)
        self.addSubview(borderView)
        self.layoutIfNeeded()
        self.isHighlighted = false
    }

    private func updateBorderViewAppearance() {
        let width: CGFloat = 1.0
        let borderColor: UIColor
        let backgroundColor: UIColor
        if isHighlighted {
            borderColor = UIColor.appColor(.shortcutSlotHighlightBorderColor)
            backgroundColor = UIColor.appColor(.shortcutSlotHighlightColor)
        } else {
            borderColor = UIColor.appColor(.shortcutSlotBorderColor)
            backgroundColor = UIColor.appColor(.shortcutSlotBgColor)
        }

        self.borderView.frame = self.bounds.insetBy(dx: width, dy: width)
        self.borderView.backgroundColor = backgroundColor
        self.dashedBorder.fillColor = nil
        self.dashedBorder.path = UIBezierPath(roundedRect: self.borderView.bounds, cornerRadius: cornerRadius).cgPath
        self.dashedBorder.lineWidth = width
        self.dashedBorder.strokeColor = borderColor.cgColor
        self.dashedBorder.lineDashPattern = [4, 4]
        self.dashedBorder.shadowColor = UIColor.label.withAlphaComponent(0.12).cgColor
        self.dashedBorder.shadowOpacity = 1.0
        self.dashedBorder.shadowRadius = 2.0
        self.dashedBorder.shadowOffset = CGSize(width: 0, height: 2.0)
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
