//
//  FTPenShapeModel.swift
//  Noteshelf3
//
//  Created by Narayana on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPenShapeModel: NSObject {
    var shape: FTShapeType
    var isSelected: Bool

    init(shape: FTShapeType, isSelected: Bool = false) {
        self.shape = shape
        self.isSelected = isSelected
    }
}

enum FavoriteShapePosition: Int, CaseIterable {
    case first = 0
    case second
    case third

    static func getPosition(index: Int) -> FavoriteShapePosition {
        var position = FavoriteShapePosition.first
        if index == 1 {
            position = .second
        } else if index == 2 {
            position = .third
        }
        return position
    }
}
