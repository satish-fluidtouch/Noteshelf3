//
//  FTShortcutQuadrant.swift
//  Noteshelf3
//
//  Created by Narayana on 14/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTShortcutQuadrant: String {
    case topLeft
    case left
    case bottomLeft

    case topRight
    case right
    case bottomRight

    case top
    case bottom
    case center

    func convertToPlacementIfPossible() -> FTShortcutPlacement? {
        var placement: FTShortcutPlacement?
        switch self {
        case .topLeft:
            placement = .topLeft
        case .left:
            placement = .centerLeft
        case .bottomLeft:
            placement = .bottomLeft
        case .topRight:
            placement = .topRight
        case .right:
            placement = .centerRight
        case .bottomRight:
            placement = .bottomRight
        case .top:
            placement = .top
        case .bottom:
            placement = .bottom
            break
        case .center:
            break
        }
        return placement
    }
}

extension FTShortcutQuadrant {
    func nearestPlacement(for shortcutView: UIView,topOffset: CGFloat) -> FTShortcutPlacement {
        var reqPlacement: FTShortcutPlacement = .topLeft

        if self == .topLeft {
            reqPlacement = .topLeft
        } else if self == .left {
            reqPlacement = .centerLeft
        } else if self == .bottomLeft {
            reqPlacement = .bottomLeft
        } else if self == .topRight {
            reqPlacement = .topRight
        } else if self == .right {
            reqPlacement = .centerRight
        } else if self == .bottomRight {
            reqPlacement = .bottomRight
        } else if self == .top {
            reqPlacement = .top
        } else if self == .bottom {
            reqPlacement = .bottom
        } else {
            let movingCenter: CGPoint = shortcutView.center

            let topLeftCenter = FTShortcutPlacement.topLeft.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);
            let leftCenter = FTShortcutPlacement.centerLeft.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);
            let bottomLeftCenter = FTShortcutPlacement.bottomLeft.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);

            
            let topRightCenter = FTShortcutPlacement.topRight.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);
            let rightCenter = FTShortcutPlacement.centerRight.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);
            let bottomRightCenter = FTShortcutPlacement.bottomRight.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: topOffset);

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
