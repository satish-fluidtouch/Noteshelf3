//
//  FTNThemeCategory.swift
//  Noteshelf
//
//  Created by Amar on 29/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTNewNotebook

class FTThemeCategory: NSObject {
    var categoryName : String!;
    var coverVariant_imageName: String!
    var themes = [FTThemeable]();
    var customizations: FTCategoryCustomization?
    var isDownloaded : Bool = false
    var eventTrackName: String!
        
    func isCustom() -> Bool {
        return (categoryName == NSLocalizedString("Custom", comment: "Custom"));
    }
    
    func isRecents() -> Bool {
        return (categoryName == NSLocalizedString("Recents", comment: "Recents"));
    }
    func isBasic() -> Bool {
        return (categoryName == NSLocalizedString("Basic", comment: "Basic"));
    }
    
    private func isDynamicDiaries() -> Bool {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone && (categoryName == FTDiaryGeneratorLocalizedString("DigitalDiaries", comment: "Digital Diaries"));
        #else
        return false;
        #endif
    }
    
  //  This method is being used for only transparent and audio category
    func getRandomCoverTheme(type : FTCoverThemeType) -> FTThemeable? {
        let themes = self.themes
        guard !themes.isEmpty else {
            return nil
        }
        let userDefault = FTUserDefaults.defaults()
        var index = userDefault.integer(forKey: type.rawValue)
        if index >= themes.count {
            index = 0
        }
        userDefault.set(index + 1, forKey: type.rawValue)
        userDefault.synchronize()
        return themes[index]
    }
}
