//
//  FTShortcutContentHolderView.swift
//  Noteshelf3
//
//  Created by Narayana on 14/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private var offset: CGFloat = 8.0

public class FTShortcutContentHolderView: UIView {
    @IBOutlet public weak var shortcutView: UIView?
    private var toolbarOffset: CGFloat = FTToolbarConfig.Height.regular + offset

     func updateMinOffsetIfNeeded() {
        if UIDevice().isIphone() || self.frame.width < FTToolbarConfig.compactModeThreshold {
            var extraOffset: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = UIApplication.shared.keyWindow {
                    let topSafeAreaInset = window.safeAreaInsets.top
                    if topSafeAreaInset > 0 {
                        extraOffset = topSafeAreaInset
                    }
                }
            }
            self.toolbarOffset = FTToolbarConfig.Height.compact + offset + extraOffset
        } else {
            self.toolbarOffset = FTToolbarConfig.Height.regular + offset
        }
    }

    func shortcutViewCenter(for placement: FTShortcutPlacement, size: CGSize) -> CGPoint {
        let minY = self.frame.minY
        let maxX = self.frame.maxX
        let maxY = self.frame.maxY
        let midY = self.frame.midY

        var center: CGPoint = .zero

        switch placement {
        case .centerLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: midY)
        case .centerRight:
            center = CGPoint(x: maxX - size.width/2.0 - offset, y: midY)
        case .topLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: minY + offset + toolbarOffset + size.height/2.0)
        case .bottomLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: maxY - offset - size.height/2.0)
        case .topRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: minY + offset + toolbarOffset + size.height/2.0)
        case .bottomRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: maxY - offset - size.height/2.0)
        }
        return center
    }

    func fetchNearstPlacement(from center: CGPoint, quadrant: FTShortcutQuadrant, size: CGSize) -> FTShortcutPlacement {
        var reqPlacement: FTShortcutPlacement = .topLeft

        if quadrant == .topLeft {
            reqPlacement = .topLeft
        } else if quadrant == .left {
            reqPlacement = .centerLeft
        } else if quadrant == .bottomLeft {
            reqPlacement = .bottomLeft
        } else if quadrant == .topRight {
            reqPlacement = .topRight
        } else if quadrant == .right {
            reqPlacement = .centerRight
        } else if quadrant == .bottomRight {
            reqPlacement = .bottomRight
        } else {
            let movingCenter: CGPoint = center

            let topLeftCenter = self.shortcutViewCenter(for: .topLeft, size: size)
            let leftCenter = self.shortcutViewCenter(for: .centerLeft, size: size)
            let bottomLeftCenter = self.shortcutViewCenter(for: .bottomLeft, size: size)

            let topRightCenter = self.shortcutViewCenter(for: .topRight, size: size)
            let rightCenter = self.shortcutViewCenter(for: .centerRight, size: size)
            let bottomRightCenter = self.shortcutViewCenter(for: .bottomRight, size: size)

            let distanceBtwCenterToTopLeftCenter: CGFloat = movingCenter.distance(to: topLeftCenter)
            let distanceBtwCenterToLeftCenter: CGFloat = movingCenter.distance(to: leftCenter)
            let distanceBtwCenterToBottomLeftCenter: CGFloat = movingCenter.distance(to: bottomLeftCenter)

            let distanceBtwCenterToTopRightCenter: CGFloat = movingCenter.distance(to: topRightCenter)
            let distanceBtwCenterToRightCenter: CGFloat = movingCenter.distance(to: rightCenter)
            let distanceBtwCenterToBottomRightCenter: CGFloat = movingCenter.distance(to: bottomRightCenter)

            let smallestOfAll: CGFloat = min(distanceBtwCenterToTopLeftCenter, distanceBtwCenterToLeftCenter, distanceBtwCenterToBottomLeftCenter, distanceBtwCenterToTopRightCenter, distanceBtwCenterToRightCenter, distanceBtwCenterToBottomRightCenter)

            if smallestOfAll == distanceBtwCenterToTopLeftCenter {
                reqPlacement = .topLeft
            } else if smallestOfAll == distanceBtwCenterToLeftCenter {
                reqPlacement = .centerLeft
            } else if smallestOfAll == distanceBtwCenterToBottomLeftCenter {
                reqPlacement = .bottomLeft
            } else if smallestOfAll == distanceBtwCenterToTopRightCenter {
                reqPlacement = .topRight
            } else if smallestOfAll == distanceBtwCenterToRightCenter {
                reqPlacement = .centerRight
            } else if smallestOfAll == distanceBtwCenterToBottomRightCenter {
                reqPlacement = .bottomRight
            }
        }

        return reqPlacement
    }
}
