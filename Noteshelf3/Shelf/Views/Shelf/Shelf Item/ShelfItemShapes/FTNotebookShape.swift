//
//  FTNotebookShape.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI

struct FTNotebookShape: Shape {
    private var leftCornerRadius: CGFloat;
    private var rightCornerRadius: CGFloat;
    
    init(raidus: CGFloat) {
        leftCornerRadius = raidus;
        rightCornerRadius = raidus;
    }

    init(leftRaidus: CGFloat = FTShelfItemProperties.Constants.Notebook.portNBCoverleftCornerRadius
         ,rightRadius: CGFloat = FTShelfItemProperties.Constants.Notebook.portNBCoverRightCornerRadius) {
        leftCornerRadius = leftRaidus;
        rightCornerRadius = rightRadius;
    }

    func path(in rect: CGRect) -> Path {
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
