//
//  FTTemplateModel.swift
//  NS3
//
//  Created by Narayana on 19/04/22.
//

import UIKit
import SwiftUI
import FTNewNotebook

class FTTemplateGridModel: Equatable {
    let image: UIImage
    let title: String
    var color: String

    init(title: String, image: UIImage, color: String) {
        self.title = title
        self.image = image
        self.color = color
    }

    static func == (lhs: FTTemplateGridModel, rhs: FTTemplateGridModel) -> Bool {
        return lhs.title == rhs.title && lhs.image == rhs.image && lhs.color == rhs.color
    }
}
// swiftlint:enable all

enum FTTemplateDisplayType: String {
    case all
    case featured
}

class FTFeaturedTemplateCategory: NSObject {
    var themeSections = [FTTemplateSection]()
}

class FTAllTemplateCategory: NSObject {
    var themeCategories = [FTTemplateCategory]()
}

public class FTTemplateCategory: NSObject {
    public var categoryName: String!
    public var sections = [FTTemplateSection]()

    public func isCustomCategory() -> Bool {
        if self.categoryName.lowercased() == "custom" {
            return true
        }
        return false
    }

    public func isFavoritesCategory() -> Bool {
        if self.categoryName.lowercased() == "favorites" {
            return true
        }
        return false
    }

    public func isRecentsCategory() -> Bool {
        if self.categoryName.lowercased() == "recents" {
            return true
        }
        return false
    }
}

public class FTTemplateSection: NSObject {
    public var sectionName: String!
    public var themes = [FTThemeable]()
}

// This is exclusively used for basic papers
class FTBasicThemeCategory: NSObject {
    var categoryName: String!
    var themes = [FTThemeable]()
    var customizations: FTCategoryCustomization?
    var isDownloaded: Bool = false

    func getDefaultLineHeight() -> FTLineType {
        guard let defaultLineType = self.customizations?.lineTypes.first(where: {$0.lineType.rawValue.contains("Standard")}) else {
            fatalError("Failed to fetch default line type")
        }
        return defaultLineType
    }

    func getDefaultTemplateColor() -> FTThemeColors {
        let colorData = self.customizations?.color_variants.first
        guard let defaultColor =  colorData?.colors.first(where: {$0.colorHex == "#FFFFFF-1.0"}) else {
            fatalError("Failed to fetch default color")
        }
        return defaultColor
    }

    static func getCustomLineColorHex(bgHex: String) -> String {
        let uicolor = UIColor(hexString: bgHex)
        var lineColorHex = "#FFFFFF-0.30"
        if (uicolor.isLightTemplateColor()) {
            lineColorHex = "#0000-0.20"
        }
        return lineColorHex
    }
}
