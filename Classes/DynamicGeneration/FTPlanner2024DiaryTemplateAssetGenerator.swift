//
//  FTPlannerDiaryTemplateAssetGenerator.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTPlanner2024DiaryTemplateInfo : FTDigitalDiaryInfo {
    
    var templateType : FTPlanner2024DiaryTemplateType

    init(templateType : FTPlanner2024DiaryTemplateType, customVariants variants : FTPaperVariants, isDarkTemplate: Bool = false){
        self.templateType = templateType
        super.init(variants: variants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(hexString: "#FEFEFE")
    }
}

class FTPlanner2024DiaryTemplateAssetGenerator : NSObject {
    var templateFormat : FTPlanner2024DiaryTemplateFormat;
    var templateInfo : FTPlanner2024DiaryTemplateInfo;

    init(templateInfo : FTPlanner2024DiaryTemplateInfo){
        self.templateInfo = templateInfo
        self.templateFormat = FTPlanner2024DiaryTemplateFormat.getFormatFrom(templateInfo:templateInfo)
    }
    func generate() -> URL {
        let orientation = (templateInfo.customVariants.isLandscape) ? "Land" : "Port"
        let screenType = templateInfo.customVariants.selectedDevice.isiPad ? "iPad" : "iPhone"
        let screenSize = FTMidnightDairyFormat.getScreenSize(fromVariants: templateInfo.customVariants)
        let displayName = templateInfo.templateType.displayName
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
