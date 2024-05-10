//
//  StretchTemplateFormat.swift
//  FTTemplatePicker
//
//  Created by Sameer on 03/08/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import Foundation

class FTStoreTemplateFormat: NSObject {
    var width: Int!
    var height: Int!
    var isLandscape: Bool!
    var customVariants: FTPaperVariants!
    var templateUrl: URL!
    var bgColor = "#F7F7F2-1.0";
    
    var outerRect : CGRect {
        return CGRect(x: 0, y: 0, width: self.width, height: self.height)
    }
       
    init(_ isLandscape: Bool,_ variants: FTPaperVariants, templateUrl: URL) {
        super.init()
        self.isLandscape = isLandscape
        self.customVariants = variants
        self.templateUrl = templateUrl
        
        setTemplateSize()
    }
    func setTemplateSize() {
        var screenSize = ""
        if !self.isLandscape {
            screenSize = customVariants.selectedDevice.dimension_port
        } else {
            screenSize = customVariants.selectedDevice.dimension_land
        }
        let measurements = screenSize.split(separator: "_")
        self.width = Int(measurements[0])
        self.height = Int(Double(measurements[1])!)
    }
    
    // This method is for the device type specific (Either Ipad or Iphone)
    private func setTemplateSize(forIpad: Bool, deviceType: FTScreenType, _ safeAreaInsets: UIEdgeInsets?){
        if !forIpad && deviceType == FTScreenType.Ipad {
            if !self.isLandscape {
                self.width = 375
                self.height = 603
            } else {
                self.width = 667
                self.height = 331
            }
        } else if forIpad && deviceType == FTScreenType.Iphone {
            if !self.isLandscape {
                self.width = 768
                self.height = 960
            } else {
                self.width = 1024
                self.height = 704
            }
        } else {
            setTemplateSize()
        }
    }
    
    func renderTemplate(context: CGContext) {
        guard let pdfPage = getTemplatePage() else { return  }
        context.saveGState()
        for i in 0..<pdfPage.count{
            let cgPDFPage = pdfPage[i]
            let rect = cgPDFPage.getBoxRect(CGPDFBox.cropBox)
            renderPage(context: context)
            context.translateBy(x: 0, y: outerRect.height);
            context.scaleBy(x: 1, y: -1);
            let aspectRect: CGRect = aspectFittedRect(inRect: rect, maxRect: outerRect)
            context.translateBy(x: aspectRect.origin.x, y: aspectRect.origin.y);
            let scale = getScale(actualRect: outerRect, innerRect: rect)
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(cgPDFPage)
        }
        context.restoreGState()
        UIGraphicsEndPDFContext()
    }
    
    func renderPage(context: CGContext) {
        UIGraphicsBeginPDFPageWithInfo(outerRect, nil)
        context.setFillColor(UIColor.init(hexWithAlphaString: self.bgColor).cgColor)
        context.fill(outerRect)
    }
    
    func getTemplatePage() -> [CGPDFPage]? {
        var pagesArray = [CGPDFPage]()
        if let url = self.templateUrl {
              let pdfDocument = PDFDocument.init(url: url);
            if let count = pdfDocument?.pageCount {
                for i in 0..<count {
                    if let pdfPage = pdfDocument?.page(at: i), let pageRef = pdfPage.pageRef{
                        pagesArray.append(pageRef)
                    }
                }
            }
        }
        return pagesArray
    }
    
    func getScale(actualRect: CGRect, innerRect: CGRect) -> CGFloat {
       let cosideredRect = CGRect(x: actualRect.origin.x,
                                            y: actualRect.origin.y,
                                            width: actualRect.width ,
                                            height: actualRect.height )
          return min((cosideredRect.width/innerRect.width),(cosideredRect.height/innerRect.height))
      }
    
    func aspectFittedRect( inRect: CGRect, maxRect: CGRect) -> CGRect {
        let originalAspectRatio: CGFloat = inRect.size.width / inRect.size.height;
        let maxAspectRatio: CGFloat = maxRect.size.width / maxRect.size.height;
        
        var newRect: CGRect = maxRect;
        if (originalAspectRatio > maxAspectRatio) { // scale by width
            newRect.size.height = maxRect.size.width * inRect.size.height / inRect.size.width;
            newRect.origin.y += (maxRect.size.height - newRect.size.height)/2.0;
        } else {
            newRect.size.width = maxRect.size.height  * inRect.size.width / inRect.size.height;
            newRect.origin.x += (maxRect.size.width - newRect.size.width)/2.0;
        }
        //    return CGRectIntegral(newRect);
        return newRect;
    }
}

public extension CGRect
{
    func transform(to rect: CGRect) -> CGAffineTransform {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: -self.minX, y: -self.minY)
        t = t.scaledBy(x: 1 / self.width, y: 1 / self.height)
        t = t.scaledBy(x: rect.width, y: rect.height)
        t = t.translatedBy(x: rect.minX * self.width / rect.width, y: rect.minY * self.height / rect.height)
        return t
    }
}
