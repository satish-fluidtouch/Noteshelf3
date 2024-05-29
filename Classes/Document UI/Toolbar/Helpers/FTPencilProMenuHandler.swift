//
//  FTPencilProMenuHandler.swift
//  Noteshelf3
//
//  Created by Narayana on 29/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPencilProMenuHandler {
    let center: CGPoint
    let radius: CGFloat
    let menuItemsCount: Int

    private(set) var startAngle: CGFloat = .pi
    private(set) var endAngle: CGFloat = .pi/4
    private let maxItemsCountToShow: Int = 7
    
    init(center: CGPoint, radius: CGFloat, menuItemsCount: Int) {
        self.center = center
        self.radius = radius
        self.menuItemsCount = menuItemsCount
        self.findAnglesIfNeeded()
    }
    
    private func findAnglesIfNeeded() {
        if menuItemsCount < maxItemsCountToShow {
            // start angle
            self.startAngle = .pi - (CGFloat(menuItemsCount) * .pi/24)
            // end angle
            self.endAngle = .pi/4 - (CGFloat(menuItemsCount) * .pi/24)
        }
    }
}
