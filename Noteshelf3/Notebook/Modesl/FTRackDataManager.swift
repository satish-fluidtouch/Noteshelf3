//
//  FTRackDataManager.swift
//  Noteshelf3
//
//  Created by Narayana on 18/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let rackPlistName = "FTPenRack"

public class FTRackDataManager {
    private let rackPlistURL: URL
    static let shared = FTRackDataManager()
    private var info: FTRackInfoModel?
    
    private init() {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        rackPlistURL = documentURL.appendingPathComponent(rackPlistName+".plist")
    }

    func getRackData() -> FTRackInfoModel {
        guard let info else {
            let rackInfo: FTRackInfoModel
            do {
                try migrateRackDataIfNecessary()
                let migratedData = try Data(contentsOf: rackPlistURL)
                rackInfo = try PropertyListDecoder().decode(FTRackInfoModel.self, from: migratedData)
            } catch {
                rackInfo = getDefaultStockData()
            }
            info = rackInfo
            return rackInfo
        }
        return info
    }

    // MARK: To fetch initial provided default data
     func getDefaultStockData() -> FTRackInfoModel {
        do {
            let plistData = try Data(contentsOf: resourcePlistUrl)
            return try PropertyListDecoder().decode(FTRackInfoModel.self, from: plistData)
        } catch {
            fatalError("Programmer error, unable to fetch default rack data")
        }
    }

    func saveRackData(_ rackData: FTRackInfoModel) {
        do {
            info = rackData
            let data = try PropertyListEncoder().encode(rackData)
            try data.write(to: self.rackPlistURL)
        }
        catch {
            print("Error saving rack data: \(error)")
        }
    }
}

private extension FTRackDataManager {
    private func migrateRackDataIfNecessary() throws {
        let fileManager = FileManager.default
        let sourcePlistURL = resourcePlistUrl
        let rackPlistURL = rackPlistURL

        if fileManager.fileExists(atPath: rackPlistURL.path) == false {
            try fileManager.copyItem(at: sourcePlistURL, to: rackPlistURL)
        } else { // local version handling
            let sourceData = try Data(contentsOf: sourcePlistURL)
            let currentData = try Data(contentsOf: rackPlistURL)
            let sourceInfo = try PropertyListDecoder().decode(FTRackInfoModel.self, from: sourceData)
            let currentInfo = try PropertyListDecoder().decode(FTRackInfoModel.self, from: currentData)
            if let sourceVersion = Float(sourceInfo.version),
               let currentVersion = Float(currentInfo.version) {
                if sourceVersion > currentVersion {
                    try fileManager.replaceItem(at: rackPlistURL, withItemAt: sourcePlistURL, backupItemName: nil, resultingItemURL: nil)
                }
            }
        }
    }

    private var resourcePlistUrl: URL {
        guard let sourcePlistURL = Bundle.main.url(forResource: rackPlistName, withExtension: "plist") else {
            fatalError("Programmer error, plit is not available")
        }
        return sourcePlistURL
    }

   
}
