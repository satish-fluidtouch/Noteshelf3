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
    private var defaultRackInfo: FTRackInfoModel?

    private init() {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        rackPlistURL = documentURL.appendingPathComponent(rackPlistName+".plist")
    }

    func getRackData() -> FTRackInfoModel {
        guard let info else {
            var rackInfo: FTRackInfoModel
            do {
                try migrateRackDataIfNecessary()
                let migratedData = try Data(contentsOf: rackPlistURL)
                rackInfo = try PropertyListDecoder().decode(FTRackInfoModel.self, from: migratedData)
                if rackInfo.currentPresetColors.isEmpty && !rackInfo.defaultPresetColors.isEmpty {
                    FTLogError("Stored Pen Color Empty");
                    rackInfo.currentPresetColors = rackInfo.defaultPresetColors
                }
                if rackInfo.currentHighlighterPresetColors.isEmpty && !rackInfo.defaultHighlighterPresetColors.isEmpty {
                    FTLogError("Stored Marker Color Empty");
                    rackInfo.currentHighlighterPresetColors = rackInfo.defaultHighlighterPresetColors
                }
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
         if let info = self.defaultRackInfo {
             return info;
         }
         
        do {
            let plistData = try Data(contentsOf: resourcePlistUrl)
            let infoToReturn = try PropertyListDecoder().decode(FTRackInfoModel.self, from: plistData)
            self.defaultRackInfo = infoToReturn;
            return infoToReturn;
        } catch {
            fatalError("Programmer error, unable to fetch default rack data")
        }
    }

    func saveRackData(_ rackData: FTRackInfoModel) {
        do {
            guard !rackData.currentPresetColors.isEmpty || !rackData.currentHighlighterPresetColors.isEmpty else {
#if DEBUG || BETA
                fatalError("some problem while saving color data");
#else
                FTLogError("Rack Color Empty",attributes: ["Pen": rackData.currentPresetColors.isEmpty
                                                           , "Marker" : rackData.currentHighlighterPresetColors.isEmpty]);
                return
#endif
            }
            info = rackData
            let data = try PropertyListEncoder().encode(rackData)
            try data.write(to: self.rackPlistURL)
        }
        catch {
            FTLogError("PEN RACK SAVE FAILED: \(error)")
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
