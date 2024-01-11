//
//  FTTheme.swift
//  FTTemplatePicker
//
//  Created by Sameer on 24/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit
import FTCommon
import FTNewNotebook

enum FTSelectedThemeType: String {
    case covers = "covers"
    case papers = "papers"
    case noCover = "noCover"
}

protocol FTPaperThemeable: FTThemeable {
    func setPaperVariants(_ variants: FTPaperVariants?)
    var  recentVariants: FTPaperVariants!{get}
    var  customvariants: FTPaperVariants!{get}
}

class FTTheme: NSObject, FTThemeable {

    var id: String = UUID().uuidString

    var isCustom: Bool = false
    var dynamicId: Int = 0
    var canDelete: Bool = false
    var restrictsChangeTemplate : Bool = false
    var hasCover: Bool = false
    private var _displayName: String = "No Title"
    var displayName: String {
        get {
            NSLocalizedString(_displayName, comment: _displayName)
        }
        set {
            _displayName = newValue
        }
    }
    private(set) var themeFileURL : URL
    var categoryName : String = "No Category";
    var annotationInfo : [String : Any]?;
    var isRecent : Bool = false
    var isFavorite: Bool = false
    fileprivate var overlayImageURL : URL?;
    private(set) var footerOption = FTPageFooterOption.show;

    var eventTrackName: String = "" //Used for tracking selected template name in all languages to be in english only

    class func theme(url : URL, themeType: FTSelectedThemeType) -> FTTheme? {
        var themeObj : FTTheme?
        if FileManager.init().fileExists(atPath: url.path) {
            if themeType == FTSelectedThemeType.covers {
                themeObj = FTCoverTheme.init(url: url)
                themeObj?.hasCover = true
            } else if themeType == FTSelectedThemeType.papers {
                themeObj = FTPaperTheme.paperTheme(url: url)
            } else if themeType == .noCover {
                themeObj = FTNoCoverTheme.init(url: url)
            }
            let metaDataURL = url.appendingPathComponent("metadata.plist");
            if let metaData =  NSDictionary(contentsOf: metaDataURL) {
                let currentLang = FTCommonUtils.currentLanguage()

                // display name
                if let themeObj = themeObj {
                    let defaultDisplayNameKey = "display_name"
                    let localizedDisplayNamekey = defaultDisplayNameKey + "_" + currentLang;
                    if let display_name = metaData.value(forKey: localizedDisplayNamekey) as? String {
                        themeObj.displayName = display_name
                    } else if let display_name = metaData.value(forKey: defaultDisplayNameKey) as? String {
                        themeObj.displayName = display_name
                    }

                    //category name is added to support downloaded themes logic in FTNThemesLibrary. Need to revisit it
                    let defaultCatName = "category_name";
                    let locCatName = defaultCatName.appending("_").appending(currentLang);
                    if let category_name = metaData.value(forKey: locCatName) as? String {
                        themeObj.categoryName = category_name;
                    } else if let category_name = metaData.value(forKey: defaultCatName) as? String {
                        themeObj.categoryName = category_name;
                    }
                    if let dynamicId = (metaData.value(forKey: "dynamic_id") as? Int) {
                        themeObj.dynamicId = dynamicId
                    }
                    if let annotationInfo = metaData.value(forKey: "annotationInfo") {
                        themeObj.annotationInfo = annotationInfo as? [String : Any]
                    }
                    if let footerOption = metaData.value(forKey: "footer_option") as? Int {
                        themeObj.footerOption = FTPageFooterOption(rawValue: footerOption)!
                    }

                    if themeObj.isValidTheme() {
                        return themeObj;
                    }
                }
            }
        }
        return themeObj
    }

    init(url: URL) {
        themeFileURL = url;
        super.init();
    }

    private func themeOverlayImageURL() -> URL?{
        let overlayImageURL = self.themeFileURL.screenScaleURL(for: "overlay.png");
        return overlayImageURL;
    }

    class func getRecentTheme(url: URL, _ variants: FTPaperVariants?) -> FTPaperTheme? {
        if FileManager.init().fileExists(atPath: url.path) {
            let theme = FTTheme.theme(url: url, themeType: FTSelectedThemeType.papers)
            if let paperThemeObj = theme as? FTPaperTheme{
                paperThemeObj.themeFileURL = url
                paperThemeObj.recentVariants = variants
                return paperThemeObj
            }
        }
        return nil
    }

    class func getFavoriteTheme(url: URL, _ variants: FTPaperVariants?) -> FTPaperTheme? {
        return self.getRecentTheme(url: url, variants)
    }

    func isTransparent12Cover() -> Bool {
        if self.themeFileURL.lastPathComponent == "Transparent12.nsc" {
            return true
        }
        return false
    }

    func isClearWhiteCover() -> Bool {
        if self.themeFileURL.lastPathComponent == "Transparent0.nsc" {
            return true
        }
        return false
    }

    func isValidTheme() -> Bool {
        return true;
    }

    //MARK:- FTThemeable Protocol Implementations
    func themeTemplateURL() -> URL {
        NSException.init(name: NSExceptionName(rawValue: "Theme"), reason: "subclass should override ", userInfo: nil).raise();
        return URL(string: "")!;
    }

    func themeThumbnail() -> UIImage {
        NSException.init(name: NSExceptionName(rawValue: "Theme"), reason: "subclass should override ", userInfo: nil).raise();
        return UIImage()
    }

    func preview() async -> UIImage? {
        NSException.init(name: NSExceptionName(rawValue: "Theme"), reason: "subclass should override ", userInfo: nil).raise()
        return nil
    }

    var overlayImage: UIImage? {
        if let thumbURL = self.themeOverlayImageURL(){
            self.overlayImageURL = thumbURL;
            return UIImage.init(contentsOfFile: thumbURL.path);
        }
        return nil
    };
    func deleteThumbnailFromCache() {
        NSException.init(name: NSExceptionName(rawValue: "Theme"), reason: "subclass should override ", userInfo: nil).raise();
    }
}

extension URL {
    func screenScaleURL(for name:String) -> URL? {
        var imageURL: URL?
        let fileExt = name.pathExtension
        let fileName = name.deletingPathExtension

        var screenScale = UIScreen.main.scale;
        if screenScale == 1{
            screenScale = 2.0
        }
        let fileManager = FileManager();
        var screenIntValue = Int(screenScale);
        var overlayImagePath = self.appendingPathComponent("\(fileName)@\(screenIntValue)x.\(fileExt)");
        while ((screenIntValue > 0) && (!fileManager.fileExists(atPath: overlayImagePath.path))) {
            screenIntValue -= 1;
            overlayImagePath = self.appendingPathComponent("\(fileName)@\(screenIntValue)x.\(fileExt)");
        }
        if (fileManager.fileExists(atPath: overlayImagePath.path)) {
            imageURL = overlayImagePath;
        }
        return imageURL;
    }
}
