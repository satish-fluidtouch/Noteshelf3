//
//  FTLanguageCodeFinder.swift
//  Noteshelf
//
//  Created by Naidu on 04/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLanguageResourceMapper: NSObject {
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

   static func currentScriptLanguageCode(foriOSPreferredLanguage preferredLanguageCode: String? = nil) -> String {
        let preferredLanguages = Locale.preferredLanguages;
        var langToSet = "";
        for eachLang in preferredLanguages {
            langToSet = FTLanguageResourceMapper.langMapping(eachLang);
            if(langToSet.count > 0) {
                break;
            }
        }
        if(langToSet.count == 0) {
            langToSet = "en_US";
        }
        return langToSet;
    }
    
    fileprivate static func langMapping(_ currentLang : String) -> String
    {
        let lowerCaseLang = currentLang.lowercased();
        
        var scriptLanguageCode = ""
        if(lowerCaseLang == "en-us") {
            scriptLanguageCode = "en_US";
        }
        else if(lowerCaseLang == "en-gb") {
            scriptLanguageCode = "en_GB";
        }
        else if(lowerCaseLang.hasPrefix("en")) {
            scriptLanguageCode = "en_US";
        }
        else if(lowerCaseLang.hasPrefix("zh-hans")) {
            scriptLanguageCode = "zh_CN";
        }
        else if(lowerCaseLang.hasPrefix("zh-hant")) {
            scriptLanguageCode = "zh_TW";
        }
        else if(lowerCaseLang.hasPrefix("it")) {
            scriptLanguageCode = "zh_TW";
        }
        else if(lowerCaseLang.hasPrefix("ja")) {
            scriptLanguageCode = "ja_JP";
        }
        else if(lowerCaseLang.hasPrefix("fr")) {
            scriptLanguageCode = "fr_FR";
        }
        else if(lowerCaseLang.hasPrefix("es")) {
            scriptLanguageCode = "es_ES";
        }
        else if(lowerCaseLang.hasPrefix("de")) {
            scriptLanguageCode = "de_DE";
        }
        else if(lowerCaseLang.hasPrefix("pt")) {
            scriptLanguageCode = "pt_PT";
        }
        else if(lowerCaseLang.hasPrefix("ko")) {
            scriptLanguageCode = "ko_KR";
        }

        return scriptLanguageCode;
        
    }
}
