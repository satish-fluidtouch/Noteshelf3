//
//  FTTextStyleManager.swift
//  Noteshelf
//
//  Created by Mahesh on 27/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let key_Version = "version"
private let key_Styles = "styles"
private let key_TextStylePlist = "FTTextStyle.plist"


class FTTextStyleManager: NSObject {
    
    static let shared = FTTextStyleManager()
    private override init() { }
    
    private var resourcePlistUrl: URL {
        guard let sourcePlistURL = Bundle.main.url(forResource: "FTTextStyle", withExtension: "plist") else {
            fatalError("Programmer error, plit is not available")
        }
        return sourcePlistURL
    }
    
    private var textStylePlistUrl: URL {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let plistURL = documentURL.appendingPathComponent(key_TextStylePlist)
        return plistURL
    }
    
    func copyStylesFromResourceIfRequired() {
        let fileManager = FileManager.default
        let sourcePlistURL = self.resourcePlistUrl
        let textStylePlistURL = self.textStylePlistUrl
        if fileManager.fileExists(atPath: textStylePlistURL.path) == false {
            do {
                try fileManager.copyItem(at: sourcePlistURL, to: textStylePlistURL)
            }
            catch {
                FTCLSLog("Copying styles: \(error.localizedDescription)")
            }
        } else {
            updateStylesIfRequired()
        }
    }
    
    private func canMigrate() -> Bool {
        let sourcePlistURL = self.resourcePlistUrl
        let textStylePlistURL = self.textStylePlistUrl
        
        var oldVersion: Int = 0
        let pathOld = textStylePlistURL.path
        if let ver =  NSDictionary(contentsOfFile: pathOld)?.value(forKey: key_Version) as? Int{
            oldVersion = ver
        }
        
        var newVersion: Int = 0
        let pathNew = sourcePlistURL.path
        if let ver =  NSDictionary(contentsOfFile: pathNew)?.value(forKey: key_Version) as? Int{
            newVersion = ver
        }
        
        if newVersion > oldVersion {
            return true
        }
        return false
    }
    
    private func updateStylesIfRequired() {
        if canMigrate() {
            let styles = self.fetchResourceTextStylesFromPlist()?.styles
            let defaultStyles = styles?.filter({$0.isDefault == true})
            defaultStyles?.forEach({ style in
                self.updateTextStyle(style)
            })
            let updatedStyles = self.fetchTextStylesFromPlist()
            
            var dict = [[String: Any]]()
            updatedStyles.styles.forEach({ style in
                dict.append(style.dictionaryRepresentation())
            })
            
            var newVersion: Int = 0
            let pathNew = self.resourcePlistUrl.path
            if let ver =  NSDictionary(contentsOfFile: pathNew)?.value(forKey: key_Version) as? Int{
                newVersion = ver
            }
            var mainDict = updatedStyles.dictionaryRepresentation()
            mainDict[key_Styles] = dict
            mainDict[key_Version] = newVersion
            try? (mainDict as NSDictionary).write(to: textStylePlistUrl)
        }
    }
    
    func fetchTextStylesFromPlist() -> FTTextStyle {
        let path = textStylePlistUrl
        do {
            let data = try Data(contentsOf: path)
            let decoder = PropertyListDecoder()
            let textStyles = try decoder.decode(FTTextStyle.self, from: data)
            return textStyles
        } catch {
            print("Local Filtering File Read Error::",error.localizedDescription)
            fatalError("Programmer error, unable to find text styles")
        }
    }
    
    private func fetchResourceTextStylesFromPlist() -> FTTextStyle? {
        let path = resourcePlistUrl
        do {
            let data = try Data(contentsOf: path)
            let decoder = PropertyListDecoder()
            let textStyles = try decoder.decode(FTTextStyle.self, from: data)
            return textStyles
        } catch {
            print("Local Filtering File Read Error::",error.localizedDescription)
        }
        return nil
    }
    
    func insertNewTextStyle(_ style: FTTextStyleItem) {
        let textItem = self.fetchTextStylesFromPlist()
        var dict = [[String: Any]]()
        textItem.styles.forEach({ item in
            dict.append(item.dictionaryRepresentation())
        })
        
        if style.displayName.isEmpty {
            style.displayName = key_Default_Style_Name
        }
        
        if style.displayName == key_Default_Style_Name {
            let filteredStyles = textItem.styles.filter({$0.displayName.contains(key_Default_Style_Name)})
            if !filteredStyles.isEmpty {
                for (idx,_) in filteredStyles.enumerated() {
                    let modifiedDisplayName = "\(key_Default_Style_Name) \(idx + 1)"
                    let matchedItems = textItem.styles.filter({$0.displayName.contains(modifiedDisplayName)})
                    if matchedItems.isEmpty {
                        style.displayName = modifiedDisplayName
                        break
                    }
                }
            }
        }
        dict.append(style.dictionaryRepresentation())
        var mainDict = textItem.dictionaryRepresentation()
        mainDict[key_Styles] = dict
        try? (mainDict as NSDictionary).write(to: textStylePlistUrl)
    }
    
    func fetchTextStyleForId(_ id: String) -> FTTextStyleItem? {
        let styles = self.fetchTextStylesFromPlist().styles
        let filteredStyle = styles.filter({$0.fontId == id}).first
        return filteredStyle
    }
    
    func updateTextStyle(_ style: FTTextStyleItem) {
        let textItem = self.fetchTextStylesFromPlist()
        if let updatedIndex = textItem.styles.firstIndex(where: {$0.fontId == style.fontId}) {
            if updatedIndex != NSNotFound {
                textItem.styles.remove(at: updatedIndex)
            }
            textItem.styles.insert(style, at: updatedIndex)
        }
        var dict = [[String: Any]]()
        textItem.styles.forEach({ item in
            dict.append(item.dictionaryRepresentation())
        })
        var mainDict = textItem.dictionaryRepresentation()
        mainDict[key_Styles] = dict
        try? (mainDict as NSDictionary).write(to: textStylePlistUrl)
    }
    
    func deleteTextStyle(_ style: FTTextStyleItem) {
        let textItem = self.fetchTextStylesFromPlist()
        if let updatedIndex = textItem.styles.firstIndex(where: {$0.fontId == style.fontId}) {
            if updatedIndex != NSNotFound {
                textItem.styles.remove(at: updatedIndex)
            }
        }
        var dict = [[String: Any]]()
        textItem.styles.forEach({ item in
            dict.append(item.dictionaryRepresentation())
        })
        var mainDict = textItem.dictionaryRepresentation()
        mainDict[key_Styles] = dict
        try? (mainDict as NSDictionary).write(to: textStylePlistUrl)
    }
    
    func resetPresetTextStyles() {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: textStylePlistUrl)
            copyStylesFromResourceIfRequired()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateOrderOfStyles(_ item: FTTextStyle) {
        var dict = [[String: Any]]()
        item.styles.forEach({ style in
            dict.append(style.dictionaryRepresentation())
        })
        var mainDict = item.dictionaryRepresentation()
        mainDict[key_Styles] = dict
        (mainDict as NSDictionary).write(to: textStylePlistUrl, atomically: true)
    }
}
