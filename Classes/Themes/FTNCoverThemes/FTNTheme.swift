//
//  FTNTheme.swift
//  Noteshelf
//
//  Created by Amar on 29/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNTheme: NSObject, FTThemeable
{
    fileprivate let defaultLanguageID = "en";

    var themeFileURL : URL!;
    fileprivate var thumbnailURL : URL!;
    fileprivate var overlayImageURL : URL?;
    fileprivate var themeName : String!;
    var categoryName : String?;
    var isLandscape : Bool = false
    var overlayType : Int = 0
    var documentType : FTDocumentType = .defaultType;
    var diaryStartYear : Int?

    var annotationInfo : [String : Any]?;
    
    var diplayName : String! {
        return self.themeName;
    };

    var canDelete = false;
    var lineHeight : Int?;
    var themeSize : CGSize?;
    fileprivate var themeFooterOption = FTPageFooterOption.show;
    var footerOption : FTPageFooterOption! {
        return self.themeFooterOption;
    }
    
    var dynamicId: Int = 0

    class func theme(_ themeName : String = "",url : URL) -> FTNTheme?
    {
        var themeToReurn : FTNTheme?;
        let ext = url.pathExtension;
        if(FileManager.init().fileExists(atPath: url.path)) {
            if(ext == "nsp") {
                themeToReurn = FTNPaperTheme.theme(url: url);
                themeToReurn!.themeFileURL = url;
                themeToReurn!.themeName = themeName;
            }
            else if(ext == "nsc")
            {
                themeToReurn = FTNCoverTheme();
                themeToReurn!.themeFileURL = url;
                themeToReurn!.themeName = themeName;
            }
            let metaDataURL = url.appendingPathComponent("metadata.plist");
            if FileManager.init().fileExists(atPath: metaDataURL.path), let metaData = NSDictionary(contentsOf: metaDataURL) {
                let currentLang = FTUtils.currentLanguage();
                let defaultDisplayNameKey = "display_name";
                let localizedDisplayNamekey = defaultDisplayNameKey + "_" + currentLang;

                if let display_name = metaData.value(forKey: localizedDisplayNamekey) as? String {
                    themeToReurn!.themeName = display_name;
                }
                else if let display_name = metaData.value(forKey: defaultDisplayNameKey) as? String {
                    themeToReurn!.themeName = display_name;
                }
                
                //category name
                let defaultCatName = "category_name";
                let locCatName = defaultCatName.appending("_").appending(currentLang);
                if let category_name = metaData.value(forKey: locCatName) as? String {
                    themeToReurn!.categoryName = category_name;
                }
                else if let category_name = metaData.value(forKey: defaultCatName) as? String {
                    themeToReurn!.categoryName = category_name;
                }
                if let line_height = metaData.value(forKey: "line_height") as? Int, line_height > 0 {
                    themeToReurn!.lineHeight = line_height;
                }

                if let footerOption = metaData.value(forKey: "footer_option") as? Int {
                    themeToReurn!.themeFooterOption = FTPageFooterOption(rawValue: footerOption)!;
                }

                if let type = metaData.value(forKey: "template_type") as? Int {
                    themeToReurn!.documentType = FTDocumentType(rawValue: type)!;
                }
                
                if let year = metaData.value(forKey: "startYear") as? String {
                    themeToReurn!.diaryStartYear = Int(year)
                }
                
                if let dynamicId = metaData.value(forKey: "dynamic_id") as? Int {
                    themeToReurn!.dynamicId = dynamicId
                }
                
                //============================
                //For new type of diary templates of type .dailyAndWeeklyPlanner
                if let postProcessInfo = metaData.value(forKey: "postProcessInfo") as? [String: Any] {
                    if let type = postProcessInfo["template_type"] as? Int {
                        themeToReurn!.documentType = FTDocumentType(rawValue: type)!;
                    }
                    if let startDateString = postProcessInfo["startDate"] as? String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy";
                        if let startDate = formatter.date(from: startDateString) {
                            let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
                            let components = calendar.dateComponents([.year], from: startDate)
                            let year = components.year
                            themeToReurn!.diaryStartYear = year
                        }
                    }
                }
                //============================


                let width = metaData.deviceSpecificWidth;
                let height = metaData.deviceSpecificHeight;
                if (width > 0 && height > 0) {
                    themeToReurn!.themeSize = CGSize(width: width, height: height);
                    themeToReurn!.isLandscape = (width > height);
                }
                if let overlayType = metaData.value(forKey: "overlay_type") as? NSNumber {
                    themeToReurn!.overlayType = overlayType.intValue;
                }

                themeToReurn?.annotationInfo = metaData.value(forKey: "annotationInfo") as? [String : Any];
            }
        }
        if let theme = themeToReurn, theme.isValidTheme() {
            return theme;
        }
        else if let theme = themeToReurn {
            #if !NS2_SIRI_APP
            var param = [String : Any]();
            if let dispName = theme.diplayName {
                param["themeName"] = dispName;
            }
            if let lastPathCom = theme.themeFileURL?.lastPathComponent {
                param["pathComponent"] = lastPathCom;
            }
            track("invalid_theme", params: param, shouldLog: false);
            #endif
        }
        return nil;
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

    func themeThumbnailURL() -> URL
    {
        var thumbURL : URL!;
        
        let screenScale = UIScreen.main.scale;
        if(screenScale == 1) {
            thumbURL = self.themeFileURL?.appendingPathComponent("thumbnail.png");
        }
        else {
            var screenIntValue = Int(screenScale);
            var thumbPath = self.themeFileURL?.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
            
            while ((screenIntValue > 0) && (!FileManager.default.fileExists(atPath: thumbPath!.path))) {
                screenIntValue -= 1;
                thumbPath = self.themeFileURL?.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
            }
            
            if(FileManager.default.fileExists(atPath: thumbPath!.path)) {
                thumbURL = thumbPath!;
            }
        }
        
        if(nil == thumbURL) {
            if(self is FTNPaperTheme) {
                thumbURL = Bundle.main.url(forResource: "default_paper_image", withExtension: "png");
            }
            else {
                thumbURL = Bundle.main.url(forResource: "default_cover_image", withExtension: "png");
            }
        }
        return thumbURL;
    }
    func themeOverlayImageURL() -> URL?{
        var overlayImageURL : URL?;
        
        let screenScale = UIScreen.main.scale;
        if(screenScale == 1) {
            overlayImageURL = self.themeFileURL?.appendingPathComponent("overlay.png");
        }else {
            var screenIntValue = Int(screenScale);
            var overlayImagePath = self.themeFileURL?.appendingPathComponent("overlay@\(screenIntValue)x.png");
            
            while ((screenIntValue > 0) && (!FileManager.default.fileExists(atPath: overlayImagePath!.path))) {
                screenIntValue -= 1;
                overlayImagePath = self.themeFileURL?.appendingPathComponent("overlay@\(screenIntValue)x.png");
            }
            
            if(overlayImagePath != nil && FileManager.default.fileExists(atPath: overlayImagePath!.path)) {
                overlayImageURL = overlayImagePath!;
            }
        }
        return overlayImageURL;
    }
    
    func themeThumbnail() -> UIImage {
        let thumbURL = self.themeThumbnailURL();
        self.thumbnailURL = thumbURL;
        return UIImage.init(contentsOfFile: thumbURL.path)!;
    };
    var overlayImage: UIImage? {
        if let thumbURL = self.themeOverlayImageURL(){
            self.overlayImageURL = thumbURL;
            return UIImage.init(contentsOfFile: thumbURL.path);
        }
        return nil
    };
    func themeTemplateURL() -> URL {
        NSException.init(name: NSExceptionName(rawValue: "Theme"), reason: "subclass should override ", userInfo: nil).raise();
        return URL(string: "")!;
    }
    
    //MARK:- Equatable
    override func isEqual(_ object: Any?) -> Bool {
        if let inputTheme = object as? FTNTheme,
        inputTheme.themeTemplateURL().resolvingSymlinksInPath() == self.themeTemplateURL().resolvingSymlinksInPath() {
            return true;
        }
        return false;
    }
    
    func isValidTheme() -> Bool
    {
        return true;
    }
}

class FTNCoverTheme : FTNTheme
{
    override func themeTemplateURL() -> URL {
        if(nil == self.thumbnailURL) {
            self.thumbnailURL = self.themeThumbnailURL();
        }
        return self.thumbnailURL;
    }
    
    override func isValidTheme() -> Bool {
        
        var templateURL : URL?;
        let screenScale = UIScreen.main.scale;
        if(screenScale == 1) {
            templateURL = self.themeFileURL?.appendingPathComponent("thumbnail.png");
        }
        else {
            if let themeURL = self.themeFileURL {
                var screenIntValue = Int(screenScale);
                var tempURL = themeURL.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
                while ((screenIntValue > 0) && (!FileManager.default.fileExists(atPath: tempURL.path))) {
                    screenIntValue -= 1;
                    tempURL = themeURL.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
                }
                templateURL = tempURL;
            }
        }

        if let tempURL = templateURL {
            return FileManager().fileExists(atPath: tempURL.path);
        }
        return false;
    }
}

class FTNPaperTheme : FTNTheme
{
    class func theme(url: URL) -> FTNTheme? {
        let metaDataURL = url.appendingPathComponent("metadata.plist");
        if FileManager.default.fileExists(atPath: metaDataURL.standardizedFileURL.path), let metaData = NSDictionary(contentsOf: metaDataURL) {
            if let dynamicId = (metaData.value(forKey: "dynamic_id") as? Int) {
                if dynamicId == 1 {
                    return FTNAutoTemlpateDiaryTheme.init(metaData: metaData);
                } else {
                    #if !NS2_SIRI_APP
                    return FTNDynamicTemplateTheme.init(metaData: metaData);
                    #else
                    return FTNPaperTheme.init();
                    #endif
                }
            }
        }
        
        return FTNPaperTheme.init();
    }
    
    override init() {
        super.init()
    }
    
    init(metaData : NSDictionary) {
        super.init()
    }
    
    override  func themeTemplateURL() -> URL {
        var templateURL : URL?;
        let pdfTemplate = self.themeFileURL?.appendingPathComponent("template.pdf");
        let packageTemplate = self.themeFileURL?.appendingPathComponent("template.noteshelf");

        let pdfTemplateDeviceSpecific = self.themeFileURL?.appendingPathComponent(self.deviceSpecificTemplateName());
        
        if(FileManager.default.fileExists(atPath: pdfTemplateDeviceSpecific!.path)) {
            templateURL = pdfTemplateDeviceSpecific;
        } else if(FileManager.default.fileExists(atPath: pdfTemplate!.path)) {
            templateURL = pdfTemplate;
        } else if(FileManager.default.fileExists(atPath: packageTemplate!.path)) {
            templateURL = packageTemplate;
        }
        
        return templateURL!;
    }
    
    fileprivate func deviceSpecificTemplateName() -> String
    {
        let deviceSpecificKey = UIDevice.deviceSpecificKey();
        return "template_\(deviceSpecificKey).pdf"
    }
    
    override func isValidTheme() -> Bool {
        var fileExisits = false;
        if let templateURL = self.themeFileURL?.appendingPathComponent("template.pdf") {
            fileExisits = FileManager().fileExists(atPath: templateURL.path);
        }
        if !fileExisits,let templateURL = self.themeFileURL?.appendingPathComponent("template.noteshelf") {
            fileExisits = FileManager().fileExists(atPath: templateURL.path);
        }
        if !fileExisits{
            fileExisits = self.dynamicId != 0
        }
        return fileExisits;
    }

}

extension UIDevice
{
    static func deviceSpecificKey() -> String
    {
        let mainScreen = UIScreen.main;
        var screenBounds = mainScreen.bounds;
        screenBounds = mainScreen.coordinateSpace.convert(screenBounds, to: mainScreen.fixedCoordinateSpace);
        let width = Int(screenBounds.width);
        let height = Int(screenBounds.height);
        return "\(width)_\(height)"
    }
}

fileprivate extension NSDictionary
{
    var deviceSpecificWidth : CGFloat
    {
        var width : CGFloat = 0;
        
        let defaultWidthKey = "width";
        let deviceSpecificKey = UIDevice.deviceSpecificKey();
        let widthKey = defaultWidthKey.appending("_\(deviceSpecificKey)");
        
        if let widthValue = self.value(forKey: widthKey) as? CGFloat, widthValue > 0 {
            width = widthValue;
        }
        else if let widthValue = self.value(forKey: defaultWidthKey) as? CGFloat, widthValue > 0 {
            width = widthValue;
        }
        return width
    }
    
    var deviceSpecificHeight : CGFloat
    {
        var height : CGFloat = 0;
        
        let defaultheightKey = "height";
        let deviceSpecificKey = UIDevice.deviceSpecificKey();
        let heightKey = defaultheightKey.appending("_\(deviceSpecificKey)");
        
        if let heightValue = self.value(forKey: heightKey) as? CGFloat, heightValue > 0 {
            height = heightValue;
        }
        else if let heightValue = self.value(forKey: defaultheightKey) as? CGFloat, heightValue > 0 {
            height = heightValue;
        }
        return height
    }
}

class FTNAutoTemlpateDiaryTheme : FTNPaperTheme
{
    var templateId: String = "Cassic"
    var startDate: Date?
    var endDate: Date?
    
    override init(metaData : NSDictionary) {
        super.init(metaData: metaData)
        if let dynamicId = metaData.value(forKey: "dynamic_id") as? Int {
            self.dynamicId = dynamicId;
        }
        
        if let templateId = metaData.value(forKey: "template_id") as? String {
            self.templateId = templateId
        }
    }
    
    override func themeTemplateURL() -> URL {
        return URL(string: "FTNAutoTemlpateDiaryTheme_template")!
    }
}

class FTNDynamicTemplateTheme: FTNPaperTheme {
    var templateInfoDict: NSDictionary?
    
    override init(metaData: NSDictionary) {
        super.init(metaData: metaData)
        
        if let dynamicId = metaData.value(forKey: "dynamic_id") as? Int {
            self.dynamicId = dynamicId;
        }
        
        if let dict = metaData.value(forKey: "dynamic_template_info") as? NSDictionary {
            self.templateInfoDict = dict
        }
    }
    
    override func themeTemplateURL() -> URL {
        return URL(string: "FTNDynamicTemlpateDiaryTheme_template")!
    }
}
