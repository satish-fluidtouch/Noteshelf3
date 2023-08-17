//
//  FTPlannerDiaryTemplateAssetGenerator.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlannerDiaryTemplateInfo : FTDigitalDiaryInfo {
    
    var templateType : FTPlannerDiaryTemplateType
    var isDarkTemplate: Bool = false

    init(templateType : FTPlannerDiaryTemplateType, customVariants variants : FTPaperVariants, isDarkTemplate: Bool = false){
        self.templateType = templateType
        self.isDarkTemplate = isDarkTemplate
        super.init(variants: variants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        if isDarkTemplate {
            return UIColor(hexString: "#131313")
        }else {
            return UIColor(hexString: "#FEFEFE")
        }
    }
}

class FTPlannerDiaryTemplateAssetGenerator : NSObject {
    var templateFormat : FTPlannerDiaryTemplateFormat;
    var templateInfo : FTPlannerDiaryTemplateInfo;

    init(templateInfo : FTPlannerDiaryTemplateInfo){
        self.templateInfo = templateInfo
        self.templateFormat = FTPlannerDiaryTemplateFormat.getFormatFrom(templateInfo:templateInfo)
    }
    func generate() -> URL {
        let orientation = (templateInfo.customVariants.isLandscape) ? "Land" : "Port"
        let screenType = templateInfo.customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTMidnightDairyFormat.getScreenSize(fromVariants: templateInfo.customVariants)
        let displayName = templateInfo.isDarkTemplate ? templateInfo.templateType.displayName + "(Dark)" : templateInfo.templateType.displayName
        let key = displayName + "_" + screenType + "_" + orientation +  "_" + "\(screenSize.width)" + "_"
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
