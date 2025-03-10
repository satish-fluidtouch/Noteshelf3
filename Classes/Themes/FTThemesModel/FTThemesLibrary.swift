//
//  FTThemesLibrary.swift
//  Noteshelf
//
//  Created by Amar on 29/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTNewNotebook

let RecentThemesKey = "RecentThemes"
extension NSNotification.Name {
    static let themeDidDelete = Notification.Name(rawValue: "THEME_DELETED_NOTIFICATION")
    static let customThemeDidCreate = Notification.Name(rawValue: "CUSTOM_THEME_CREATED_NOTIFICATION")
    static let themesDidMigrate = Notification.Name(rawValue: "PAPER_THEMES_MIGRATED_NOTIFICATION")
}

enum FTTemplateID : String {
    case digitalDiariesClassic = "Digital_Diaries_Classic"
    case digitalDiariesModern = "Digital_Diaries_Modern"
    case digitalDiariesMidnight = "Digital_Diaries_Midnight"
    case digitalDiariesDayandNightJournal = "Digital_Diaries_Day_and_Night_Journal"
    case digitalDiariesColorfulPlanner = "Digital_Diaries_Colorful_Planner"
    case digitalDiariesColorfulPlannerDark = "Digital_Diaries_Colorful_Planner_Dark"
    case landscapeDiariesColorfulPlanner = "Landscape_Diaries_Colorful_Planner"
}

enum FTNThemeLibraryType: Int {
    case covers
    case papers
}

enum FTCoverThemeType : String {
    case transparent
    case audio
}

class FTCustomCoverThemeInfo {
    var title : String
    let isCustom: Bool
    let shouldSave: Bool
    let isDiary: Bool

    init(title: String, isCustom: Bool, shouldSave: Bool, isDiary: Bool) {
        self.title = title.isEmpty ? "Untitled".localized : title
        self.isCustom = isCustom
        self.shouldSave = shouldSave
        self.isDiary = isDiary
    }
}

class FTThemesLibrary: NSObject, FTCoverThemeGenerator {
    private var metadataStorage: FTThemesStorage
    private var quickCreateVaraints = "quickCreateVariants" // key for saving variants of quick create settings paper formsheet
    private var basicPaperVariants = "basicPaperVariants" // key for saving variants of basic templates (Inside paper picker of create NB screen)
    private var templateVariants = "templateVariants" // key for saving variants of templates used inside NB (change template and new template options)

    private let themeType: FTSelectedThemeType

    private lazy var templatesData: NSDictionary? = {
        return NSDictionary(contentsOf: self.metadataStorage.themesMetadataURL)
    }()

    init(libraryType: FTNThemeLibraryType) {
        self.metadataStorage = FTThemesStorage(themeLibraryType: libraryType)
        switch libraryType {
        case .covers:
            self.themeType = FTSelectedThemeType.covers
        case .papers:
            self.themeType = FTSelectedThemeType.papers
        }
    }

    func generateCoverTheme(fromImage coverImage: UIImage,
                            coverThemeInfo: FTCustomCoverThemeInfo) -> (error: NSError?, url: URL?) {
        var error: NSError?
        let title = coverThemeInfo.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let uniqueCoverThemeTitle = FileManager.uniqueFileName(title+".nsc", inFolder: self.metadataStorage.customThemesFolderURL)
        coverThemeInfo.title = uniqueCoverThemeTitle

        do {
            let coverInfo = self.generateCoverTheme(fromImage: coverImage,
                                                              themeInfo: coverThemeInfo)
            var urlToreturn:URL?
            error = coverInfo.error
            if nil == error, let url = coverInfo.url {
                let urlToWrite = self.metadataStorage.customThemesFolderURL.appendingPathComponent(uniqueCoverThemeTitle)
                if coverThemeInfo.shouldSave {
                    try FileManager.init().moveItem(at: url, to: urlToWrite)
                    urlToreturn = urlToWrite
                } else {
                    urlToreturn = url
                }
            }
            return (error,urlToreturn)
        } catch let failError as NSError{
            error = failError
            return (error, nil)
        }
    }
}

extension FTThemesLibrary {
    func getDefaultTheme(defaultMode : ThemeDefaultMode) -> FTThemeable {
        let themeProperties = self.metadataStorage.defaultTheme(defaultMode: defaultMode)
        if let themeInfo = themeProperties {
            var theme = FTTheme.theme(url: themeInfo.themeURL, themeType: self.themeType)
            if defaultMode != .basic {
                if themeType == .papers, themeInfo.dynamicId == FTTemplateType.storeTemplate.rawValue {
                    theme = FTStoreTemplatePaperTheme(url: themeInfo.themeURL)
                }
            }
            guard let theme = theme else{
                return self._defaultTheme(defaultMode: defaultMode)
            }
            theme.isCustom = themeInfo.isCustom
            theme.hasCover = themeInfo.hasCover
            if let paperTheme = theme as? FTPaperThemeable ,themeType == .papers{
                paperTheme.setPaperVariants(themeInfo.variants)
                return paperTheme
            }
            return theme
        }
        return self._defaultTheme(defaultMode: defaultMode)
    }

    func _defaultTheme(defaultMode: ThemeDefaultMode) -> FTThemeable {
        if self.themeType == .covers {
            let categories = self.getCoverCategoryList().filter({!$0.isRecents()});
            if UIDevice.current.userInterfaceIdiom == .phone {
                let category = categories.filter{$0.isMobile()};
                if !category.isEmpty {
                    return category.first!.themes.first!;
                }
            }
            let coverTitle: String
            let themeType: FTSelectedThemeType
            if defaultMode == .basic {
                coverTitle = "palette3"
                themeType = .covers
            } else {
                coverTitle = "NoCover"
                themeType = .noCover
            }
            guard let themeUrl = Bundle.main.url(forResource: coverTitle, withExtension: "nsc", subdirectory:"StockCovers.bundle") else {
                fatalError("Programmer error")
            }
            var reqTheme: FTThemeable
            if let theme = FTTheme.theme(url: themeUrl, themeType: themeType) {
                reqTheme = theme
            } else {
                guard let defaultTheme = categories.first?.themes.first else {
                    fatalError("Programmer error")
                }
                reqTheme = defaultTheme
            }
            return reqTheme
        } else {
            let basicCategory = self.getBasicPaperCategory()
            guard let paperTheme = basicCategory.themes.first as? FTPaperTheme else {
                fatalError("Programmer error")
            }
            let dataSource = FTBasicTemplatesDataSource.shared
            let reqVariants = dataSource.getDefaultVariants()
            paperTheme.customvariants = reqVariants
            return paperTheme
        }
    }

    //MARK:- QuickCreateSettings
    func getRandomCoverTheme() -> FTThemeable {
        let userDefaults = FTUserDefaults.defaults()
        var recentThemes = [String]()
        if let existingRecentThemes = userDefaults.value(forKey: RecentThemesKey) as? [String] {
            recentThemes.append(contentsOf: existingRecentThemes)
        }

        let categories = self.getCoverCategoryList().filter({!$0.themes.isEmpty && !$0.isCustom() && !$0.isTransparent() && !$0.isAudio()})
        let randomCategoryIndex = Int(arc4random_uniform(UInt32(categories.count)))
        let randomCategory = categories[randomCategoryIndex]

        let themes = randomCategory.themes.filter({!recentThemes.contains($0.themeTemplateURL().standardizedFileURL.relativeThemePath(withDownloadedURL: self.metadataStorage.downloadedThemesFolderURL))})

        guard !themes.isEmpty else {
            return getRandomCoverTheme()
        }

        let randomThemeIndex = Int(arc4random_uniform(UInt32(themes.count)))
        let randomTheme = themes[randomThemeIndex]

        recentThemes.append(randomTheme.themeTemplateURL().standardizedFileURL.relativeThemePath(withDownloadedURL: self.metadataStorage.downloadedThemesFolderURL))
        userDefaults.setValue(Array(recentThemes.suffix(7)), forKey: RecentThemesKey)
        userDefaults.synchronize()

        return randomTheme
    }

    func getTransparentCovers() -> [FTThemeCategory]{
        let allCategories = self.getCoverCategoryList()
        var transparentCategories  = allCategories.filter({!$0.themes.isEmpty && $0.isTransparent()})
        if transparentCategories.isEmpty {
            transparentCategories = allCategories
        }
        return transparentCategories
    }

    func setDefaultTheme(_ theme:FTThemeable,defaultMode : ThemeDefaultMode,withVariants variants : FTPaperVariants?) {
         self.metadataStorage.setDefaultTheme(themeInfo: (url: theme.themeFileURL, title: theme.displayName, dynamicId: theme.dynamicId),
                                             defaultMode: defaultMode, withVariants:variants,isCustom :theme.isCustom, hasCover: theme.hasCover)
    }
}

extension FTThemesLibrary {
    func getCoverCategoryList() -> [FTThemeCategory] {
        var themeCategories = [FTThemeCategory]()
        let stockThemesInfo = self.metadataStorage.stockThemes
        var downloadedThemesInfo = self.metadataStorage.downloadedThemes
        var currentCatagory = [String:FTThemeCategory]()

       guard let coversInfo = self.templatesData?["covers"] as? NSDictionary else {
           return themeCategories
        }

        guard let categories = coversInfo["categories"] as? [[String:AnyObject]] else {
            return themeCategories
        }

        for categoryMetadata in categories {
            var themes = [FTThemeable]()
            var isDownloaded : Bool = false
            if let themesMetadata = categoryMetadata["themes"] as? [String]{
                for themeFileName in themesMetadata {

                    let packageName = (themeFileName as NSString).deletingPathExtension

                    var pathToTheme : URL?
                    var isStockTheme = false
                    if(stockThemesInfo[packageName] != nil) {
                        pathToTheme = stockThemesInfo[packageName] as URL?
                        isStockTheme = true
                    }
                    else if((downloadedThemesInfo[packageName] != nil)) {
                        pathToTheme = downloadedThemesInfo[packageName] as URL?
                        downloadedThemesInfo.removeValue(forKey: packageName)
                    }

                    if(nil != pathToTheme) {
                        let theme = FTTheme.theme(url: pathToTheme!, themeType: self.themeType)
                        if theme != nil {
                            theme!.canDelete = !isStockTheme
                            themes.append(theme!)
                            isDownloaded = isStockTheme ? false : true
                        }
                    }
                }
            }
            if(!themes.isEmpty) {
                let category = FTThemeCategory()
                category.categoryName = (categoryMetadata["category_name"] as? String) ?? ""
                if let customizeOptions = categoryMetadata["customize_options"] {
                    if let data = try? JSONSerialization.data(withJSONObject: customizeOptions, options: []) {
                        let decoder = JSONDecoder()
                        do {
                            let sections = try decoder.decode(FTCategoryCustomization.self, from: data)
                            category.customizations = sections
                        } catch {
                            FTCLSLog("FTCustmizations Error \(error)")
                        }
                    }
                }
                category.eventTrackName = (categoryMetadata["event_track_name"] as? String) ?? ""
                category.coverVariant_imageName = categoryMetadata["coverVariant_imageName"] as? String ?? ""
                category.themes = themes
                category.isDownloaded = isDownloaded
                themeCategories.append(category)
                currentCatagory[category.categoryName] = category
            }
        }

        //Populate custom themes
        let customThemesInfo = self.metadataStorage.customThemes
        var themes = [FTThemeable]()

        for (key,value) in customThemesInfo {
            let theme = FTTheme.theme(url: value, themeType: self.themeType)
            if(theme != nil) {
                theme?.displayName = key
                theme?.isCustom = true
                theme!.canDelete = true
                themes.append(theme!)
            }
        }
        themes = self.sortThemes(themes: themes,sortBy: FTShelfSortOrder.byModifiedDate)

        let category = FTThemeCategory()
        category.categoryName = NSLocalizedString("Custom", comment: "Custom")
        category.themes = themes
        category.isDownloaded = false
        themeCategories.append(category)

        return themeCategories
    }
    func getBasicPaperCategory() -> FTBasicThemeCategory {
        let themeCategory = FTBasicThemeCategory()

        guard let themesMetadata = self.templatesData?["basicpapers"] as? NSDictionary else {
            fatalError("Programmer error, basic papers data doesnot exist")
        }

        let stockThemesInfo = self.metadataStorage.stockThemes
        guard let themeData = themesMetadata["themes"] as? [String] else {
            fatalError("Programmer error, no basic paper themes available")
        }

        var themes = [FTThemeable]()

        for themeFileName in themeData {
            let packageName = (themeFileName as NSString).deletingPathExtension
            var pathToTheme: URL?

            var isStockTheme = false
            if(stockThemesInfo[packageName] != nil) {
                pathToTheme = stockThemesInfo[packageName] as URL?
                isStockTheme = true
            }
            if(nil != pathToTheme) {
                if let theme = FTTheme.theme(url: pathToTheme!, themeType: .papers) as? FTDynamicTemplateTheme {
                    theme.canDelete = !isStockTheme
                    themes.append(theme)
                }
            }
        }

        if(!themes.isEmpty) {
            themeCategory.categoryName = (themesMetadata["category_name"] as? String) ?? ""
            if let customizeOptions = themesMetadata["customize_options"] {
                if let data = try? JSONSerialization.data(withJSONObject: customizeOptions, options: []) {
                    let decoder = JSONDecoder()
                    do {
                        let sections = try decoder.decode(FTCategoryCustomization.self, from: data)
                        themeCategory.customizations = sections
                    } catch {
                    }
                }
            }
            themeCategory.themes = themes
        }

        return themeCategory
    }
}
extension FTThemesLibrary: FTPDFThemeGenerator {
    func generatePaperThemeForPDFAtURL(_ url : URL,title : String?, shouldSaveForFuture: Bool = true, onCompletion : @escaping ((NSError?, URL?)->Void)) {
        var error : NSError?

        if((nil != title) && (FileManager.default.fileExists(atPath: self.metadataStorage.customThemesFolderURL.appendingPathComponent(title!+".nsp").path))) {
            error = NSError.init(domain: "FTThemeGenerartor", code: 1001, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("ThemeAlreadyExists", comment: "Theme with this title already exists.")])
            onCompletion(error, self.metadataStorage.customThemesFolderURL)
            return
        }

        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            self.generatePaperTheme(fromPDFURL: url, onCompletion: { (genError, themeURL) in
                error = genError
                if(error == nil && shouldSaveForFuture) {
                    var coverThemeTitle = title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if(nil == coverThemeTitle || coverThemeTitle!.isEmpty) {
                        coverThemeTitle = NSLocalizedString("Untitled", comment: "Untitled")
                    }
                    let uniqueCoverThemeTitle = FileManager.uniqueFileName(coverThemeTitle!+".nsp", inFolder: self.metadataStorage.customThemesFolderURL)
                    do {
                        try FileManager.init().moveItem(at: themeURL!, to: self.metadataStorage.customThemesFolderURL.appendingPathComponent(uniqueCoverThemeTitle))
                    }
                    catch let failError as NSError {
                        error = failError
                    }
                }
                DispatchQueue.main.async(execute: {
                    onCompletion(error, themeURL)
                })
            })
        }
    }
}

extension FTThemesLibrary {
    private func sortThemes(themes : [FTThemeable],sortBy : FTShelfSortOrder = FTShelfSortOrder.byName) -> [FTThemeable] {
        let sortedThemes = themes.sorted(by: { (theme1, theme2) -> Bool in
            var returnVal = false
            if(sortBy == FTShelfSortOrder.byName) {
                let title1 = theme1.displayName
                let title2 = theme2.displayName
                returnVal = (title1.compare(title2, options: [String.CompareOptions.caseInsensitive,String.CompareOptions.numeric], range: nil, locale: nil) == ComparisonResult.orderedAscending) ? true : false
            }
            else {
                let creationDate1 = theme1.themeFileURL.fileModificationDate
                let creationDate2 = theme2.themeFileURL.fileModificationDate
                returnVal = (creationDate1.compare(creationDate2) == ComparisonResult.orderedDescending) ? true : false
            }
            return returnVal
        })
        return sortedThemes
    }
    private func fetchThemeSections(dictSections: [[String: AnyObject]]) -> [FTTemplateSection] {
        var themeSections = [FTTemplateSection]()
        let stockThemesInfo = self.metadataStorage.stockThemes
        let downloadedThemesInfo = self.metadataStorage.downloadedThemes

        for section in dictSections {
            let themeSection = FTTemplateSection()

            var requiredThemes = [FTThemeable]()
            if let themesData = section["themes"] as? [String] {
                for themeFileName in themesData {
                    let packageName = (themeFileName as NSString).deletingPathExtension
                    var pathToTheme: URL?
                    var isStockTheme = false
                    if(stockThemesInfo[packageName] != nil) {
                        pathToTheme = stockThemesInfo[packageName] as URL?
                        isStockTheme = true
                    }
                    else if(downloadedThemesInfo[packageName] != nil) {
                        pathToTheme = downloadedThemesInfo[packageName] as URL?
                        isStockTheme = false
                    }
                    if(nil != pathToTheme) {
                        if let theme = FTTheme.theme(url: pathToTheme!, themeType: self.themeType) {
                            theme.canDelete = !isStockTheme
                            theme.isFavorite = self.checkIfFavoriteTheme(theme: theme)
                            requiredThemes.append(theme)
                        }
                    }
                }
            }

            if !requiredThemes.isEmpty {
                themeSection.sectionName = section["section_name"] as? String
                themeSection.themes = requiredThemes
                themeSections.append(themeSection)
            }
        }
        return themeSections
    }

    private func checkIfFavoriteTheme(theme: FTTheme) -> Bool {
        let favorites = self.metadataStorage.getFavorites()
        if favorites.isEmpty {
            return false
        }
        if favorites.contains(where: { favTheme in
            theme.themeFileURL.standardizedFileURL == favTheme.themeFileURL.standardizedFileURL
        }) {
            return true
        }
        return false
    }
}

//MARK:- Paper Variants
extension FTThemesLibrary {
    private func persistencekeyForMode(_ mode: ThemeDefaultMode) -> String {
        let key: String
        switch mode {
        case .basic:
            key = quickCreateVaraints
        case .quickCreate:
            key = basicPaperVariants
        case .template:
            key = templateVariants
        }
        return key
    }
    func storeSelectedVariants(_ variants: FTPaperVariants, mode: ThemeDefaultMode) {
        self.metadataStorage.updateVariants(variants, forKey: persistencekeyForMode(mode))
    }
    func fetchPreviousSelectedVariantsForMode(_ mode: ThemeDefaultMode) -> FTPaperVariants? {
        if let variants = self.metadataStorage.getVariants(forKey: persistencekeyForMode(mode)) {
            return variants
        }
        return nil
    }
}

//MARK:- Favorites
extension FTThemesLibrary {
    func addToFavorites(_ theme: FTThemeable) {
        if self.themeType == FTSelectedThemeType.papers {
            self.metadataStorage.addToFavorites(theme)
        } else {
            // There is no favorite covers yet
        }
    }

    func removeFromFavorites(_ theme: FTThemeable) {
        if self.themeType == FTSelectedThemeType.papers {
            self.metadataStorage.removeFromFavorites(theme)
        } else {
            // There is no favorite covers yet
        }
    }
}

extension URL {
    fileprivate func relativeThemePath(withDownloadedURL downloadURL: URL) -> String! {
        if self.path.hasPrefix(downloadURL.path) {
            return self.path.replacingOccurrences(of: downloadURL.path, with: "")
        }
        else {
            return self.path.replacingOccurrences(of: Bundle.main.bundleURL.path, with: "")
        }
    }
}
