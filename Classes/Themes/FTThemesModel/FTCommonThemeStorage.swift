//
//  FTCommonThemeStorage.swift
//
//  Created by Narayana on 12/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

class FTCommonThemeStorage: NSObject {
    let themeURLinfo = FTThemeURLInfo.shared
    var themeLibraryType: FTNThemeLibraryType!

    var libraryURL: URL {
        return themeURLinfo.libraryURL
    }

    var pathToLocalThemesFolder: URL {
        let libraryDirectoryURL = self.libraryURL
        let localThemesFolderName = self.themeLibraryType.themeCacheFolderName()
        return libraryDirectoryURL.appendingPathComponent(localThemesFolderName)
    }

    var stockThemesURL: URL {
        let fileName = self.themeLibraryType.themeBundleName()
        return Bundle.main.url(forResource: fileName, withExtension: "bundle")!
    }

    var downloadThemeUrl: URL? {
        if let url = UserDefaults.standard.url(forKey: "TemplateDownloadUrl") {
            return url
        }
        return nil
    }
    
    func fileURL(from relativePath: String) -> URL! {
        let localPathFolder = self.pathToLocalThemesFolder.standardizedFileURL.appendingPathComponent(relativePath)
        if(FileManager().fileExists(atPath: localPathFolder.path)) {
            return localPathFolder
        }
        else {
            let stockThemeURL = self.stockThemesURL.standardizedFileURL.appendingPathComponent(relativePath)
            if(FileManager().fileExists(atPath: stockThemeURL.path)) {
                return stockThemeURL
            } else if FileManager().fileExists(atPath: relativePath) {
                return URL(fileURLWithPath: relativePath)
            }
        }
        return nil
    }
    
    func relativeFilePath(of themeFileURL: URL) -> String {
        let path = themeFileURL.standardizedFileURL.path
        let stockThemeURLPath = self.stockThemesURL.standardizedFileURL.path
        var relativeFilePath = ""
        if path.hasPrefix(stockThemeURLPath) {
            relativeFilePath = path.replacingOccurrences(of: stockThemeURLPath, with: "")
        }
        else {
            let localThemesPath = self.pathToLocalThemesFolder.standardizedFileURL.path
            relativeFilePath = path.replacingOccurrences(of: localThemesPath, with: "")
        }
        return relativeFilePath
    }

    func constructPaperVariantKey(_ variants: FTPaperVariants) -> String {
        let landScape = variants.isLandscape ? FTDeviceOrientation.land.rawValue : FTDeviceOrientation.port.rawValue
        let key = variants.selectedDevice.dimension +  "_" + landScape + "_" + variants.selectedColor.colorName.rawValue +  "_" + variants.lineType.lineType.rawValue
        return key
    }

    func copyThemesPlistFromBundleIfNeeded(_ bundlePath: URL, localPath: URL) {
        if let dict = NSDictionary.init(contentsOf: localPath),let bundleDict = NSDictionary.init(contentsOf: bundlePath){
            if let currentVersion = (dict["version"] as? NSNumber)?.floatValue,let bundleVersion = (bundleDict["version"] as? NSNumber)?.floatValue,bundleVersion > currentVersion {
                let fileManger = FileManager()
                do {
                    try fileManger.removeItem(at: localPath)
                    try fileManger.copyItem(at: bundlePath, to: localPath)
                }
                catch {
                }
            }
        }
    }

    func contentsOfDirectoryAtURL(_ folderURL: URL) -> [String: URL] {
        let options : FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants,.skipsSubdirectoryDescendants,.skipsHiddenFiles];
        let properties = [URLResourceKey.nameKey,URLResourceKey.pathKey];
        var items = [String:URL]();
        if let directoryEnumerator = FileManager.default.enumerator(at: folderURL,
                                                                    includingPropertiesForKeys:properties,
                                                                    options:options,
                                                                    errorHandler: nil){
            for fileURL in directoryEnumerator {
                var fileName : AnyObject?
                if let url = fileURL as? URL{
                    _ = try? (url as NSURL).getResourceValue(&fileName, forKey: URLResourceKey.nameKey);
                    if let fileNameString = fileName as? NSString{
                        items[fileNameString.deletingPathExtension] = url
                    }
                }
            }
        }
        return items
    }
    
    // Persist User Selections
    func updateVariants(_ variants: FTPaperVariants,forKey key:String) {
        let lineType = variants.lineType
        FTCommonUserDefaults.updateVariantsDict(dict: lineType.dictionaryRepresentation(), FTVariantType.line.rawValue, key)

        let deviceType = variants.selectedDevice
        FTCommonUserDefaults.updateVariantsDict(dict: deviceType.dictionaryRepresentation(), FTVariantType.device.rawValue, key)

        let colorType = variants.selectedColor
        FTCommonUserDefaults.updateVariantsDict(dict: colorType.dictionaryRepresentation(), FTVariantType.color.rawValue, key)

        FTCommonUserDefaults.updateVariantsDict(dict: ["orientation":"\(variants.isLandscape)"], FTVariantType.orientation.rawValue, key)
    }

    func getVariants(forKey key :String) -> FTPaperVariants? {
        let lineDict = FTCommonUserDefaults.getVariantsDict(FTVariantType.line.rawValue, key)
        let colorDict = FTCommonUserDefaults.getVariantsDict(FTVariantType.color.rawValue, key)
        let deviceDict = FTCommonUserDefaults.getVariantsDict(FTVariantType.device.rawValue, key)
        let orientationDict = FTCommonUserDefaults.getVariantsDict(FTVariantType.orientation.rawValue, key)

        if (!lineDict.isEmpty && !colorDict.isEmpty && !deviceDict.isEmpty && !orientationDict.isEmpty) {
            return FTSelectedVariants(lineType: FTLineType.init(dictionary: lineDict), selectedDevice: FTDeviceModel.init(dictionary: deviceDict), isLandscape: NSString(string: orientationDict["orientation"] ?? "false").boolValue , selectedColor: FTThemeColors.init(dictionary: colorDict))
        }
        return nil
    }

    func fetchSelectedVariants(_ dict: [String: Any]) -> FTSelectedVariants? {
        var lineType: FTLineType
        var colorType: FTThemeColors
        var deviceType: FTDeviceModel
        var isLandscape: Bool = false
        if let lineDict =  dict[FTVariantType.line.rawValue] as? [String : String], let colorDict =  dict[FTVariantType.color.rawValue] as? [String : String],let deviceDict =  dict[FTVariantType.device.rawValue] as? [String:String],let isLand =  dict["isLand"] as? Bool{
            lineType = FTLineType.init(dictionary: lineDict)
            colorType = FTThemeColors.init(dictionary: colorDict)
            deviceType = FTDeviceModel.init(dictionary: deviceDict)
            isLandscape = isLand
            return FTSelectedVariants(lineType: lineType, selectedDevice: deviceType, isLandscape: isLandscape, selectedColor: colorType)
        }
        return nil
    }
}

class FTThemeURLInfo: NSObject {
    static let shared = FTThemeURLInfo()

    var libraryURL: URL {
        guard let sharedGroupLocation = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID()) else {
            fatalError("Invalid", file: #file)
        }
        return sharedGroupLocation.appendingPathComponent("Library");
    }

    var themesMetadataFolderURL: URL {
        return self.libraryURL.appendingPathComponent("themes")
    }
}
