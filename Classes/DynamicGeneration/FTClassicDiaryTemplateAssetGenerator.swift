//
//  FTClassicDiaryTemplateAssetGenerator.swift
//  Noteshelf
//
//  Created by Ramakrishna on 03/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTClassicDiaryTemplateInfo : FTDigitalDiaryInfo {
    
    var templateType : FTClassicDiaryTemplateType
    
    init(templateType : FTClassicDiaryTemplateType, customVariants variants : FTPaperVariants){
        self.templateType = templateType
        super.init(variants: variants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(hexString: "#FAFAEF")
    }
}

class FTClassicDiaryTemplateAssetGenerator : NSObject {
    var templateFormat : FTClassicDiaryTemplateFormat;
    var templateInfo : FTClassicDiaryTemplateInfo;

    init(templateInfo : FTClassicDiaryTemplateInfo){
        self.templateInfo = templateInfo
        self.templateFormat = FTClassicDiaryTemplateFormat.getFormatFrom(templateInfo:templateInfo)
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
