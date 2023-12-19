//
//  FTCoverDataSource.swift
//  Noteshelf3
//
//  Created by srinivas on 15/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import FTNewNotebook

struct FTCoverDataSource {
    public static let shared = FTCoverDataSource()
    
    public func fetchCoverItems() -> [FTCoverSectionModel] {
        let themeLibrary = FTThemesLibrary(libraryType: .covers)
        let categoryList = themeLibrary.getCoverCategoryList()
        let list = categoryList
            .filter({ !$0.isRecents() && !$0.isCustom()})
            .map {FTCoverSectionModel(name: $0.categoryName, covers: $0.themes, imageName: $0.coverVariant_imageName)}
        return list
    }
    
    func generateCoverTheme(image: UIImage, coverType: FTCoverSelectedType, shouldSave: Bool, isDiary: Bool = false) -> FTThemeable? {
        let themeLibrary = FTThemesLibrary(libraryType: .covers)
        let info = FTCustomCoverThemeInfo(title: "Untitled".localized, isCustom: coverType == .custom, shouldSave: shouldSave, isDiary: isDiary)
        let coverInfo = themeLibrary.generateCoverTheme(fromImage: image, coverThemeInfo: info)
        if let url = coverInfo.url {
            let cover = FTCoverTheme(url: url)
            cover.isCustom = (coverType == .custom)
            cover.hasCover = !(coverType == .noCover)
            return cover
        }
        return nil
    }

    public func getRecents() -> [FTCoverThemeModel] {
        let themeLibrary = FTThemesLibrary(libraryType: .covers)
        let categoryList = themeLibrary.getCoverCategoryList()
        let list = categoryList
            .filter({$0.isCustom()})
            .reversed()
            .flatMap { $0.themes.prefix(10) }
            .map {FTCoverThemeModel(name: $0.displayName, themeable: $0)}
        return list
    }

    func fetchPreviousSelectedCoverTheme() -> FTThemeable {
        return FTThemesLibrary(libraryType: .covers).getDefaultTheme(defaultMode: .basic)
    }
}
