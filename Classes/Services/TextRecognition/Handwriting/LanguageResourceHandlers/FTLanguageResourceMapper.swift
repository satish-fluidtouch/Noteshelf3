//
//  FTLanguageCodeFinder.swift
//  Noteshelf
//
//  Created by Naidu on 04/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
let languageCodeNone = "<<None>>";

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
            if(!langToSet.isEmpty) {
                break;
            }
        }
        if(langToSet.isEmpty) {
            langToSet = "en_US";
        }
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            return languageCodeNone;
        }
        return langToSet;
    }
    
    fileprivate static func langMapping(_ currentLang : String) -> String
    {
        let lowerCaseLang = currentLang.lowercased();
        
        var scriptLanguageCode = ""
        if(lowerCaseLang.hasPrefix("en")) {
            if(lowerCaseLang == "en-us") {
                scriptLanguageCode = "en_US";
            }
            else if(lowerCaseLang == "en-gb") {
                scriptLanguageCode = "en_GB";
            }
            else if(lowerCaseLang == "en-ph") {
                scriptLanguageCode = "en_PH";
            }
            else if(lowerCaseLang == "en-ca") {
                scriptLanguageCode = "en_CA";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("zh")) {
            if(lowerCaseLang == "zh-cn") {
                scriptLanguageCode = "zh_CN";
            }
            else if(lowerCaseLang == "zh-tw") {
                scriptLanguageCode = "zh_TW";
            }
            else if(lowerCaseLang == "zh-hk") {
                scriptLanguageCode = "zh_HK";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("sr")) {
            if(lowerCaseLang == "sr_cy") {
                scriptLanguageCode = "sr_Cyrl_RS";
            }
            else if(lowerCaseLang == "sr_la") {
                scriptLanguageCode = "sr_Latn_RS";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("es")) {
            if(lowerCaseLang == "es-es") {
                scriptLanguageCode = "es_ES";
            }
            else if(lowerCaseLang == "es-co") {
                scriptLanguageCode = "es_CO";
            }
            else if(lowerCaseLang == "es-mx") {
                scriptLanguageCode = "es_MX";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("de")) {
            if(lowerCaseLang == "de-de") {
                scriptLanguageCode = "de_DE";
            }
            else if(lowerCaseLang == "de-at") {
                scriptLanguageCode = "de_AT";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("fr")) {
            if(lowerCaseLang == "fr-ca") {
                scriptLanguageCode = "fr_CA";
            }
            else if(lowerCaseLang == "fr-fr") {
                scriptLanguageCode = "fr_FR";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("pt")) {
            if(lowerCaseLang == "pt-pt") {
                scriptLanguageCode = "pt_PT";
            }
            else if(lowerCaseLang == "pt-br") {
                scriptLanguageCode = "pt_BR";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else if(lowerCaseLang.hasPrefix("nl")) {
            if(lowerCaseLang == "nl-nl") {
                scriptLanguageCode = "nl_NL";
            }
            else if(lowerCaseLang == "nl-be") {
                scriptLanguageCode = "nl_BE";
            }
            else{
                scriptLanguageCode = "en_US";
            }
        }
        else {
            scriptLanguageCode = FTLanguageResourceMapper.matchedLanguage(forKey: lowerCaseLang)
        }
        return scriptLanguageCode;
    }
    private class func matchedLanguage(forKey languageCode: String) -> String{//languageCode: jp-us
        if let key = languageCode.components(separatedBy: "-").first {//key: jp
            let arrayLangList = ["bs_BA", "ceb_PH", "az_AZ", "no_NO", "sw_TZ", "fil_PH", "it_IT", "ja_JP", "ko_KR", "mg_MG", "af_ZA", "sq_AL", "hy_AM", "eu_ES", "be_BY", "bg_BG", "ca_ES", "hr_HR", "cs_CZ", "da_DK", "et_EE", "fi_FI", "gl_ES", "ka_GE", "el_GR", "hu_HU", "is_IS", "id_ID", "ga_IE", "kk_KZ", "lv_LV", "lt_LT", "mk_MK", "ms_MY", "mn_MN", "pl_PL", "ro_RO", "ru_RU", "sk_SK", "sl_SI", "sv_SE", "tt_RU", "tr_TR", "uk_UA", "vi_VN"]
            let filteredList = arrayLangList.filter({ $0.hasPrefix(key)})
            if !filteredList.isEmpty {
                return filteredList[0]
            }
        }
        return ""
    }
}

extension String {
    var nativeDisplayName: String {
        var nativeDisplayTitle = ""
        switch self {
        case "en_US":
            nativeDisplayTitle = "English (US)"
        case "en_GB":
            nativeDisplayTitle = "English (UK)"
        case "zh_CN":
            nativeDisplayTitle = "汉语（简体）"
        case "zh_TW":
            nativeDisplayTitle = "漢語（繁體）"
        case "de_DE":
            nativeDisplayTitle = "Deutsch"
        case "fr_FR":
            nativeDisplayTitle = "French(France)"
        case "fr_CA":
            nativeDisplayTitle = "Français (Canada)"
        case "es_ES":
            nativeDisplayTitle = "Español (España)"
        case "it_IT":
            nativeDisplayTitle = "Italiana"
        case "ja_JP":
            nativeDisplayTitle = "日本語"
        case "pt_PT":
            nativeDisplayTitle = "Português (Portugal)"
        case "ko_KR":
            nativeDisplayTitle = "한국어"
//==========================================================
        case "af_ZA":
            nativeDisplayTitle = "Afrikaners"
        case "sq_AL":
            nativeDisplayTitle = "shqiptar"
        case "hy_AM":
            nativeDisplayTitle = "հայերեն"
        case "az_AZ":
            nativeDisplayTitle = "Azərbaycan"
        case "eu_ES":
            nativeDisplayTitle = "Euskal"
        case "be_BY":
            nativeDisplayTitle = "беларускі"
        case "bg_BG":
            nativeDisplayTitle = "български"
        case "ca_ES":
            nativeDisplayTitle = "català"
        case "zh_HK":
            nativeDisplayTitle = "中國（香港）"
        case "hr_HR":
            nativeDisplayTitle = "Hrvatski"
        case "cs_CZ":
            nativeDisplayTitle = "čeština"
        case "da_DK":
            nativeDisplayTitle = "dansk"
        case "nl_BE":
            nativeDisplayTitle = "Nederlands (België)"
        case "nl_NL":
            nativeDisplayTitle = "Nederlands (Nederland)"
        case "en_CA":
            nativeDisplayTitle = "English(Canada)"
        case "et_EE":
            nativeDisplayTitle = "eesti"
        case "fi_FI":
            nativeDisplayTitle = "Suomalainen"
        case "gl_ES":
            nativeDisplayTitle = "galego"
        case "ka_GE":
            nativeDisplayTitle = "ქართული"
        case "de_AT":
            nativeDisplayTitle = "Deutsch (Österreich)"
        case "el_GR":
            nativeDisplayTitle = "Ελληνικά"
        case "hu_HU":
            nativeDisplayTitle = "Magyar"
        case "id_ID":
            nativeDisplayTitle = "bahasa Indonesia"
        case "ga_IE":
            nativeDisplayTitle = "Gaeilge"
        case "is_IS":
            nativeDisplayTitle = "Íslensku"
        case "kk_KZ":
            nativeDisplayTitle = "Қазақ"
        case "lv_LV":
            nativeDisplayTitle = "Latvijas"
        case "lt_LT":
            nativeDisplayTitle = "Lietuvos"
        case "mk_MK":
            nativeDisplayTitle = "Македонски"
        case "ms_MY":
            nativeDisplayTitle = "Malay"
        case "mn_MN":
            nativeDisplayTitle = "Монгол"
        case "no_NO":
            nativeDisplayTitle = "norsk"
        case "pl_PL":
            nativeDisplayTitle = "Polskie"
        case "pt_BR":
            nativeDisplayTitle = "Português (Brasil)"
        case "ro_RO":
            nativeDisplayTitle = "Română"
        case "ru_RU":
            nativeDisplayTitle = "русский"
        case "sr_Cyrl_RS":
            nativeDisplayTitle = "Српски језик (Ћирилица)"
        case "sr_Latn_RS":
            nativeDisplayTitle = "Српски (Ћирилица)"
        case "sk_SK":
            nativeDisplayTitle = "slovenský"
        case "sl_SI":
            nativeDisplayTitle = "Slovenščina"
        case "es_MX":
            nativeDisplayTitle = "Español (México)"
        case "sv_SE":
            nativeDisplayTitle = "svenska"
        case "tt_RU":
            nativeDisplayTitle = "Tatar"
        case "tr_TR":
            nativeDisplayTitle = "Türkçe"
        case "uk_UA":
            nativeDisplayTitle = "український"
        case "vi_VN":
            nativeDisplayTitle = "Tiếng Việt"
        case "sw_TZ":
            nativeDisplayTitle = "Swahili (Tanzania)"
        case "bs_BA":
            nativeDisplayTitle = "Bosanski"
        case "ceb_PH":
            nativeDisplayTitle = "Sugbo (Pilipinas)"
        case "en_PH":
            nativeDisplayTitle = "English (Philippines)"
        case "fil_PH":
            nativeDisplayTitle = "Filipino (Pilipinas)"
        case "mg_MG":
            nativeDisplayTitle = "Malagasy (Madagascar)"
        case "es_CO":
            nativeDisplayTitle = "Español (Colombia)"

//==========================================================
        case languageCodeNone:
            nativeDisplayTitle = NSLocalizedString("DisableRecognition", comment: "Disable Recog");
        default:
            nativeDisplayTitle = "English (US)"
        }
        return nativeDisplayTitle
    }
}
