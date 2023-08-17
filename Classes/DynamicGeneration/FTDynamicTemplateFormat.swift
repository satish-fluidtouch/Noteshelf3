//
//  FTDynamicTemplateFormat.swift
//  DynamicTemplateGeneration
//
//  Created by sreenu cheedella on 24/02/20.
//  Copyright © 2020 sreenu cheedella. All rights reserved.
//

import UIKit
import PDFKit

enum FTSupportingDeviceType: Int {
    case universal
    case iPad
    case iPhone
}

class FTDynamicTemplateFormat: NSObject {
    let deviceType: FTScreenType = UIDevice.deviceScreenType()
    var templateInfo: FTDynamicTemplateInfo;
    var pageProperties = FTPageProperties();
    
    class func getFormat(_ templateInfo: FTDynamicTemplateInfo) -> FTDynamicTemplateFormat {
        if let instance = ClassFromString.getClass(fromString: templateInfo.codableInfo.themeClassName) as? FTDynamicTemplateFormat.Type {
            return instance.init(templateInfo)
        }
        
        return FTDynamicTemplateFormat.init(templateInfo)
    }
    
    required init(_ template: FTDynamicTemplateInfo){
        templateInfo = template;
        super.init()
    }
    
    var pageRect : CGRect {
        return CGRect(x: 0, y: 0, width: templateInfo.width, height: templateInfo.height)
    }
    
    func renderTemplate(context: CGContext) {
        UIGraphicsBeginPDFPage()
        let pdfPage = PDFPage.init()
        context.setFillColor(UIColor.init(hexWithAlphaString: templateInfo.customVariants.selectedColor.colorHex).cgColor)
        context.fill(pageRect)
        pdfPage.setBounds(pageRect, for: .mediaBox)
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage.transform(context, for: .cropBox);
        pdfPage.draw(with: .cropBox, to: context);
        context.restoreGState();
        
        updatePageProperties();
    }
    
    func verticalLineCount() -> Int {
        return 0
    }
    
    func horizontalLineCount() -> Int {
        return 0
    }
    
    func updatePageProperties() {
        self.pageProperties.lineHeight = (Int)(self.lineHeight);
        let lineCOunt = (CGFloat)(horizontalLineCount());
        if lineCOunt > 0 {
            let bottom = templateInfo.codableInfo.bottomMargin;
            self.pageProperties.bottomMargin = (Int)(bottom);
            self.pageProperties.topMargin = (Int)(pageRect.size.height - bottom - (lineCOunt * self.lineHeight));
        }
    }
    
    var lineHeight: CGFloat {
        return templateInfo.customVariants.lineType.horizontalLineSpacing;
    }
}

class ClassFromString {
    class func getClass(fromString className: String) -> AnyClass? {
        
        /// get namespace
        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String;
        
        /// get 'anyClass' with classname and namespace
        let cls: AnyClass? = NSClassFromString("\(namespace.replacingOccurrences(of: " ", with: "_")).\(className)");
        
        // return AnyClass!
        return cls;
    }
}
