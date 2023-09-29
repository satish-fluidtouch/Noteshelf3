//
//  FTFavoritePensetDataManager.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 29/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let favoritesPlistName = "FavoritePensets"

public class FTFavoritePensetDataManager {
    fileprivate let plistUrl: URL
    static let shared = FTFavoritePensetDataManager()

    private init() {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        plistUrl = documentURL.appendingPathComponent(favoritesPlistName+".plist")
    }

    func fetchFavorites() -> FTFavoritePensetDataModel {
        let favoriteInfo: FTFavoritePensetDataModel
        do {
            try migrateRackDataIfNecessary()
            let migratedData = try Data(contentsOf: plistUrl)
            favoriteInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: migratedData)
        } catch {
            favoriteInfo = getDefaultFavoriteInfo()
        }
        return favoriteInfo
    }

    func getDefaultFavoriteInfo() -> FTFavoritePensetDataModel {
       do {
           let plistData = try Data(contentsOf: resourcePlistUrl)
           return try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: plistData)
       } catch {
           fatalError("Programmer error, unable to fetch default rack data")
       }
   }

    func saveRackData(_ favoriteData: FTFavoritePensetDataModel) {
        do {
            let data = try PropertyListEncoder().encode(favoriteData)
            try data.write(to: plistUrl)
        }
        catch {
            print("Error saving rack data: \(error)")
        }
    }
}

private extension FTFavoritePensetDataManager {
    private func migrateRackDataIfNecessary() throws {
        let fileManager = FileManager.default
        let sourcePlistURL = resourcePlistUrl

        if fileManager.fileExists(atPath: plistUrl.path) == false {
            try fileManager.copyItem(at: sourcePlistURL, to: plistUrl)
        } else { // local version handling
            let sourceData = try Data(contentsOf: sourcePlistURL)
            let currentData = try Data(contentsOf: plistUrl)
            let sourceInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: sourceData)
            let currentInfo = try PropertyListDecoder().decode(FTFavoritePensetDataModel.self, from: currentData)
            if let sourceVersion = Float(sourceInfo.version),
               let currentVersion = Float(currentInfo.version) {
                if sourceVersion > currentVersion {
                    try fileManager.replaceItem(at: plistUrl, withItemAt: sourcePlistURL, backupItemName: nil, resultingItemURL: nil)
                }
            }
        }
    }

    private var resourcePlistUrl: URL {
        guard let sourcePlistURL = Bundle.main.url(forResource: favoritesPlistName, withExtension: "plist") else {
            fatalError("Programmer error, plist is not available")
        }
        return sourcePlistURL
    }
}

