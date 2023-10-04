//
//  FTShortcutPlacement.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

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

private var offset: CGFloat = 8.0;
extension FTShortcutPlacement {
    func shortcutViewCenter(fotShortcutView shorcutView: UIView,topOffset: CGFloat) -> CGPoint {
        guard let frame = shorcutView.superview?.frame else {
            return .zero;
        }
        let size = shorcutView.frame.size;
        
        let minY = frame.minY
        let maxX = frame.maxX
        let maxY = frame.maxY
        let midY = frame.midY

        var center: CGPoint = .zero

        switch self {
        case .centerLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: midY)
        case .centerRight:
            center = CGPoint(x: maxX - size.width/2.0 - offset, y: midY)
        case .topLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: minY + offset + topOffset + size.height/2.0)
        case .bottomLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: maxY - offset - size.height/2.0)
        case .topRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: minY + offset + topOffset + size.height/2.0)
        case .bottomRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: maxY - offset - size.height/2.0)
        }
        return center
    }

}
