//
//  FTFavoritePensetDataManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let favoritesPlistName = "FavoritePensets"
private let toMigrateNS2Favorites = "ToMigrateNS2Favorites"

public class FTFavoritePensetDataManager {
    private let fileManager = FileManager.default
    private lazy var resourcePlistUrl: URL = {
        guard let sourcePlistURL = Bundle.main.url(forResource: favoritesPlistName, withExtension: "plist") else {
            fatalError("Programmer error, plist is not available")
        }
        return sourcePlistURL
    }()

    private lazy var plistUrl: URL = {
        let documentURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return documentURL.appendingPathComponent(favoritesPlistName+".plist")
    }()

    init() {
        UserDefaults.standard.register(defaults: [toMigrateNS2Favorites: true])
    }

    func fetchFavorites() -> FTFavoritePensetDataModel {
        var favoriteInfo: FTFavoritePensetDataModel
        do {
            try copyDefaultDataIfNecessary()
            let migratedData = try Data(contentsOf: plistUrl)
            favoriteInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: migratedData)
            favoriteInfo.favorites = [favoriteInfo.favorites.first!]
            if UserDefaults.standard.bool(forKey: toMigrateNS2Favorites) {
                let migrationInfo = self.checkMigrationPossibilityForNS2Favorites()
                if migrationInfo.canMigrate {
                    let ns2Favorites = migrationInfo.favorites
                    favoriteInfo.favorites = self.prepareNS3Favorites(using: ns2Favorites)
                    self.saveFavorites(favoriteInfo)
                }
                UserDefaults.standard.setValue(false, forKey: toMigrateNS2Favorites)
            }
        } catch {
            favoriteInfo = getDefaultFavoriteInfo()
        }
        return favoriteInfo
    }


    func saveFavorites(_ favoriteData: FTFavoritePensetDataModel) {
        do {
            let data = try PropertyListEncoder().encode(favoriteData)
            try data.write(to: plistUrl)
        }
        catch {
            debugLog("Error saving rack data: \(error)")
        }
    }
}

private extension FTFavoritePensetDataManager {
    func getDefaultFavoriteInfo() -> FTFavoritePensetDataModel {
        do {
            let plistData = try Data(contentsOf: resourcePlistUrl)
            return try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: plistData)
        } catch {
            fatalError("Programmer error, unable to fetch default rack data")
        }
    }

    func copyDefaultDataIfNecessary() throws {
        if fileManager.fileExists(atPath: plistUrl.path) == false {
            try fileManager.copyItem(at: resourcePlistUrl, to: plistUrl)
        } else {
            let sourceData = try Data(contentsOf: resourcePlistUrl)
            let currentData = try Data(contentsOf: plistUrl)
            let sourceInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: sourceData)
            let currentInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: currentData)
            if let sourceVersion = Float(sourceInfo.version),
               let currentVersion = Float(currentInfo.version) {
                if sourceVersion > currentVersion {
                    try fileManager.replaceItem(at: plistUrl, withItemAt: resourcePlistUrl, backupItemName: nil, resultingItemURL: nil)
                }
            }
        }
    }

    func checkMigrationPossibilityForNS2Favorites() -> (canMigrate: Bool, favorites:  [[String: Any]]) {
        let ns2RackPlistUrl = FTUtils.ns2ApplicationDocumentsDirectory().appendingPathComponent("FTPenRack_v1.plist")
        if fileManager.fileExists(atPath: ns2RackPlistUrl.path) {
            if let data = try? Data(contentsOf: ns2RackPlistUrl) {
                do {
                    if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                       let favorites = plist["favorites"] as? [[String: Any]], !favorites.isEmpty {
                        return (true, favorites)
                    }
                } catch {
                    debugLog("Error in migration of NS2 favorites to NS3: \(error)")
                    return (false, [])
                }
            }
        }
        return (false, [])
    }

    func prepareNS3Favorites(using ns2Favorites: [[String: Any]]) -> [FTFavoritePenset]  {
        let reqFavorites: [FTFavoritePenset] = ns2Favorites.map { oldFavorite in
            if let type = oldFavorite["Type"] as? Int,
               let color = oldFavorite["Color"] as? String,
               let size = oldFavorite["Size"] as? Int,
               let preciseSize = oldFavorite["PreciseSize"] as? CGFloat {
                return FTFavoritePenset(type: type, color: color, size: CGFloat(size), preciseSize: String(Float(preciseSize)))
            }
            return FTFavoritePenset(type: 0, color: "000000", size: 3, preciseSize: "3.0")
        }
        return reqFavorites
    }
}

