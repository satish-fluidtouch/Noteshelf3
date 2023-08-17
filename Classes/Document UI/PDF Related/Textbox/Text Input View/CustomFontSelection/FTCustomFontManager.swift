//
//  FTCustomFontManager.swift
//  Noteshelf
//
//  Created by Naidu on 21/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTCustomFontManager: NSObject {
    var recentFonts:[[String : String]] = []
    var favoriteFonts:[[String : String]] = []
    
    var customFontInfo:FTCustomFontInfo!
    private var fontColors:[String]!;

    let defaultColorPlistName = "DefaultCustomColors"
    let defaultFavoriteFontsIdentifier = "DefaultFavoriteFonts.plist"
    let favoriteFontsIdentifier = "FavoriteFonts"
    let blueColorHex = "086DB1"
    
    //MARK:- Get/save font colors
    override init() {
        super.init()
        initiateDefaultStorage()
    }
    
    fileprivate var libraryURL : URL {
        let documentURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return documentURL
    }
    
    fileprivate  var defaultColorsPlistURL : URL {
        let fileName = defaultColorPlistName + ".plist"
        return self.libraryURL.appendingPathComponent(fileName)
    }
    
    func getDefaultColors() -> [String] {
        if(nil != fontColors) {
            return fontColors;
        }

        var colors = [String]()
        
        if FileManager().fileExists(atPath: self.defaultColorsPlistURL.path){
            if  let colorData = try? Data(contentsOf: self.defaultColorsPlistURL), let persisted = try? PropertyListDecoder().decode([String].self, from: colorData) {
                colors.append(contentsOf: persisted)
            }
            self.fontColors = colors;
        }else{
            fontColors = self.saveColorsFromPlist()
        }
        return fontColors;
    }

    func saveColorsFromPlist() -> [String]!{
        var colors = [String]()
        if let path = Bundle.main.url(forResource: defaultColorPlistName, withExtension: "plist")
        {
            if let colorData = try? Data(contentsOf: path), let persisted = try? PropertyListDecoder().decode([String].self, from: colorData){
                colors.append(contentsOf: persisted)
            }
            
            self.storeColorsLocally(colors)
        }
        return colors
    }
    
    func storeColorsLocally(_ colors: [String]) {
        fontColors = colors;
        DispatchQueue.global().async {
            let propertyListEncoder = PropertyListEncoder()
            if let data = try? propertyListEncoder.encode(colors) {
                try? data.write(to: self.defaultColorsPlistURL)
            }
        }
    }
    
    func replaceColors(_ colors: [String]) {
        self.storeColorsLocally(colors)
    }
    
    func resetColors(){
        _ = self.saveColorsFromPlist()
    }
    
    //MARK:- Fonts
    fileprivate  var defaultFavoriteFontUrl : URL {
        return self.libraryURL.appendingPathComponent(self.defaultFavoriteFontsIdentifier)
    }
    
    func saveFontToFavorite() {
        var currentFonts = [[String : String]]()
        currentFonts.append(contentsOf: self.favoriteFonts)
        let newFont = FTCustomFontInfo()
        newFont.displayName = self.customFontInfo.displayName
        newFont.fontName = self.customFontInfo.fontName
        newFont.fontStyle = self.customFontInfo.fontStyle
        newFont.fontSize = CGFloat(roundf(Float(self.customFontInfo.fontSize)))
        newFont.textColor = self.customFontInfo.textColor
        newFont.isBold = self.customFontInfo.isBold
        newFont.isItalic = self.customFontInfo.isItalic
        newFont.isUnderlined = self.customFontInfo.isUnderlined
        currentFonts.append(newFont.dictionaryRepresentation())
        (currentFonts as NSArray).write(to: defaultFavoriteFontUrl, atomically: true)
    }
    
    func initiateDefaultFavoriteFontStorage() {
        
        if FileManager().fileExists(atPath: self.defaultFavoriteFontUrl.path){
            return
        }
        let color = UIColor.black.hexStringFromColor()
        
        let defaultFonts = [["displayName":"H1","fontName":"Helvetica Neue","fontStyle":"HelveticaNeue-Bold","fontSize":"28","textColor":color,"isBold":"1","isItalic":"0","isUnderlined":"0"],
                            ["displayName":"H2","fontName":"Helvetica Neue","fontStyle":"HelveticaNeue-Bold","fontSize":"24","textColor":blueColorHex,"isBold":"1","isItalic":"0","isUnderlined":"0"],
                            ["displayName":"H3","fontName":"Helvetica Neue","fontStyle":"HelveticaNeue-Bold","fontSize":"20","textColor":color,"isBold":"1","isItalic":"0","isUnderlined":"0"],
                            ["displayName":"Body","fontName":"Helvetica Neue","fontStyle":"HelveticaNeue","fontSize":"20","textColor":color,"isBold":"0","isItalic":"0","isUnderlined":"0"]]
        (defaultFonts as NSArray).write(to: defaultFavoriteFontUrl, atomically: true)
    }
    
    func favoriteFontsRemoveObjectAt(index: Int)  {
        self.favoriteFonts.remove(at: index)
        (self.favoriteFonts as NSArray).write(to: defaultFavoriteFontUrl, atomically: true)
    }
    
    func favoriteFontRename(name: String, at index: Int) {
        self.favoriteFonts[index]["displayName"] = name
        (self.favoriteFonts as NSArray).write(to: defaultFavoriteFontUrl, atomically: true)
    }
    
    func reorderFont(From firstIndex: Int, to lastIndex: Int) {
        let font = self.favoriteFonts[firstIndex]
        self.favoriteFonts.remove(at: firstIndex)
        self.favoriteFonts.insert(font, at: lastIndex)
        (self.favoriteFonts as NSArray).write(to: defaultFavoriteFontUrl, atomically: true)
    }
    
    func defaultFavoriteFonts() -> [FTCustomFontInfo]{
        guard let savedArray = NSMutableArray.init(contentsOf: defaultFavoriteFontUrl) as? [[String : String]]
            else{
                return [FTCustomFontInfo]()
        }
        self.favoriteFonts = savedArray
        let customFonts = savedArray.map { element in
            return FTCustomFontInfo.font(withDictionary: element)
        }
        return customFonts
    }

    func initiateDefaultStorage(){
        if let recentFonts = UserDefaults.standard.object(forKey: "recentFonts") as? [[String : String]] {
            self.recentFonts = recentFonts
        } else {
            self.recentFonts = [["displayName":"Helvetica","fontName":"Helvetica"],["displayName":"Avenir","fontName":"Avenir"],["displayName":"Georgia","fontName":"Georgia"],["displayName":"American Typewriter","fontName":"American Typewriter"]]
            UserDefaults.standard.set(self.recentFonts, forKey: "recentFonts")
            UserDefaults.standard.synchronize()
        }
        
        let defalultFontInfo = FTCustomFontInfo()
        defalultFontInfo.displayName = "Helvetica"
        defalultFontInfo.fontName = "Helvetica"
        defalultFontInfo.fontStyle = "Helvetica"
        defalultFontInfo.isBold = false
        defalultFontInfo.isItalic = false
        defalultFontInfo.isUnderlined = false
        defalultFontInfo.fontSize = 16
        defalultFontInfo.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1.0)
        self.customFontInfo = defalultFontInfo
    }
    
    func insertLatestSelectedFont(_ recentFont : [String : String]) {
        
        if var storedFonts = UserDefaults.standard.object(forKey: "recentFonts") as? [[String : String]] {
            var index = storedFonts.index(where: { (item) -> Bool in
                if(item["displayName"] == recentFont["displayName"]) {
                    return true
                }
                return false
            })
            
            if(nil == index) {
                index = storedFonts.count - 1
            }
            storedFonts.remove(at: index!)
            storedFonts.insert(recentFont, at: 0)
            self.recentFonts = storedFonts
            
            UserDefaults.standard.set(self.recentFonts, forKey: "recentFonts")
            UserDefaults.standard.synchronize()
        }
    }
    
}
