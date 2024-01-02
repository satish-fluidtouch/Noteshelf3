//
//  FTShape.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import SwiftUI

@objc public enum FTShapeType: Int {
    case freeForm
    case line
    case triangle
    case rectangle
    case polygon
    case pentagon
    case ellipse
    case dashLine
    case arrow
    case doubleArrow
    case roundedRect
    case rombus
    case paralalleogram
    case oval
    case star
    case union
    case lineStrip
    case curve
    case none
    
    func getDefaultShape() -> FTShape? {
        var shapeType: FTShape?
        switch self {
        case .rectangle:
            shapeType = FTShapeRectangle()
        case .ellipse:
            shapeType = FTShapeEllipse()
        case .triangle:
            shapeType = FTShapeTriangle()
        case .rombus:
            shapeType = FTShapeRombus()
        case .pentagon:
            shapeType = FTShapePentagon()
        case .line :
            shapeType = FTShapeLine()
        case .dashLine :
            shapeType = FTShapeDashLine()
        case .arrow:
            shapeType = FTShapeArrow()
        case .doubleArrow:
            shapeType = FTShapeDoubleArrow()
        case .paralalleogram:
            shapeType = FTShapeParallelogram()
        case .polygon:
            shapeType = FTShapePolygon()
        case .curve:
            shapeType = FTShapeCurve()
        default:
            shapeType = FTShapeLineStrip()
        }
        return shapeType;
    }
    
    func shapeSides() -> Int {
        var sides = 0
        switch self {
        case .triangle:
            sides = 3
        case .rectangle:
            sides = 4
        case .pentagon:
            sides = 5
        default:
            sides = 0
        }
        return sides
    }

    func getShapeName() -> String {
        var shapeImageName = ""
        switch self {
        case .rectangle:
            shapeImageName = "rectangle"
        case .triangle:
            shapeImageName = "triangle"
        case .ellipse:
            shapeImageName = "circle"
        case .roundedRect:
            shapeImageName = "roundedrect"
        case .line:
            shapeImageName = "line"
        case .arrow:
            shapeImageName = "arrow"
        case .freeForm:
            shapeImageName = "freeform"
        case .doubleArrow:
            shapeImageName = "doublearrow"
        case .dashLine:
            shapeImageName = "dashline"
        case .rombus:
            shapeImageName = "rombus"
        case .paralalleogram:
            shapeImageName = "paralellogram"
        case .oval:
            shapeImageName = "oval"
        case .pentagon:
            shapeImageName = "pentagon"
        case .star:
            shapeImageName = "star"
        case .union:
            shapeImageName = "union"
        default:
            shapeImageName = "rectangle"
        }
        return shapeImageName
    }

    func getMiniShapeName() -> String {
        var shapeImageName = ""
        switch self {
        case .rectangle:
            shapeImageName = "rectangle_mini"
        case .triangle:
            shapeImageName = "triangle_mini"
        case .ellipse:
            shapeImageName = "circle_mini"
        case .roundedRect:
            shapeImageName = "roundedrect_mini"
        case .line:
            shapeImageName = "line_mini"
        case .arrow:
            shapeImageName = "arrow_mini"
        case .freeForm:
            shapeImageName = "freeform_mini"
        case .doubleArrow:
            shapeImageName = "doublearrow_mini"
        case .dashLine:
            shapeImageName = "dashline_mini"
        case .rombus:
            shapeImageName = "rombus_mini"
        case .paralalleogram:
            shapeImageName = "paralellogram_mini"
        case .oval:
            shapeImageName = "oval_mini"
        case .pentagon:
            shapeImageName = "pentagon_mini"
        case .star:
            shapeImageName = "star_mini"
        case .union:
            shapeImageName = "union_mini"
        default:
            shapeImageName = "rectangle_mini"
        }
        return shapeImageName
    }

    func saveSelection() {
        UserDefaults.standard.shapeTypeRawValue = self.rawValue
    }

    static func savedShapeType() -> FTShapeType {
        return FTShapeType(rawValue: UserDefaults.standard.shapeTypeRawValue) ?? .freeForm
    }
}

@objc protocol FTShape: NSObjectProtocol {
    var vertices: [CGPoint] { get set }
    var isClosedShape: Bool {get set}
    var numberOfSides: CGFloat {get set}
    func drawingPoints(scale: CGFloat) -> [CGPoint]
    func validate()
    func type() -> FTShapeType
    func shapeName() -> String
    func controlPoints() -> [CGPoint]
    @objc optional func shapeControlPoints(in view: UIView, for scale: CGFloat) -> [CGPoint]
    func isPerfectShape() -> Bool
    @objc optional func isLineType() -> Bool
    @objc optional func knobControlPoints() -> [CGPoint]
}
