//
//  FTPreviewShape.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

public struct FTPreviewShape: Shape {
    public var leftCornerRadius: CGFloat;
    public var rightCornerRadius: CGFloat;
    
    public init(raidus: CGFloat) {
        leftCornerRadius = raidus;
        rightCornerRadius = raidus;
    }

    public init(leftRaidus: CGFloat
         ,rightRadius: CGFloat) {
        leftCornerRadius = leftRaidus;
        rightCornerRadius = rightRadius;
    }

    public func path(in rect: CGRect) -> Path {
        Path { path in
            let frame = rect;
           
            path.move(to: CGPoint(x: frame.minX+leftCornerRadius, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.maxX-rightCornerRadius, y: frame.minY))
            
            path.addQuadCurve(to: CGPoint(x: frame.maxX, y: frame.minY+rightCornerRadius),
                              control: CGPoint(x: frame.maxX, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY-rightCornerRadius))

            path.addQuadCurve(to: CGPoint(x: frame.maxX-rightCornerRadius, y: frame.maxY),
                              control: CGPoint(x: frame.maxX, y: frame.maxY))
            path.addLine(to: CGPoint(x: frame.minX+leftCornerRadius, y: frame.maxY))

            path.addQuadCurve(to: CGPoint(x: frame.minX, y: frame.maxY-leftCornerRadius),
                              control: CGPoint(x: frame.minX, y: frame.maxY))
            path.addLine(to: CGPoint(x: frame.minX, y: frame.minY+leftCornerRadius))

            path.addQuadCurve(to: CGPoint(x: frame.minX+leftCornerRadius, y: frame.minY),
                              control: CGPoint(x: frame.minX, y: frame.minY))

            path.closeSubpath();
        }
    }
}
