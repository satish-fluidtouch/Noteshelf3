//
//  FTPenSizeModel.swift
//  Noteshelf3
//
//  Created by Narayana on 30/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public class FTPenSizeModel: NSObject {
    var size: CGFloat
    var isSelected: Bool

    init(size: CGFloat, isSelected: Bool = false) {
        self.size = size
        self.isSelected = isSelected
    }
}

enum FavoriteSizePosition: Int, CaseIterable {
    case first = 0
    case second
    case third

    static func getPosition(index: Int) -> FavoriteSizePosition {
        var position = FavoriteSizePosition.first
        if index == 1 {
            position = .second
        } else if index == 2 {
            position = .third
        } 
        return position
    }

}
