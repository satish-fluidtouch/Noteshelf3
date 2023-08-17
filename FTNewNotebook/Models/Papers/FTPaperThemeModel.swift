//
//  FTPaperDataModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 02/03/23.
//

import UIKit

public struct FTPaperThemeModel: Equatable, Identifiable {
    public static func == (lhs: FTPaperThemeModel, rhs: FTPaperThemeModel) -> Bool {
        lhs.id == rhs.id
    }

    public private(set) var id = UUID()
    public var name: String
    public var thumbnail: UIImage
    public var themeable: FTThemeable

   public init(name: String, thumbnail: UIImage, themeable: FTThemeable) {
        self.name = name
        self.thumbnail = thumbnail
        self.themeable = themeable
    }
}
