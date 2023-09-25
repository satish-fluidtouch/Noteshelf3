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
    func shortcutViewCenter(fotShortcutView shorcutView: UIView,topOffset: CGFloat) -> CGPoint {
        guard let frame = shorcutView.superview?.frame else {
            return .zero;
        }
        let size = shorcutView.frame.size;
        
        let minY = frame.minY
        let maxX = frame.maxX
        let maxY = frame.maxY
        let midY = frame.midY
        let midX = frame.midX

        var center: CGPoint = .zero
        var bottomOffset: CGFloat = 0.0
        if self.isBottomPlacement() {
            if let window = UIApplication.shared.keyWindow {
                bottomOffset = window.safeAreaInsets.bottom
            }
        }

        switch self {
        case .centerLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: midY)
        case .centerRight:
            center = CGPoint(x: maxX - size.width/2.0 - offset, y: midY)
        case .topLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: minY + offset + topOffset + size.height/2.0)
        case .bottomLeft:
            center = CGPoint(x: size.width/2.0 + offset, y: maxY - (2*offset) - size.height/2.0 - bottomOffset)
        case .topRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: minY + offset + topOffset + size.height/2.0)
        case .bottomRight:
            center = CGPoint(x: maxX - offset - size.width/2.0, y: maxY - (2*offset) - size.height/2.0 - bottomOffset)
        case .top:
            center = CGPoint(x: midX, y: minY + topOffset + size.height/2.0)
        case .bottom:
            center = CGPoint(x: midX, y: maxY - offset - size.height/2.0 - bottomOffset)
        }
        return center
    }
}
