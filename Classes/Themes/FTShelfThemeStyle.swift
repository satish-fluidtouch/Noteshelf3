//
//  FTShelfThemeStyle.swift
//  Noteshelf
//
//  Created by Amar on 9/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private var settingFirstTime = true;
private let _defaultTheme = FTShelfThemeStyle.init("ffffff",title:"ShelfThemeWhite");

class FTShelfThemeStyle : NSObject {
    
    var selectionIndicatorImage : UIImage? {
        var imageName = "indicatorwhite"
        if self.isLightTheme() {
            imageName = "indicatorblack"
        } else if self.isMojaveTheme() {
            imageName = "indicatorblue"
        }
        return UIImage.init(named: imageName)
    }
    
    var swatchColor : UIColor {
        var color = self.themeColor
        if(self.title == "ShelfThemeGreen") {
            color = UIColor(hexString: "09bf8d");
        }
        else if(self.title == "ShelfThemeOrange") {
            color = UIColor(hexString: "eb9147");
        }
        else if(self.title == "ShelfThemeMojaveDark") {
            color = UIColor(hexString: "5e5a5a");
        }
        else if(self.title == "ShelfThemeMojaveMidNight") {
            color = UIColor(hexString: "303545");
        }
        
        let colorName = "Theme Colors/\(self.title)"
        if let availableColor = UIColor(named:colorName) {
            color = availableColor;
        }
        #if targetEnvironment(macCatalyst)
        color = UIColor(hexString: "d2d1d2");
        #endif
        return color;
    };
    
    var shelfSwatchColor : UIColor? {
        var color : UIColor?;
        if(self.title == "ShelfThemeMojaveDark") {
            color = UIColor(hexString: "3b3e42");
        }
        else if(self.title == "ShelfThemeMojaveMidNight") {
            color = UIColor(hexString: "24242d");
        }
        return color
    };
    
    @objc var title : String;
    var isNewTheme: Bool = false
    
    var tintColor : UIColor {
        if self.isLightTheme() {
            return .black;
        }
        else {
            return .white;
        }
    }
    
    var themeColor : UIColor;
    var shelfThemeColor : UIColor?;
    
    var separatorColor : UIColor {
        if self.isLightTheme() {
            return UIColor(hexString: "D2D2CD");
        }
        else if self.isDarkTheme() {
            return UIColor(hexString: "222222");
        }
        else {
            return UIColor.separator;
        }
    };
    
    @objc var imageNameSuffix: String! {
        if self.isLightTheme() {
            return "";
        }
        else if self.isMojaveTheme() {
            return "Dark";
        }
        else {
            return "";
        }
    };
    
    init(_ color : String,
         title : String,
         shelfThemeColor: String? = nil,
         isNewTheme: Bool = false) {
        self.title = title;
        self.isNewTheme = isNewTheme
        self.themeColor = UIColor.init(hexString:color);
        if(nil != shelfThemeColor) {
            self.shelfThemeColor = UIColor(hexString: shelfThemeColor)
        }
    }
    
    class func allThemeStyles() -> [FTShelfThemeStyle]
    {
        var themes = [FTShelfThemeStyle]();
        
        themes = [FTShelfThemeStyle("ffffff",title:"ShelfThemeWhite")
                  ,FTShelfThemeStyle("344455",title:"ShelfThemeOxfordBlue")
                  ,FTShelfThemeStyle("5c6067",title:"ShelfThemeGraphite")
                  ,FTShelfThemeStyle("262626",title:"ShelfThemeDark")
                  ,FTShelfThemeStyle("5ca7f7",title:"ShelfThemeAqua")
                  ,FTShelfThemeStyle("aba08e",title:"ShelfThemeNapa")
                  ,FTShelfThemeStyle("4aa3af",title:"ShelfThemeHippieBlue")
                  ,FTShelfThemeStyle("0aa788",title:"ShelfThemeGreen")
                  ,FTShelfThemeStyle("e03884",title:"ShelfThemePink")
                  ,FTShelfThemeStyle("eb9147",title:"ShelfThemeOrange")
        ]

        return themes
    }
    class func isLightColorTheme() -> Bool {
        let lightThemes  = [FTShelfThemeStyle("344455",title:"ShelfThemeOxfordBlue"),FTShelfThemeStyle("5c6067",title:"ShelfThemeGraphite"),FTShelfThemeStyle("262626",title:"ShelfThemeDark")]
        return (lightThemes.first(where: {$0.title == FTShelfThemeStyle.defaultTheme().title}) != nil)
    }
    class func isDarkColorTheme() -> Bool {
        let darkThemes = [FTShelfThemeStyle("ffffff",title:"ShelfThemeWhite"),FTShelfThemeStyle("5ca7f7",title:"ShelfThemeAqua")
        ,FTShelfThemeStyle("aba08e",title:"ShelfThemeNapa")
        ,FTShelfThemeStyle("4aa3af",title:"ShelfThemeHippieBlue")
        ,FTShelfThemeStyle("0aa788",title:"ShelfThemeGreen")
        ,FTShelfThemeStyle("e03884",title:"ShelfThemePink")
        ,FTShelfThemeStyle("eb9147",title:"ShelfThemeOrange")]
        return (darkThemes.first(where: {$0.title == FTShelfThemeStyle.defaultTheme().title}) != nil)
    }
    func setAsDefault(forcibly : Bool = false)
    {
        let currentDefaultTheme = FTShelfThemeStyle.defaultTheme();
        if(forcibly || (currentDefaultTheme.title != self.title)) {
            UserDefaults.standard.set(self.styleInfoToSave(), forKey: "NS_default_theme");
            UserDefaults.standard.synchronize();
            NotificationCenter.default.post(name: NSNotification.Name.FTShelfThemeDidChange, object: nil);
        }
    }
    
    func isCurrent() -> Bool
    {
        let colorString = FTShelfThemeStyle.defaultTheme().themeColor.hexStringFromColor();
        if(colorString == self.themeColor.hexStringFromColor()) {
            return true;
        }
        return false;
    }
    
    @objc class func defaultTheme() -> FTShelfThemeStyle
    {
        if(settingFirstTime) {
            settingFirstTime = false;
            UserDefaults.standard.register(defaults: ["NS_default_theme":_defaultTheme.styleInfoToSave()]);
        }
        
        let info = UserDefaults.standard.value(forKey: "NS_default_theme");
        if let colorInfo = info as? [String : Any],
            let colorString = colorInfo["color"] as? String,
            let title = colorInfo["title"] as? String {
            let shelfColor = colorInfo["shelfColor"] as? String
            var isThemeNew = false;
            if let isNewThemeVal = colorInfo["isNewTheme"] as? Bool {
                isThemeNew = isNewThemeVal;
            }
            else if let isNewThemeStr = colorInfo["isNewTheme"] as? String {
                isThemeNew = (isNewThemeStr == "true");
            }
            return FTShelfThemeStyle.init(colorString,
                                          title:title,
                                          shelfThemeColor:shelfColor,
                                          isNewTheme: isThemeNew);
        }
        return _defaultTheme;
    }
    
    func isLightTheme() -> Bool
    {
        if title == "ShelfThemeWhite" {
            // UITraitCollection.current has been changed to UIscreen.main to fix the issue
        // https://www.notion.so/fluidtouch/Icons-are-not-visible-when-changing-device-mode-after-sharing-a13ce95a9d364e2d9e695551aaee80a3
            if(UIScreen.main.traitCollection.userInterfaceStyle == .dark) {
                return false
            }
            return true
        }
        return false
    }
    
    func isAutoTheme() -> Bool {
        if title == "ShelfThemeWhite" {
            return true
        }
        return false
    }
     
     func getLocalizedTitleOfTheme() -> String {
        switch title {
        case "ShelfThemeWhite":
            return NSLocalizedString("Theme_Auto", comment: "Auto")
        case "ShelfThemeOxfordBlue":
            return NSLocalizedString("Theme_Midnight", comment: "Midnight")
        case "ShelfThemeGraphite":
            return NSLocalizedString("Theme_Graphite", comment: "Graphite")
        case "ShelfThemeDark":
            return NSLocalizedString("Theme_Dark", comment: "Dark")
        case "ShelfThemeAqua":
            return NSLocalizedString("Theme_Aqua", comment: "Aqua")
        case "ShelfThemeNapa":
            return NSLocalizedString("Theme_Brown", comment: "Brown")
        case "ShelfThemeHippieBlue":
            return NSLocalizedString("Theme_Teal", comment: "Teal")
        case "ShelfThemeGreen":
            return NSLocalizedString("Theme_Green", comment: "Green")
        case "ShelfThemePink":
            return NSLocalizedString("Theme_Magenta", comment: "Magenta")
        case "ShelfThemeOrange":
            return NSLocalizedString("Theme_Orange", comment: "Orange")
        default:
            return ""
        }
    }
    
    private func styleInfoToSave() -> [String : Any]
    {
        let currentColorString = self.themeColor.hexStringFromColor();
        var themeData : [String : Any] = ["color" : currentColorString,
                                          "title" : self.title,
                                          "isNewTheme": self.isNewTheme];
        if let shelfColor = self.shelfThemeColor?.hexStringFromColor() {
            themeData["shelfColor"] = shelfColor;
        }
        return themeData;
    }
    
    private func isDarkTheme() -> Bool
    {
        if (title == "ShelfThemeMojaveDark"
            || title == "ShelfThemeMojave"
            || title == "ShelfThemeOxfordBlue"
            || title == "ShelfThemeDark"
            ) {
            return true;
        }
        return false;
    }
    
    func isMojaveTheme() -> Bool {
        if (title == "ShelfThemeMojaveDark"
            || title == "ShelfThemeMojaveMidNight"
            ){
            return true
        }
        return false
    }
    
}
