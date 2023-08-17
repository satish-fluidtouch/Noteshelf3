//
//  FTCoverDataModel.swift
//  Noteshelf3
//
//  Created by srinivas on 17/06/22.
//


import UIKit

// For UI
public struct FTCoverSectionModel: Equatable, Identifiable {
    public private(set) var id = UUID()
    public let name: String
    public let variantImageName: String
    public let covers: [FTCoverThemeModel]
    public var sectionType: FTCoverSelectedType = .standard
    
    public init(name: String, covers: [FTThemeable], imageName: String) {
        self.name = name
        self.variantImageName = imageName
        self.covers = covers.map({ theme in
            FTCoverThemeModel(name: theme.displayName, themeable: theme)
        })
    }
}

public struct FTCoverThemeModel: Equatable, Identifiable {
    public static func == (lhs: FTCoverThemeModel, rhs: FTCoverThemeModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public private(set) var id = UUID()
    public var name: String
    public var themeable: FTThemeable

   public init(name: String, themeable: FTThemeable) {
        self.name = name
        self.themeable = themeable
    }
    
    public func thumbnail() -> UIImage? {
        return  themeable.themeThumbnail();
    }
}

enum FTCoverPreviewMode: String {
    case justPreview
    case previewEdit

    var isEditPreviewMode: Bool {
        var status = false
        if self == .previewEdit {
            status = true
        }
        return status
    }
}
