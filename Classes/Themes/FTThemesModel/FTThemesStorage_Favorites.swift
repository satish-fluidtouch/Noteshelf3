//
//  FTThemesStorage_Favorites.swift
//
//  Created by Narayana on 12/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import FTNewNotebook

extension FTThemesStorage {
     func getFavorites() -> [FTTheme] {
        if self.themeType == FTSelectedThemeType.papers {
            let favorites = self.getPaperFavorites()
            return favorites.compactMap({ [weak self] in
                guard let strongSelf = self else { return nil}
                return strongSelf.getFavoritePaperTheme(with: $0)
            })
        } else {
            // There are no favorite covers for now
        }
        return []
    }
    func addToFavorites(_ theme: FTThemeable) {
        self.addPaperToFavorites(theme)
    }

    func removeFromFavorites(_ theme: FTThemeable) {
        var favorites = self.getPaperFavorites()
        var key = theme.displayName
        if !theme.isCustom {
            if let paperTheme = theme as? FTPaperThemeable, let variants = paperTheme.customvariants as? FTSelectedVariants{
                key +=  "_" + variants.getKey()
            }
        }
        if let index = favorites.firstIndex(where: { (storableTheme) -> Bool in
            let storableThemeKey = (storableTheme["key"] as? String) ?? ""
            return storableThemeKey == key
        }) {
            favorites.remove(at: index)
            self.savePaperFavorites(favorites)
        }
    }
}

private extension FTThemesStorage {
    private func getFavoritePaperTheme(with theme: [String: Any]) -> FTTheme? {
        if let path = theme["relativePath"] as? String, let fileURL = self.fileURL(from: path) {
            //Fetch selected variants
            var variants: FTSelectedVariants?
            if let custom =  theme["isCustom"] as? String, custom == "0"  {
                variants = fetchSelectedVariants(theme)
            }
            let favTheme = FTTheme.getFavoriteTheme(url: fileURL, variants)
            if let favoriteTheme = favTheme {
                if let isCustom = theme["isCustom"] as? String {
                    favoriteTheme.isCustom = (isCustom == "1") ? true : false
                    if isCustom == "1"{
                        favoriteTheme.displayName = fileURL.lastPathComponent.deletingPathExtension
                    }
                }
                if let isFav = theme["isFavorite"] as? Bool {
                    favoriteTheme.isFavorite = isFav
                }
                return favoriteTheme
            }
        }
        return nil
    }

    private func addPaperToFavorites(_ theme: FTThemeable) {
        var favorites = self.getPaperFavorites()
        guard let paperTheme = theme as? FTPaperThemeable
        else{
            fatalError("Failed to cast theme to type FTPaperThemeable")
        }
        var key = theme.displayName
        if !theme.isCustom {
            // form unqiue key with selected variants for each theme
            let variants = paperTheme.customvariants
            paperTheme.setPaperVariants(variants)
            key += "_" + constructPaperVariantKey(paperTheme.customvariants)
        }

        var favCount = favorites.count
        let index = favorites.firstIndex(where: { (storableTheme) -> Bool in
            let storableThemekey = (storableTheme["key"] as? String) ?? ""
            return storableThemekey == key
        })

        if (index != nil) {
            favorites.remove(at: index!)
            favCount -= 1
        }

        let isCustom = theme.isCustom ? "1" : "0"

        var favDict = [String : Any]()
        favDict = ["relativePath": self.relativeFilePath(of: theme.themeFileURL) as Any, "key": key, "isCustom": isCustom, "isFavorite": true]

        if let variants = paperTheme.customvariants {
            let lineType = variants.lineType
            favDict.updateValue(lineType.dictionaryRepresentation(), forKey: FTVariantType.line.rawValue)

            let deviceType = variants.selectedDevice
            favDict.updateValue(deviceType.dictionaryRepresentation(), forKey: FTVariantType.device.rawValue)

            let colorType = variants.selectedColor
            favDict.updateValue(colorType.dictionaryRepresentation(), forKey: FTVariantType.color.rawValue)

            favDict.updateValue(variants.isLandscape, forKey: "isLand")
        }

        favDict.updateValue(key, forKey: "key")
        favorites.insert(favDict, at: 0)
        self.savePaperFavorites(favorites)
    }

    private func savePaperFavorites(_ dict : [[String:Any]]) {
        let favoritesData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
        if let favData = favoritesData {
            try? favData.write(to: self.favoritesPlistURL)
        }
    }

    private func getPaperFavorites() -> [[String:Any]] {
        let favorites: [[String: Any]]
        let data = try? Data(contentsOf: self.favoritesPlistURL)
        if let data = data, let favData =  try? PropertyListSerialization.propertyList(from: data, format: nil) as? [[String:Any]] {
            favorites = favData.filter({$0["key"] != nil })
        } else {
            favorites = []
        }
        self.savePaperFavorites(favorites)
        return favorites
    }
}
