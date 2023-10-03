//
//  FTNThemesStorage.swift
//  Noteshelf
//
//  Created by Amar on 29/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import FTTemplatesStore

//change ftappconfig key {config}_themes_v8_metadata_version
//Make sure the path is pointing to proper version folder like v8 in FTServerConfig themesMetadataURL method
public let themePlist = "themes_v8"

let newlyAddedThemesKey = "newlyAddedThemes";
let themeFilesDownloadedDefaultsKey = "themeFilesDownloadedDefaultsKey"
let themeFileDownloadedTimeKey = "themeFileDownloadedTimeKey"
let themeFileName = "themeFileName"

enum FTVariantType : String {
    case line
    case device
    case color
    case orientation
}
enum ThemeDefaultMode : Int {
    /// quick create option on shelf
    case quickCreate

    /// For change template and template options inside notebook
    case template

    /// For covers and   basic papers
    case basic

    func defaultModeKey() -> String
    {
        var modeKey : String!;
        switch self {
        case .quickCreate:
            modeKey  = "QuickNote";
        case .template:
            modeKey =  "Template"
        case .basic:
            modeKey  = "Basic";
        }
        return modeKey;
    }
}

extension FTNThemeLibraryType {
    func themeBundleName() -> String {
        var bundleName : String!;
        switch self {
        case .covers:
            bundleName  = "StockCovers";
        case .papers:
            bundleName  = "StockPapers";
        }
        return bundleName
    }

    func themeCacheFolderName() -> String {
        var bundleName : String!;
        switch self {
        case .covers:
            bundleName  = "covers";
        case .papers:
            bundleName  = "papers_v2";
        }
        return bundleName;
    }

    func previousVersionThemeCacheFolderName() -> String {
        var bundleName : String!;
        switch self {
        case .covers:
            bundleName  = "covers";
        case .papers:
            bundleName  = "papers";
        }
        return bundleName;
    }

    func themeURLDefaultKey() -> String {
        var defaultKey : String!;
        switch self {
        case .covers:
            defaultKey  = "Default_Cover";
        case .papers:
            defaultKey  = "Default_Paper";
        }
        return defaultKey;
    }

    func themeTitleDefaultKey() -> String {
        var defaultKey : String!;
        switch self {
        case .covers:
            defaultKey  = "Default_Cover_Title";
        case .papers:
            defaultKey  = "Default_Paper_Title";
        }
        return defaultKey;
    }
}

struct DefaultThemeProperties {
    var themeURL : URL
    var themeDisplayName : String
    var isCustom : Bool
    var hasCover : Bool
    var variants : FTPaperVariants
    var dynamicId: Int
}

class FTThemesStorage: FTCommonThemeStorage {
    var themeType: FTSelectedThemeType = .covers

    //MARK:- Initialize -
    required convenience init(themeLibraryType: FTNThemeLibraryType) {
        self.init()
        super.themeLibraryType = themeLibraryType
        self.createDefaultFoldersIfNeeded()
        switch themeLibraryType {
        case .covers:
            self.themeType = FTSelectedThemeType.covers
        case .papers:
            self.themeType = FTSelectedThemeType.papers
        }
    }

    //MARK:- Paths -
    var themesMetadataURL: URL {
        let currentLang = FTCommonUtils.currentLanguage();
        let defaultFileName = themePlist.appending("_en.plist");

        let fileName = themePlist+"_\(currentLang).plist";
        let localPath = self.themesMetadataFolderURL.appendingPathComponent(fileName);

        let defaultFilePath = self.themesMetadataFolderURL.appendingPathComponent(defaultFileName);
        let bundle = Bundle.main
        let url = bundle.url(forResource: fileName, withExtension: nil)!
        return url
    }

    var recentsPlistURL : URL {
        return self.pathToLocalThemesFolder.appendingPathComponent("recents.plist")
    }

    var favoritesPlistURL: URL {
        return self.pathToLocalThemesFolder.appendingPathComponent("favorites.plist")
    }

    var themesMetadataFolderURL: URL {
        return themeURLinfo.themesMetadataFolderURL
    }

    var customThemesFolderURL: URL {
        return self.pathToLocalThemesFolder.appendingPathComponent("custom")
    }

    var stockThemes: [String:URL] {
        return self.contentsOfDirectoryAtURL(self.stockThemesURL)
    }

    var downloadedThemesFolderURL : URL {
        return self.pathToLocalThemesFolder.appendingPathComponent("downloaded");
    }

    var downloadedThemes: [String: URL] {
        if let url = self.downloadThemeUrl {
            return self.contentsOfDirectoryAtURL(url)
        }
        return [:]
    }

    var customThemes: [String:URL] {
        return self.contentsOfDirectoryAtURL(self.customThemesFolderURL)
    }

    private func createDefaultFoldersIfNeeded() {
        if(!FileManager.default.fileExists(atPath: self.pathToLocalThemesFolder.path)) {
            _ = try? FileManager.default.createDirectory(at: self.pathToLocalThemesFolder, withIntermediateDirectories: true, attributes: nil)
        }

        if(!FileManager.default.fileExists(atPath: self.themesMetadataFolderURL.path)) {
            _ = try? FileManager.default.createDirectory(at: self.themesMetadataFolderURL, withIntermediateDirectories: true, attributes: nil)
        }

        if(!FileManager.default.fileExists(atPath: self.customThemesFolderURL.path)) {
            try? FileManager.default.createDirectory(at: self.customThemesFolderURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

//for defaults
extension FTThemesStorage {
    func setDefaultTheme(themeInfo : (url:URL,title:String, dynamicId: Int),defaultMode : ThemeDefaultMode, withVariants variants : FTPaperVariants?,isCustom : Bool, hasCover: Bool) {
        let key = defaultMode.defaultModeKey()+"_\(self.themeLibraryType.themeURLDefaultKey())";
        let titleKey = defaultMode.defaultModeKey()+"_\(self.themeLibraryType.themeTitleDefaultKey())";
        let path = themeInfo.url.standardizedFileURL.path;
        let stockThemeURLPath = self.stockThemesURL.standardizedFileURL.path;
        if path.hasPrefix(stockThemeURLPath) {
            FTUserDefaults.defaults().set(path.replacingOccurrences(of: stockThemeURLPath, with: ""), forKey: key);
        }
        else {
            let localThemesPath = self.pathToLocalThemesFolder.standardizedFileURL.path;
            FTUserDefaults.defaults().set(path.replacingOccurrences(of: localThemesPath, with: ""), forKey: key);
        }
        if themeLibraryType == .papers, let defaultVariants = variants {
            self.updateVariants(defaultVariants, forKey: "DefaultThemeVariantsFor\(defaultMode.rawValue)")
        }
        FTUserDefaults.defaults().set(isCustom, forKey: "DefaultThemeFor\(defaultMode.rawValue)isCustom")
        if themeLibraryType == .covers {
            FTUserDefaults.defaults().set(hasCover, forKey: "DefaultThemeFor\(defaultMode.rawValue)hasCover")
        }
        FTUserDefaults.defaults().set(themeInfo.title, forKey: titleKey);
        FTUserDefaults.defaults().set(themeInfo.dynamicId, forKey: "DefaultThemeFor\(defaultMode.rawValue)dynamicId");
        FTUserDefaults.defaults().synchronize();

    }

    func defaultTheme(defaultMode : ThemeDefaultMode) -> DefaultThemeProperties? {
        let key = defaultMode.defaultModeKey()+"_\(self.themeLibraryType.themeURLDefaultKey())";
        let titleKey = defaultMode.defaultModeKey()+"_\(self.themeLibraryType.themeTitleDefaultKey())";
        let dynamicIdKey = "DefaultThemeFor\(defaultMode.rawValue)dynamicId"
        let storedPath = FTUserDefaults.defaults().string(forKey: key);
        let title = FTUserDefaults.defaults().string(forKey: titleKey);
        let id = FTUserDefaults.defaults().string(forKey: dynamicIdKey) ?? "0"
        let dynamicId = Int(id) ?? 0
        let isCustom = (FTUserDefaults.defaults().value(forKey:"DefaultThemeFor\(defaultMode.rawValue)isCustom") as? Bool) ?? false
        let hasCover = (FTUserDefaults.defaults().value(forKey:"DefaultThemeFor\(defaultMode.rawValue)hasCover") as? Bool) ?? false
        var variants : FTPaperVariants = FTBasicTemplatesDataSource.shared.getDefaultVariants()
        if themeLibraryType == .papers, let defaultVariants = self.getVariants(forKey: "DefaultThemeVariantsFor\(defaultMode.rawValue)"){
            variants = defaultVariants
        }
        if let storedPath {
            var templatePath = FTTemplatesCache().locationFor(filePath: storedPath)
            if isCustom {
                templatePath = FTStoreCustomTemplatesHandler.shared.locationFor(filePath:storedPath)
            }
            if dynamicId == FTTemplateType.storeTemplate.rawValue, FileManager().fileExists(atPath: templatePath.path) {
                return DefaultThemeProperties(themeURL: templatePath, themeDisplayName: title!, isCustom: isCustom, hasCover: hasCover, variants: variants, dynamicId: dynamicId)
            }
            else {
                let stockThemeURL = self.stockThemesURL.standardizedFileURL.appendingPathComponent(storedPath);
                if(FileManager().fileExists(atPath: stockThemeURL.path)) {
                    return DefaultThemeProperties(themeURL: stockThemeURL, themeDisplayName: title!, isCustom: isCustom, hasCover: hasCover, variants: variants, dynamicId: dynamicId)
                }
            }
        }
        return nil
    }
}

extension Dictionary {
    mutating func update(_ dict:Dictionary) {
        for (key,value) in dict {
            self.updateValue(value, forKey:key)
        }
    }
}
