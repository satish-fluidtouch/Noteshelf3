//
//  FTMidnightThemeAssetGenerator.swift
//  Beizerpaths
//
//  Created by Ramakrishna on 05/05/21.
//

import Foundation
import UIKit

class FTDigitalDiaryInfo : NSObject {
    var customVariants : FTPaperVariants
    init(variants: FTPaperVariants) {
        self.customVariants = variants
    }
    var screenSize : CGSize {
       return FTMidnightDairyFormat.getScreenSize(fromVariants: self.customVariants)
    }
    func getTemplateBackgroundColor() -> UIColor {
        NSException.init(name: NSExceptionName(rawValue: "DigitalDiaryTemplateBGColor"), reason: "subclass should override ", userInfo: nil).raise();
         return UIColor()
    }
}

class FTMidnightDiaryInfo : FTDigitalDiaryInfo {
    
    var templateType : FTDigitalDiaryTemplateType
    
    init(templateType : FTDigitalDiaryTemplateType, customVariants variants : FTPaperVariants){
        self.templateType = templateType
        super.init(variants: variants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return  UIColor(red: 29/255, green: 35/255, blue: 47/255, alpha: 1.0)
    }
}
class FTMidnightDiaryTemplateAssetGenerator : NSObject {
    
    var templateFormat : FTMidnightDiaryTemplateFormat;
    var templateInfo : FTMidnightDiaryInfo;

    init(templateInfo : FTMidnightDiaryInfo){
        self.templateInfo = templateInfo
        self.templateFormat = FTMidnightDiaryTemplateFormat.getFormatFrom(templateInfo: templateInfo)
    }
    func generate() -> URL {
        let orientation = (templateInfo.customVariants.isLandscape) ? "Land" : "Port"
        let screenType = templateInfo.customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTMidnightDairyFormat.getScreenSize(fromVariants: templateInfo.customVariants)
        let key = templateInfo.templateType.displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
            + "\(screenSize.height)"
        let pageRect = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        let path = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        UIGraphicsBeginPDFContextToFile(path.path, pageRect, nil)
        
        if let context = UIGraphicsGetCurrentContext() {
            
            templateFormat.renderTemplate(context: context)
        }
        UIGraphicsEndPDFContext()
        
        return path
    }
    
    var rootPath: URL {
        return NSURL.fileURL(withPath: NSTemporaryDirectory())
    }
}
