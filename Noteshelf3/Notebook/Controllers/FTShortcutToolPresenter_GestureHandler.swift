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
            self.hasAddedSlots = false
            self.viewMovementEnded()
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
        FTShortcutPlacement.allCases.forEach { placement in
            addSlotView(for: placement)
        }

        func addSlotView(for placement: FTShortcutPlacement) {
            let slotView = FTSlotView()
            slotView.frame.size = placement.slotSize
            slotView.center = shortcutView.center
            self.parentVC?.view.addSubview(slotView)
            let topCenter = placement.shortcutViewCenter(fotShortcutView: slotView, topOffset: toolbarOffset)
            slotView.center = topCenter // update center
            slotView.tag = placement.slotTag
            slotView.isHighlighted = false
        }
    }

    func removeAllSlots() {
        FTShortcutPlacement.allCases.forEach { placement in
            let tagToSearch = placement.slotTag
            for subview in self.parentVC?.view.subviews ?? [] {
                if subview.tag == tagToSearch {
                    subview.removeFromSuperview()
                }
            }
        }
    }

    func highlightNearstSlotView() {
        guard let parentView = self.parentVC?.view else {
            return
        }
        let currentPlacement = self.shortCutQuadrant.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset)
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
        self.updateQuadrant(quadrant: self.quadrantDetector.getQuadrant(for: center))

        let currentPlacementCenter = self.shortcutViewPlacement.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: self.toolbarOffset)
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
        self.removeAllSlots()
        let placement = self.shortCutQuadrant.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset);
        placement.save()
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else {
                return
            }
            self.shortcutView.transform = .identity
            if placement == .top || placement == .bottom {
                self.shortcutView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            }
            let reqCenter = placement.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: toolbarOffset);
            self.updateShortcutViewCenter(reqCenter)
        } completion: { [weak self] _ in
            self?.delegate?.didStartPlacementChange()
        }
    }
}

class FTSlotView: UIView {
    private let borderWidth: CGFloat = 0.5
    private let cornerRadius: CGFloat = 20.0

    private lazy var borderLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.appColor(.shortcutSlotBorderColor).cgColor
        shapeLayer.lineDashPattern = [4, 4]
        shapeLayer.lineWidth = borderWidth
        return shapeLayer
    }()


    var isHighlighted: Bool = false {
        didSet {
            if isHighlighted {
                self.borderLayer.fillColor = UIColor.appColor(.shortcutSlotHighlightColor).cgColor
                self.borderLayer.lineWidth = 0.0
            } else {
                self.borderLayer.fillColor = UIColor.appColor(.shortcutSlotBgColor).cgColor
                self.borderLayer.lineWidth = borderWidth
            }
        }
    }

    override var frame: CGRect {
        didSet {
            self.updateBorderLayer()
        }
    }

    init() {
        super.init(frame: .zero)
        self.configure()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        self.layer.addSublayer(borderLayer)
        let rect = self.bounds.insetBy(dx: 1, dy: 1)
        self.addVisualEffectBlur(cornerRadius: 16.0, frameToBlur: rect)
    }

    private func updateBorderLayer() {
        self.borderLayer.frame = self.bounds
        self.borderLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.borderLayer.layoutIfNeeded()
        self.layoutIfNeeded()
    }
}
