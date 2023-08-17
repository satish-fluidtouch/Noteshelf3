//
//  FTPenTypeInfoModel.swift
//  Noteshelf3
//
//  Created by Narayana on 18/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTRackInfoModel: Codable {
    let version: String
    var pilotPen: FTPilotPen
    var caligraphyPen: FTCaligraphyPen
    var pen: FTPen
    var pencil: FTPencil

    var flatHighlighter: FTFlatHighlighter
    var highlighter: FTHighlighter

    var shapeInfo: FTShapeTypeInfo
    let presenterInfo: FTPresenterTypeInfo

    let defaultPresetColors: [String]
    var currentPresetColors: [String]

    let defaultHighlighterPresetColors: [String]
    var currentHighlighterPresetColors: [String]

    var lastSelectedPenType: Int
    var lastSelectedHighlighterType: Int
}

struct FTPilotPen: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

struct FTCaligraphyPen: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

struct FTPen: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

struct FTPencil: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

struct FTFlatHighlighter: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

struct FTHighlighter: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

public struct FTFavoriteColor: Codable {
    var color: String
    var isSelected: Bool
}

public struct FTFavoriteSize: Codable {
    var size: CGFloat
    var isSelected: Bool
}

struct FTShapeTypeInfo: Codable {
    var favouriteColors: [FTFavoriteColor]
    var favouriteSizes: [FTFavoriteSize]

    var selectedColor: String? {
        return self.favouriteColors.first(where: { $0.isSelected})?.color
    }

    var selectedSize: CGFloat? {
        return self.favouriteSizes.first(where: { $0.isSelected })?.size
    }
}

public struct FTFavoriteShape: Codable {
    var shape: Int
    var isSelected: Bool
}

struct FTPresenterTypeInfo: Codable {
    let pointerColors: [FTFavoriteColor]
    let penColors: [FTFavoriteColor]
    let types: [FTPresenterModel]
}

struct FTPresenterModel: Codable {
    let type: Int
    let isSelected: Bool
}
