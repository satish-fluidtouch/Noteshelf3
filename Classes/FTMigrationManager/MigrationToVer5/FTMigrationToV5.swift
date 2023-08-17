//
//  FTMigrationToV5.swift
//  Noteshelf
//
//  Created by Amar on 09/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTMigrationToV5: NSObject {
    func performMigration()
    {
        let sharedDefaults = FTUserDefaults.defaults();
        let value = sharedDefaults.float(forKey: "migrationVersion");
        if(value < 5.0) {
            FTShelfThemeStyle.performMigrationTov5();
            sharedDefaults.set(5.0, forKey: "migrationVersion");
            sharedDefaults.synchronize();
        }
    }
}

fileprivate extension FTShelfThemeStyle
{
    class func performMigrationTov5()
    {
        /*
         old values:                                             New Values
         ShelfThemeGraphite 7BB2B9                             //ShelfThemeOxfordBlue
         ShelfThemeDefault  EB9F61                             //ShelfThemeOrange
         ShelfThemeAqua     61C1EE                             //ShelfThemeAqua
         ShelfThemeBlack    53585F                             //ShelfThemeGraphite
         ShelfThemeGreen    23B890                              //ShelfThemeGreen
         ShelfThemeTapestry AC6584                              //ShelfThemePink
         ShelfThemeLight    fffffc                              //ShelfThemeWhite
         ShelfThemeDark     383838                              //ShelfThemeDark
         ShelfThemeMojave   383837 , 3d3c3c (shelf)             //ShelfThemeMojaveDark
         */
        /*
         "fffffc",title:"ShelfThemeWhite
         ,title:"ShelfThemeNapa")
         ,title:"ShelfThemeHippieBlue"
         ,title:"ShelfThemeGreen")
         ,title:"ShelfThemePink")
         ,title:"ShelfThemeOrange")
         ,title:"ShelfThemeAqua")
         ,title:"ShelfThemeGraphite")
         2626",title:"ShelfThemeDark")
         ShelfThemeMojaveDark
         ShelfThemeMojaveMidNight
         */
        
        let theme = FTShelfThemeStyle.defaultTheme();
        var newThemeToSet : FTShelfThemeStyle?;
        
        switch theme.title {
//        case "ShelfThemeWhite":
//            newThemeToSet = self.theme("colorTheme2");
//        case "ShelfThemeOxfordBlue":
//            newThemeToSet = self.theme("colorTheme1");
//        case "ShelfThemeNapa":
//            newThemeToSet = self.theme("colorTheme6");
//        case "ShelfThemeHippieBlue":
//            newThemeToSet = self.theme("colorTheme7");
//        case "ShelfThemeGreen":
//            newThemeToSet = self.theme("colorTheme8");
//        case "ShelfThemePink":
//            newThemeToSet = self.theme("colorTheme9");
//        case "ShelfThemeOrange":
//            newThemeToSet = self.theme("colorTheme10");
//        case "ShelfThemeAqua":
//            newThemeToSet = self.theme("colorTheme5");
//        case "ShelfThemeGraphite":
//            newThemeToSet = self.theme("colorTheme3");
//        case "ShelfThemeDark":
//            newThemeToSet = self.theme("colorTheme1");
        case "ShelfThemeMojaveDark":
            newThemeToSet = self.theme("ShelfThemeDark");
        case "ShelfThemeMojaveMidNight":
            newThemeToSet = self.theme("ShelfThemeOxfordBlue");
        default:
            break;
        }
        newThemeToSet?.setAsDefault(forcibly: true);
    }
    
    private class func theme(_ title : String) -> FTShelfThemeStyle?
    {
        let allThemes = FTShelfThemeStyle.allThemeStyles();
        var themeToReturn : FTShelfThemeStyle?;
        for eachTheme in allThemes {
            if(eachTheme.title == title) {
                themeToReturn = eachTheme;
                break;
            }
        }
        return themeToReturn;
    }
}
