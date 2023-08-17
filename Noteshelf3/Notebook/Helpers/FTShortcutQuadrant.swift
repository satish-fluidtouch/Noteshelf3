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

    case other

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
        case .other:
            break
        }
        return placement
    }
}
