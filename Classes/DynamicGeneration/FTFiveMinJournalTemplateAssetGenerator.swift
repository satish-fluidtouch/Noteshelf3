//
//  FTFiveMinJournalTemplateAssetGenerator.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTFiveMinJournalTemplateInfo : FTDigitalDiaryInfo {
    
    var templateType : FTFiveMinJournalTemplateType
    
    init(templateType : FTFiveMinJournalTemplateType, customVariants variants : FTPaperVariants){
        self.templateType = templateType
        super.init(variants: variants)
    }
    override func getTemplateBackgroundColor() -> UIColor {
        return UIColor(red: 247/255, green: 247/255, blue: 242/255, alpha: 1.0)
    }
}

class FTFiveMinJournalTemplateAssetGenerator : NSObject {
    var templateFormat : FTFiveMinJournalTemplateFormat;
    var templateInfo : FTFiveMinJournalTemplateInfo;

    init(templateInfo : FTFiveMinJournalTemplateInfo){
        self.templateInfo = templateInfo
        self.templateFormat = FTFiveMinJournalTemplateFormat.getFormatFrom(templateInfo:templateInfo)
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
