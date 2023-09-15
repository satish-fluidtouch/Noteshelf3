//
//  FTLanguageResourceManager.swift
//  Noteshelf
//
//  Created by Naidu on 27/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//


let FTResourceDownloadStatusDidChange = "FTResourceDownloadStatusDidChange"
let FTRecognitionLanguageDidSelect = "FTRecognitionLanguageDidSelect"

import Combine

class FTLanguageResourceManager: NSObject {
    @objc static let shared:FTLanguageResourceManager = FTLanguageResourceManager()
    var languageResources: [FTRecognitionLangResource] = []
    var lastSelectedLangCode: String = "" {
        didSet{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTRecognitionLanguageDidSelect), object: nil)
        }
    }
    fileprivate var fileHandler: FTLogger?
    private var premiumCancellableEvent: AnyCancellable?

    private override init() {
        super.init()
        // Once non premiumuser becomes premium, need to enable writing recognition
        if !FTIAPManager.shared.premiumUser.isPremiumUser {
            premiumCancellableEvent = FTIAPManager.shared.premiumUser.$isPremiumUser
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isPremium in
                    if isPremium {
                        self?.activateOnDemandResourcesIfNeeded()
                    }
                }
        }
    }

    var currentLanguageCode: String? {
        get{
            return UserDefaults.standard.value(forKey: "currentLanguageCode") as? String
        }
        set{
            var shouldFire = false
            if self.currentLanguageCode != newValue {
                shouldFire = true
            }
            UserDefaults.standard.setValue(newValue, forKey: "currentLanguageCode")
            UserDefaults.standard.synchronize()
            if(shouldFire){
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: FTRecognitionLanguageDidChange), object: nil)
            }
        }
    }
    var isPreferredLanguageChosen: Bool {
        get{
            return UserDefaults.standard.bool(forKey: "isPreferredLanguageChosen")
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "isPreferredLanguageChosen")
            UserDefaults.standard.synchronize()
        }
    }

    var currentLanguageDisplayName: String {
        var languageCodeToDisplay = self.currentLanguageCode
        if !self.lastSelectedLangCode.isEmpty {
            languageCodeToDisplay = self.lastSelectedLangCode
        }
        let language = self.languageResources.first(where: ({$0.languageCode == languageCodeToDisplay}));
        if let _language = language {
            var name: String = _language.displayName;
            if _language.languageCode == languageCodeNone {
                name = _language.nativeDisplayName;
            }
            return name
        }
        return ""
    }
    private lazy var availableLanguageResources:[FTRecognitionLangResource] = {
        var languages:[FTRecognitionLangResource] = []
        languages.append(FTRecognitionLangResource.init(with: "EnglishUS", languageCode: "en_US", eventLanguageName: "EnglishUS"))
        languages.append(FTRecognitionLangResource.init(with: "EnglishUK", languageCode: "en_GB", eventLanguageName: "EnglishUK"))
        languages.append(FTRecognitionLangResource.init(with: "ChineseS", languageCode: "zh_CN", eventLanguageName: "ChineseSimp"))
        languages.append(FTRecognitionLangResource.init(with: "ChineseT", languageCode: "zh_TW", eventLanguageName: "ChineseTrad"))
        languages.append(FTRecognitionLangResource.init(with: "Chinese(Hong Kong)", languageCode: "zh_HK", eventLanguageName: "ChineseHK"))
        languages.append(FTRecognitionLangResource.init(with: "German", languageCode: "de_DE", eventLanguageName:"German"))
        languages.append(FTRecognitionLangResource.init(with: "French", languageCode: "fr_FR", eventLanguageName:"French"))
        languages.append(FTRecognitionLangResource.init(with: "Spanish", languageCode: "es_ES", eventLanguageName:"Spanish"))
        languages.append(FTRecognitionLangResource.init(with: "Spanish(Mexico)", languageCode: "es_MX", eventLanguageName:"SpanishMex"))
        languages.append(FTRecognitionLangResource.init(with: "Spanish(Colombia)", languageCode: "es_CO", eventLanguageName:"SpanishClmb"))
        languages.append(FTRecognitionLangResource.init(with: "Italian", languageCode: "it_IT", eventLanguageName:"Italian"))
        languages.append(FTRecognitionLangResource.init(with: "Japanese", languageCode: "ja_JP", eventLanguageName:"Japanese"))
        languages.append(FTRecognitionLangResource.init(with: "Portugal", languageCode: "pt_PT", eventLanguageName:"Portuguese"))
        languages.append(FTRecognitionLangResource.init(with: "Korean", languageCode: "ko_KR", eventLanguageName:"Korean"))
        
        languages.append(FTRecognitionLangResource.init(with: "Africans", languageCode: "af_ZA", eventLanguageName:"Afrikaans"))
        languages.append(FTRecognitionLangResource.init(with: "Albanian", languageCode: "sq_AL", eventLanguageName:"Albanian"))
        languages.append(FTRecognitionLangResource.init(with: "Armenian", languageCode: "hy_AM", eventLanguageName:"Armenian"))
        languages.append(FTRecognitionLangResource.init(with: "Azeri", languageCode: "az_AZ", eventLanguageName:"Azeri"))
        languages.append(FTRecognitionLangResource.init(with: "Basque", languageCode: "eu_ES", eventLanguageName:"Basque"))
        languages.append(FTRecognitionLangResource.init(with: "Belarusian", languageCode: "be_BY", eventLanguageName:"Belarusian"))
        languages.append(FTRecognitionLangResource.init(with: "Bulgarian", languageCode: "bg_BG", eventLanguageName:"Bulgarian"))
        languages.append(FTRecognitionLangResource.init(with: "Bosnian", languageCode: "bs_BA", eventLanguageName:"Bosnian"))
        languages.append(FTRecognitionLangResource.init(with: "Catalan", languageCode: "ca_ES", eventLanguageName:"Catalan"))
        languages.append(FTRecognitionLangResource.init(with: "Cebuano(Philippines)", languageCode: "ceb_PH", eventLanguageName:"Cebuano"))
        languages.append(FTRecognitionLangResource.init(with: "Croatian", languageCode: "hr_HR", eventLanguageName:"Croatian"))
        languages.append(FTRecognitionLangResource.init(with: "Czech", languageCode: "cs_CZ", eventLanguageName:"Czech"))
        languages.append(FTRecognitionLangResource.init(with: "Danish", languageCode: "da_DK", eventLanguageName:"Danish"))
        languages.append(FTRecognitionLangResource.init(with: "Dutch(Belgium)", languageCode: "nl_BE", eventLanguageName:"DutchBelg"))
        languages.append(FTRecognitionLangResource.init(with: "Dutch(Netherlands)", languageCode: "nl_NL", eventLanguageName:"DutchNethL"))
        languages.append(FTRecognitionLangResource.init(with: "English(Canada)", languageCode: "en_CA", eventLanguageName:"EnglishCa"))
        languages.append(FTRecognitionLangResource.init(with: "English(Philippines)", languageCode: "en_PH", eventLanguageName:"EnglishPhil"))
        languages.append(FTRecognitionLangResource.init(with: "Estonian", languageCode: "et_EE", eventLanguageName:"Estonian"))
        languages.append(FTRecognitionLangResource.init(with: "Filipino(Philippines)", languageCode: "fil_PH", eventLanguageName:"Filipino"))
        languages.append(FTRecognitionLangResource.init(with: "Finnish", languageCode: "fi_FI", eventLanguageName:"Finnish"))
        languages.append(FTRecognitionLangResource.init(with: "French(Canada)", languageCode: "fr_CA", eventLanguageName:"FrenchCan"))
        languages.append(FTRecognitionLangResource.init(with: "Galician", languageCode: "gl_ES", eventLanguageName:"Galician"))
        languages.append(FTRecognitionLangResource.init(with: "Georgian", languageCode: "ka_GE", eventLanguageName:"Georgian"))
        languages.append(FTRecognitionLangResource.init(with: "German(Austria)", languageCode: "de_AT", eventLanguageName:"GermanAus"))
        languages.append(FTRecognitionLangResource.init(with: "Greek", languageCode: "el_GR", eventLanguageName:"Greek"))
        languages.append(FTRecognitionLangResource.init(with: "Hungarian", languageCode: "hu_HU", eventLanguageName:"Hungarian"))
        languages.append(FTRecognitionLangResource.init(with: "Indonesian", languageCode: "id_ID", eventLanguageName:"Indonesian"))
        languages.append(FTRecognitionLangResource.init(with: "Irish", languageCode: "ga_IE", eventLanguageName:"Irish"))
        languages.append(FTRecognitionLangResource.init(with: "Islandic", languageCode: "is_IS", eventLanguageName:"Islandic"))
        languages.append(FTRecognitionLangResource.init(with: "Kazakh", languageCode: "kk_KZ", eventLanguageName:"Kazakh"))
        languages.append(FTRecognitionLangResource.init(with: "Latvian", languageCode: "lv_LV", eventLanguageName:"Latvian"))
        languages.append(FTRecognitionLangResource.init(with: "Lithuanian", languageCode: "lt_LT", eventLanguageName:"Lithuanian"))
        languages.append(FTRecognitionLangResource.init(with: "Macedonian", languageCode: "mk_MK", eventLanguageName:"Macedonian"))
        languages.append(FTRecognitionLangResource.init(with: "Malagasy(Madagascar)", languageCode: "mg_MG", eventLanguageName:"Malagasy"))
        languages.append(FTRecognitionLangResource.init(with: "Malay", languageCode: "ms_MY", eventLanguageName:"Malay"))
        languages.append(FTRecognitionLangResource.init(with: "Mongolian", languageCode: "mn_MN", eventLanguageName:"Mongolian"))
        languages.append(FTRecognitionLangResource.init(with: "Norwegian", languageCode: "no_NO", eventLanguageName:"Norwegian"))
        languages.append(FTRecognitionLangResource.init(with: "Polish", languageCode: "pl_PL", eventLanguageName:"Polish"))
        languages.append(FTRecognitionLangResource.init(with: "Portuguese(Brazil)", languageCode: "pt_BR", eventLanguageName:"PortgBrazil"))
        languages.append(FTRecognitionLangResource.init(with: "Romanian", languageCode: "ro_RO", eventLanguageName:"Romanian"))
        languages.append(FTRecognitionLangResource.init(with: "Russian", languageCode: "ru_RU", eventLanguageName:"Russian"))
        languages.append(FTRecognitionLangResource.init(with: "Serbian(Cyrillic)", languageCode: "sr_Cyrl_RS", eventLanguageName:"SerbianCyr"))
        languages.append(FTRecognitionLangResource.init(with: "Serbian(Latin)", languageCode: "sr_Latn_RS", eventLanguageName:"SerbianLat"))
        languages.append(FTRecognitionLangResource.init(with: "Slovak", languageCode: "sk_SK", eventLanguageName:"Slovak"))
        languages.append(FTRecognitionLangResource.init(with: "Slovenian", languageCode: "sl_SI", eventLanguageName:"Slovenian"))
        languages.append(FTRecognitionLangResource.init(with: "Swahili(Tanzania)", languageCode: "sw_TZ", eventLanguageName:"Swahili"))
        languages.append(FTRecognitionLangResource.init(with: "Swedish", languageCode: "sv_SE", eventLanguageName:"Swedish"))
        languages.append(FTRecognitionLangResource.init(with: "Tatar", languageCode: "tt_RU", eventLanguageName:"Tatar"))
        languages.append(FTRecognitionLangResource.init(with: "Turkish", languageCode: "tr_TR", eventLanguageName:"Turkish"))
        languages.append(FTRecognitionLangResource.init(with: "Ukrainian", languageCode: "uk_UA", eventLanguageName:"Ukranian"))
        languages.append(FTRecognitionLangResource.init(with: "Vietnamese", languageCode: "vi_VN", eventLanguageName:"Vietnamese"))
        languages.append(FTRecognitionLangResource.init(with: "DisableRecognition", languageCode: languageCodeNone, eventLanguageName:""))
        return languages
    }()
    
    @objc func activateOnDemandResourcesIfNeeded(){ // Wehen we set a language for hand-writing recogntion, it needs to be ready if it is an on demand resource
        if FTIAPManager.shared.premiumUser.isPremiumUser
            , !UserDefaults.standard.isHWlLanguageSet  {
            if self.currentLanguageCode == languageCodeNone {
                self.currentLanguageCode = nil
            }
            UserDefaults.standard.isHWlLanguageSet = true
        }

        self.languageResources = self.availableLanguageResources
        
        if self.currentLanguageCode == nil{
            let currentLangCode = FTLanguageResourceMapper.currentScriptLanguageCode()
            if currentLangCode == "en_US" || currentLangCode == languageCodeNone {
                self.currentLanguageCode = currentLangCode
                self.isPreferredLanguageChosen = true
            }
            else
            {
                let filteredLanguages = self.languageResources.filter({$0.languageCode == currentLangCode})
                if filteredLanguages.isEmpty == false
                {
                    let currentLanguage = filteredLanguages.first!
                    currentLanguage.downloadCompletionCallback = {
                        if FTLanguageResourceManager.shared.currentLanguageCode == nil{
                            FTLanguageResourceManager.shared.currentLanguageCode = currentLanguage.languageCode
                            FTLanguageResourceManager.shared.isPreferredLanguageChosen = true //Assuming this is automatic resource request, so setting isPreferredLanguageChosen to true
                        }
                    }
                    currentLanguage.downloadResourceOnDemand()
                }
            }
        }
    }

    @objc func warnLanguageSelectionIfNeeded(onController controller: UIViewController){
        //==========================================
        if (self.isPreferredLanguageChosen || self.currentLanguageCode == nil || (self.currentLanguageCode != nil && self.currentLanguageCode != "en_US")) {
            return
        }
        
        FTTooltipsManager.sharedManager().destroyVisibleTooltips()
        let alertController = UIAlertController.init(title: NSLocalizedString("HandwritingLanguageChangeInfo", comment: "Your handwriting recognition..."), message: nil, preferredStyle: .alert);
        let keepAction = UIAlertAction.init(title: NSLocalizedString("KeepEnglishOnly", comment: "Keep English Only"), style: .default) { (_) in
            FTLanguageResourceManager.shared.isPreferredLanguageChosen = true
        };
        alertController.addAction(keepAction);
        
        let changeAction = UIAlertAction.init(title: NSLocalizedString("ChangeLanguage", comment: "Change"), style: .default) { [weak controller] (_) in
            FTLanguageResourceManager.shared.isPreferredLanguageChosen = true
            self.forceDisplayLanguageSettingsController(onController: controller)
        };
        alertController.addAction(changeAction);
        controller.present(alertController, animated: true, completion: nil);
        //==========================================
    }

    func forceDisplayLanguageSettingsController(onController : UIViewController?) {
        if let controller = onController {
            let storyboard = UIStoryboard(name: "FTNewSettings", bundle: nil);
            if let settingsController = storyboard.instantiateViewController(withIdentifier: FTRecognitionLanguageViewController.className) as? FTRecognitionLanguageViewController  {
                let navController = UINavigationController(rootViewController: settingsController)
                navController.modalPresentationStyle = .formSheet
                controller.present(navController, animated: true, completion: nil)
            }
        }
    }
}

extension FTLanguageResourceManager{
    func writeLogString(_ newLog:String, currentDocument:FTNoteshelfDocument?)
    {
        if(nil == self.fileHandler) {
            self.fileHandler = FTLogger.init(fileName: "RecognitionLog", createIfNeeded: true);
        }
        self.fileHandler?.log((currentDocument?.documentName ?? "") + " : " + newLog, truncateIfNeeded: true, addTime: true);
        #if DEBUG
        debugPrint("Log:: \(newLog)");
        #endif
    }
    
}

private extension UserDefaults {
    var isHWlLanguageSet: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isManuallyDisabledRecognition")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isManuallyDisabledRecognition")
            UserDefaults.standard.synchronize()
        }
    }
}
