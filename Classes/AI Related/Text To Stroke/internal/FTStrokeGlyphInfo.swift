//
//  FTStrokeGlyphInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 27/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTStrokeGlyphInfo: Codable {
    let name: String
    let width,lsb,rsb: CGFloat
    let x,y: CGFloat

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case width = "Width"
        case lsb = "LSB"
        case rsb = "RSB"
        case x = "X"
        case y = "Y"
    }
    
    private init(name: String,width: CGFloat,lsb: CGFloat,rsb: CGFloat,x: CGFloat,y: CGFloat) {
        self.name = name;
        self.width = width;
        self.y = y;
        self.x = x;
        self.rsb = rsb;
        self.lsb = lsb;
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
        width = values.decodeCGFloat(forKey: .width)
        lsb = values.decodeCGFloat(forKey: .lsb)
        rsb = values.decodeCGFloat(forKey: .rsb)
        x = values.decodeCGFloat(forKey: .x)
        y = values.decodeCGFloat(forKey: .y)
    }
    
    func scaledInfo(_ scale: CGFloat) -> FTStrokeGlyphInfo {
        return FTStrokeGlyphInfo(name: self.name
                            , width: self.width * scale
                            , lsb: self.lsb * scale
                            , rsb: self.rsb * scale
                            , x: self.x * scale
                            , y: self.y * scale)
    }
    
    var fontWidth: CGFloat {
        return width - lsb - rsb;
    }
}

private extension KeyedDecodingContainer {
    func decodeCGFloat(forKey key: KeyedDecodingContainer.Key) -> CGFloat {
        if let value = try? self.decodeIfPresent(String.self, forKey: key) {
            return CGFloat(value.floatValue);
        }
        else if let value = try? self.decodeIfPresent(Float.self, forKey: key) {
            return CGFloat(value);
        }
        return CGFloat(0);
    }
}
