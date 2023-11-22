//
//  FTFavoritePensetDataManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let favoritesPlistName = "FavoritePensets"

public class FTFavoritePensetDataManager: NSObject {
    private let fileManager = FileManager.default
    static let shared = FTFavoritePensetDataManager()
    private override init() { }

    private lazy var resourcePlistUrl: URL = {
        guard let sourcePlistURL = Bundle.main.url(forResource: favoritesPlistName, withExtension: "plist") else {
            fatalError("Programmer error, plist is not available")
        }
        return sourcePlistURL
    }()

    private lazy var ns3FavoritesUrl: URL = {
        let documentURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return documentURL.appendingPathComponent(favoritesPlistName+".plist")
    }()

    private var ns2FavoritesUrl: URL {
        return FTUtils.ns2ApplicationDocumentsDirectory().appendingPathComponent("FTPenRack_v1.plist")
    }

    func migrateNS2Favorites() {
        let migrationInfo = self.checkMigrationPossibilityForNS2Favorites()
        if migrationInfo.canMigrate {
            let favorites = migrationInfo.favorites
            let ns2Favorites = self.prepareNS3ModelFavorites(using: favorites)
            do {
                var favoriteInfo: FTFavoritePensetDataModel
                if fileManager.fileExists(atPath: ns3FavoritesUrl.path) == false {
                    try fileManager.copyItem(at: resourcePlistUrl, to: ns3FavoritesUrl)
                    let currentData = try Data(contentsOf: ns3FavoritesUrl)
                    favoriteInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: currentData)
                    if !ns2Favorites.isEmpty {
                        favoriteInfo.favorites = [] // To remove default favorites when copied from bundle
                        favoriteInfo.favorites = ns2Favorites
                    }
                } else {
                    let currentData = try Data(contentsOf: ns3FavoritesUrl)
                    favoriteInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: currentData)
                    for ns2Favorite in ns2Favorites {
                        if !favoriteInfo.favorites.contains(where: {
                            $0.color == ns2Favorite.color && $0.type == ns2Favorite.type && $0.size == ns2Favorite.size && $0.preciseSize == ns2Favorite.preciseSize
                        }) {
                            favoriteInfo.favorites.append(ns2Favorite)
                        }
                    }
                 }
                self.saveFavorites(favoriteInfo)
            }
            catch let error {
                debugLog("Error in migrating ns2 favorites - \(error.localizedDescription)")
            }
        }
    }

    func fetchFavorites() -> FTFavoritePensetDataModel {
        var favoriteInfo: FTFavoritePensetDataModel
        do {
            try copyDefaultDataIfNecessary()
            let migratedData = try Data(contentsOf: ns3FavoritesUrl)
            favoriteInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: migratedData)
        } catch {
            favoriteInfo = getDefaultFavoriteInfo()
        }
        return favoriteInfo
    }


    func saveFavorites(_ favoriteData: FTFavoritePensetDataModel) {
        do {
            let data = try PropertyListEncoder().encode(favoriteData)
            try data.write(to: ns3FavoritesUrl)
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
        if fileManager.fileExists(atPath: ns3FavoritesUrl.path) == false {
            try fileManager.copyItem(at: resourcePlistUrl, to: ns3FavoritesUrl)
        } else {
            let sourceData = try Data(contentsOf: resourcePlistUrl)
            let currentData = try Data(contentsOf: ns3FavoritesUrl)
            let sourceInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: sourceData)
            let currentInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: currentData)
            if let sourceVersion = Float(sourceInfo.version),
               let currentVersion = Float(currentInfo.version) {
                if sourceVersion > currentVersion {
                    try fileManager.replaceItem(at: ns3FavoritesUrl, withItemAt: resourcePlistUrl, backupItemName: nil, resultingItemURL: nil)
                }
            }
        }
    }

    func checkMigrationPossibilityForNS2Favorites() -> (canMigrate: Bool, favorites:  [[String: Any]]) {
        if fileManager.fileExists(atPath: ns2FavoritesUrl.path) {
            if let data = try? Data(contentsOf: ns2FavoritesUrl) {
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

    func prepareNS3ModelFavorites(using ns2Favorites: [[String: Any]]) -> [FTFavoritePenInfo]  {
        let reqFavorites: [FTFavoritePenInfo] = ns2Favorites.map { oldFavorite in
            if let type = oldFavorite["Type"] as? Int,
               let color = oldFavorite["Color"] as? String,
               let size = oldFavorite["Size"] as? Int {
                var preciseSize = CGFloat(size)
                if let size = oldFavorite["PreciseSize"] as? CGFloat {
                    preciseSize = size
                }
                return FTFavoritePenInfo(type: type, color: color, size: CGFloat(size), preciseSize: String(Float(preciseSize.roundToDecimal(1))))
            }
            return FTFavoritePenInfo(type: 0, color: "000000", size: 3, preciseSize: "3.0")
        }
        return reqFavorites
    }
}

