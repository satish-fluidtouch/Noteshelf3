//
//  FTPDFFileGenerator.swift
//  Noteshelf
//
//  Created by Amar on 9/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import VisionKit
import FTCommon

class FTPDFFileGenerator : NSObject
{
    @discardableResult func generatePDFFile(withImages images : [UIImage], onCompletion : @escaping (String)->()) -> Progress { //To create PDF with multiple images if required
        let conversionProgress = Progress()
        conversionProgress.totalUnitCount = Int64(images.count)
        
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("Untitled.pdf");
        _ = try? FileManager.init().removeItem(atPath: destPath);
        DispatchQueue.global().async {
            var pageRect = CGRect.zero;
            UIGraphicsBeginPDFContextToFile(destPath, pageRect, nil);
            images.forEach { (image) in
                let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
                
                if(image.size.width > image.size.height)
                {
                    pageRect.size = pdfAspectFittedRect(imageRect,self.deviceSpecificLandscapeDocumentRect()).size;
                }
                else
                {
                    pageRect.size = pdfAspectFittedRect(imageRect, self.deviceSpecificPortraitDocumentRect()).size;
                }
                autoreleasepool {
                    UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
                    image.draw(in: pageRect);
                }
                conversionProgress.completedUnitCount += 1
            }
            UIGraphicsEndPDFContext();
            
            DispatchQueue.main.async {
                onCompletion(destPath)
            }
        }
        return conversionProgress;
    }
    
    func generateCoverPDFFile(withImages images : [UIImage]) -> String {
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("Untitled.pdf");
        _ = try? FileManager.init().removeItem(atPath: destPath);
        var pageRect = CGRect.zero;
        UIGraphicsBeginPDFContextToFile(destPath, pageRect, nil);
        images.forEach { (image) in
            let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
            if imageRect.size.width == portraitCoverSize.width, imageRect.size.height == portraitCoverSize.height {
                pageRect = imageRect
            } else {
                if(image.size.width > image.size.height)
                {
                    pageRect.size = pdfAspectFittedRect(imageRect,self.deviceSpecificLandscapeDocumentRect()).size;
                }
                else
                {
                    pageRect.size = pdfAspectFittedRect(imageRect, self.deviceSpecificPortraitDocumentRect()).size;
                }
            }
            autoreleasepool {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
                image.draw(in: pageRect);
            }
        }
        UIGraphicsEndPDFContext();
        return destPath
    }
    
    func generatePDFFile(withImage image: UIImage) -> String { //To create PDF with single image if required
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("Untitled.pdf");
        _ = try? FileManager.init().removeItem(atPath: destPath);
        
        var pageRect = CGRect.zero;
        UIGraphicsBeginPDFContextToFile(destPath, pageRect, nil);
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
        
        if(image.size.width > image.size.height)
        {
            pageRect.size = pdfAspectFittedRect(imageRect,self.deviceSpecificLandscapeDocumentRect()).size;
        }
        else
        {
            pageRect.size = pdfAspectFittedRect(imageRect, self.deviceSpecificPortraitDocumentRect()).size;
        }
        autoreleasepool {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
            image.draw(in: pageRect);
        }
        UIGraphicsEndPDFContext();
        return destPath
    }

    func generateBlankPDFFile(_ isLandscape : Bool) -> String
    {
        var pageRect = self.deviceSpecificPortraitDocumentRect();
        if(isLandscape) {
            pageRect = self.deviceSpecificLandscapeDocumentRect();
        }
        
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("Untitled.pdf");
        _ = try? FileManager.init().removeItem(atPath: destPath);

        UIGraphicsBeginPDFContextToFile(destPath, pageRect, nil);
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
        UIColor.white.setFill();
        UIGraphicsGetCurrentContext()!.fill(pageRect);
        UIGraphicsEndPDFContext();
        
        return destPath;
    }
    
    func deviceSpecificPortraitDocumentRect() -> CGRect
    {
        var mainScreenBounds = UIScreen.main.bounds;
        if(mainScreenBounds.size.width > mainScreenBounds.size.height) {
            let height = mainScreenBounds.size.height;
            mainScreenBounds.size.height = mainScreenBounds.size.width;
            mainScreenBounds.size.width = height;
        }
        return mainScreenBounds;
    }
    
    func deviceSpecificLandscapeDocumentRect() -> CGRect
    {
        var mainScreenBounds = UIScreen.main.bounds;
        if(mainScreenBounds.size.height > mainScreenBounds.size.width) {
            let width = mainScreenBounds.size.width;
            mainScreenBounds.size.width = mainScreenBounds.size.height;
            mainScreenBounds.size.height = width;
        }
        return mainScreenBounds;
    }
    
    func generateBlankPDFFileWithPageRect(_ pageRect : CGRect,fileName : String = "Untitled.pdf") -> String
    {
        let destPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName);
        _ = try? FileManager.init().removeItem(atPath: destPath);
        
        UIGraphicsBeginPDFContextToFile(destPath, pageRect, nil);
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil);
        let color = UIColor.init(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1.0)
        color.setFill();
        UIGraphicsGetCurrentContext()!.fill(pageRect);
        UIGraphicsEndPDFContext();
        
        return destPath;
    }
}

extension FTPDFFileGenerator{
    func generatePDFWithDocumentCameraScan(_ document : VNDocumentCameraScan) -> URL
    {
        let destUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ScannedNote.pdf")
        try? FileManager.default.removeItem(atPath: destUrl.path)

        var pageRect = CGRect.zero
        UIGraphicsBeginPDFContextToFile(destUrl.path, pageRect, nil);
        let pageCount = document.pageCount;
        for i in 0..<pageCount {
            autoreleasepool {
                let image = document.imageOfPage(at: i);
                pageRect = CGRect.zero
                let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                if(image.size.width > image.size.height) {
                    pageRect.size = pdfAspectFittedRect(imageRect, self.deviceSpecificLandscapeDocumentRect()).size
                }
                else {
                    pageRect.size = pdfAspectFittedRect(imageRect, self.deviceSpecificPortraitDocumentRect()).size
                }
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                if pageRect.contains(imageRect)
                {
                    pageRect=CGRect.init(origin: CGPoint.init(x: (pageRect.size.width-imageRect.size.width)/2, y: (pageRect.size.height-imageRect.size.height)/2), size: imageRect.size)
                }
                image.draw(in: pageRect)
            }
            
        }
        UIGraphicsEndPDFContext()
        return destUrl;
    }
}
