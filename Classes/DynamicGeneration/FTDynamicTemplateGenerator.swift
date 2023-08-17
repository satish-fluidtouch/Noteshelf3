//
//  FTDynamicTemplateGenerator.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 24/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit

class FTDynamicTemplateGenerator: NSObject {
    private var templateFormat: FTDynamicTemplateFormat;
    private var variants: FTPaperVariants
    private var displayName : String
    var pageProperties: FTPageProperties {
        return self.templateFormat.pageProperties;
    }
    
    init(safeAreaInsets: UIEdgeInsets?, _ theme: FTDynamicTemplateTheme, _ generationType: FTGenrationType) {
        
        guard let variants = theme.customvariants,let templateInfo = theme.templateInfoDict else{
            fatalError("Missing variants or template info dict")
        }
        self.templateFormat = FTDynamicTemplateFormat.getFormat(FTDynamicTemplateInfo.init(templateInfo, variants.isLandscape, safeAreaInsets, variants, generationType))
        self.variants = theme.customvariants!
        self.displayName = theme.displayName
    }
    
    func generate() -> URL {
        let orientation = (variants.isLandscape) ? FTDeviceOrientation.land : FTDeviceOrientation.port
        let key = self.displayName + "_" +  (self.variants.lineType.lineType.displayTitle) + "_" + (self.variants.selectedColor.colorName.displayTitle) + orientation.rawValue +  "_" + self.variants.selectedDevice.dimension + "_Dynamic"
        let path = self.rootPath.appendingPathComponent(key).appendingPathExtension("pdf")
        
        UIGraphicsBeginPDFContextToFile(path.path, templateFormat.pageRect, nil)
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
