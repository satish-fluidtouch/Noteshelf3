//
//  Extensions.swift
//  FTNewNotebook
//
//  Created by Narayana on 15/03/23.
//

import CoreGraphics

 extension CGSize {
    static func scale(_ size : CGSize, _ scale: CGFloat) -> CGSize {
        var p = size
        p.scale(scale: scale)
        return p
    }

    mutating func scale(scale : CGFloat) {
        self.width *= scale
        self.height *= scale
    }
}

extension CGPoint {
    static func scale(_ point : CGPoint, _ scale: CGFloat) -> CGPoint {
        var p = point
        p.scale(scale: scale)
        return p
    }
    mutating func scale(scale : CGFloat) {
        self.x *= scale
        self.y *= scale
    }

    func scaled(scale: CGFloat) -> CGPoint {
        return CGPoint.scale(self, scale)
    }
}
