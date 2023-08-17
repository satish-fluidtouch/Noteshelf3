//
//  FTShapeData.swift
//  Noteshelf
//
//  Created by Sameer on 22/03/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTShapeData: Codable {
    var shapeType = FTShapeType.lineStrip.rawValue
    var numberOfSides = 0
    var controlPoints: [CGPoint] = [CGPoint]()
    var strokeOpacity: CGFloat = 1.0

    var shapeSubType: FTShapeType {
        return FTShapeType(rawValue: shapeType) ?? .lineStrip
    }
    var properties: FTShapeProperties?

    enum CodingKeys: String, CodingKey {
        case shapeType
        case numberOfSides
        case controlPoints
        case strokeOpacity
        case properties
    }
    
    init() {
    }
        
    init(with type: Int, sides: Int, strokeOpacity: CGFloat) {
        self.shapeType = type
        self.numberOfSides = sides
        self.strokeOpacity = strokeOpacity
    }
    
    init(data: Data) {
        self.init()
        if let props = try? JSONDecoder().decode(FTShapeData.self, from: data) {
            self.shapeType = props.shapeType
            self.numberOfSides = props.numberOfSides
            self.controlPoints = props.controlPoints
            self.strokeOpacity = props.strokeOpacity
            self.properties = props.properties
        }
    }

    var data: Data {
        do {
            let _data = try JSONEncoder().encode(self)
            return _data
        } catch {
            fatalError("Unable to encode shape Data")
        }
    }
}
