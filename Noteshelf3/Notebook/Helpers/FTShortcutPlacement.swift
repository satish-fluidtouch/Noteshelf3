//
//  FTShortcutPlacement.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTShortcutPlacement: String, CaseIterable {
    case topLeft
    case centerLeft
    case bottomLeft
    case topRight
    case centerRight
    case bottomRight
    case top
    case bottom

    static var zoomModePlacements: [FTShortcutPlacement] {
        return [.top, .centerLeft, .centerRight, .bottom]
    }

    var slotTag: Int {
        let tag: Int
        switch self {
        case .topLeft:
            tag = 9000
        case .centerLeft:
            tag = 9001
        case .bottomLeft:
            tag = 9002
        case .topRight:
            tag = 9003
        case .centerRight:
            tag = 9004
        case .bottomRight:
            tag = 9005
        case .top:
            tag = 9006
        case .bottom:
            tag = 9007
        }
        return tag
    }

    var slotSize: CGSize {
        var size: CGSize = CGSize(width: 38.0, height: 124.0)
        if self.isHorizantalPlacement() {
            size = CGSize(width: 124.0, height: 38.0)
        }
        return size
    }

    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: "FTShortcutPlacement")
        UserDefaults.standard.synchronize()
    }

    static func getSavedPlacement() -> FTShortcutPlacement {
        if UIDevice.current.isIphone() {
            return .top
        }
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

    func isRightPlacement() -> Bool {
        var isRight = false
        if self == .topRight || self == .centerRight || self == .bottomRight {
            isRight = true
        }
        return isRight
    }

    func isHorizantalPlacement() -> Bool {
        var isHorizantal = false
        if self == .top || self == .bottom {
            isHorizantal = true
        }
        return isHorizantal
    }

    func isBottomPlacement() -> Bool {
        var isBottom: Bool = false
        if self == .bottomLeft || self == .bottom || self == .bottomRight {
            isBottom = true
        }
        return isBottom
    }
}

private var offset: CGFloat = 8.0;
extension FTShortcutPlacement {
    func slotCenter(forSlotView slotView: UIView, topOffset: CGFloat, zoomModeInfo: FTZoomModeInfo) -> CGPoint {
        var center: CGPoint = .zero

        if zoomModeInfo.isEnabled {
            guard let superViewFrame = slotView.superview?.bounds else {
                return .zero
            }
            let frame = CGRect(x: superViewFrame.origin.x,
                               y: superViewFrame.origin.y + topOffset,
                               width: superViewFrame.size.width,
                               height: superViewFrame.size.height - topOffset - zoomModeInfo.overlayHeight)

            let size = slotView.frame.size

            let minY = frame.minY
            let maxX = frame.maxX
            let midY = frame.midY

            if FTShortcutPlacement.zoomModePlacements.contains(self) {
                if self == .centerLeft {
                    center = CGPoint(x: size.width/2.0 + offset, y: midY)
                    if center.y < minY + size.height/2.0 {
                        center.y = minY + size.height/2.0
                    }
                } else if self == .centerRight {
                    center = CGPoint(x: maxX - size.width/2.0 - offset, y: midY)
                    if center.y < minY + size.height/2.0 {
                        center.y = minY + size.height/2.0
                    }
                }
            }
        }

        if center == .zero {
            center = self.placementCenter(forShortcutView: slotView, topOffset: topOffset, zoomModeInfo: zoomModeInfo)
        }
        return center
    }

    func placementCenter(forShortcutView shorcutView: UIView,topOffset: CGFloat, zoomModeInfo: FTZoomModeInfo) -> CGPoint {
        guard let superViewFrame = shorcutView.superview?.bounds else {
            return .zero
        }
        let frame = CGRect(x: superViewFrame.origin.x,
                                               y: superViewFrame.origin.y + topOffset,
                                               width: superViewFrame.size.width,
                                               height: superViewFrame.size.height - topOffset)

        let size = shorcutView.frame.size
        
        let minY = frame.minY
        let maxX = frame.maxX
        let maxY = frame.maxY
        let midY = frame.midY
        let midX = frame.midX

        var center: CGPoint = .zero
        var bottomOffset: CGFloat = 0.0
        if self.isBottomPlacement() && !zoomModeInfo.isEnabled {
            if let window = UIApplication.shared.keyWindow {
                bottomOffset = window.safeAreaInsets.bottom
            }
        }

        switch self {
        case .top:
            center = CGPoint(x: midX, y: minY + size.height/2.0)
        case .centerLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: midY)
        case .centerRight:
            center = CGPoint(x: maxX - size.width/2.0 - offset, y: midY)
        case .bottom:
            center = CGPoint(x: midX, y: maxY - offset - size.height/2.0 - bottomOffset)
        case .topLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: minY + size.height/2.0)
        case .topRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: minY + size.height/2.0)
        case .bottomLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: maxY - offset - size.height/2.0 - bottomOffset)
        case .bottomRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: maxY - offset - size.height/2.0 - bottomOffset)
        }

        if zoomModeInfo.isEnabled {
            if self == .centerLeft || self == .centerRight {
                let zoomModeCenterY = maxY - zoomModeInfo.overlayHeight - offset - size.height/2.0
                if center.y > zoomModeCenterY {
                    center.y = zoomModeCenterY
                }
                if center.y < minY + size.height/2.0 {
                    center.y = minY + size.height/2.0
                }
            } else if self == .bottomLeft || self == .bottomRight {
                center.y = max(center.y - (zoomModeInfo.overlayHeight + offset), minY + size.height/2.0)
            } else if self == .bottom {
                center.y -= (zoomModeInfo.overlayHeight + offset)
            }
        }
        return center
    }

    static func nearestPlacement(for shortcutView: UIView,topOffset: CGFloat,in parentView: UIView) -> FTShortcutPlacement {
        var reqPlacement: FTShortcutPlacement = .topLeft
        let movingCenter: CGPoint = shortcutView.center

        let filteredViews = parentView.subviews.compactMap { $0 as? FTSlotView }
        let slotsAndCenters = Dictionary(uniqueKeysWithValues: filteredViews.map { ($0, $0.center) })

        var nearestView: FTSlotView?
        var minDistance: CGFloat = .greatestFiniteMagnitude

        for (view, center) in slotsAndCenters {
            let distance = center.distance(to: movingCenter)
            if distance < minDistance {
                minDistance = distance
                nearestView = view
            }
        }
        if let nearstSlot = nearestView {
            if let matchingPlacement = FTShortcutPlacement.allCases.first(where: { $0.slotTag == nearstSlot.tag }) {
                reqPlacement = matchingPlacement
            }
        }
        return reqPlacement
    }
}
