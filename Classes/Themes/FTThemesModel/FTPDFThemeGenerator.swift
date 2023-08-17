//
//  FTNPDFThemeGenerator.swift
//  Noteshelf
//
//  Created by Amar on 2/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import PDFKit
import FTCommon

protocol FTPDFThemeGenerator : NSObjectProtocol {
    func generatePaperTheme(fromPDFURL url : URL, onCompletion : @escaping ((NSError?,URL?)->Void));
}

extension FTPDFThemeGenerator
{
    func generatePaperTheme(fromPDFURL url : URL, onCompletion : @escaping ((NSError?,URL?)->Void))
    {
        let coverThemeTitle = FTUtils.getUUID()+".nsp";

        let tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory());
        let packageURL = tempURL.appendingPathComponent(coverThemeTitle);
        do {
            let scale = Int(UIScreen.main.scale);
            try FileManager.init().createDirectory(at: packageURL, withIntermediateDirectories: true, attributes: nil);
            
            let templateURL = packageURL.appendingPathComponent("template.pdf");
            try FileManager.default.copyItem(at: url, to: templateURL);
            
            let thumbURL = packageURL.appendingPathComponent("thumbnail@\(scale)x.png");
            let document = PDFDocument.init(url: templateURL);
            if(document == nil) {
                DispatchQueue.main.async(execute: {
                    onCompletion(NSError.init(domain: "FTThemeGenerator", code: 1002, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("PDFFailToLoad", comment: "PDFFailToLoad")]),nil);
                });
            }
            else {
                let defaultImagePath = Bundle.main.url(forResource: "default_paper_image", withExtension: "png")
                var thumbImage = UIImage()
                if document?.isEncrypted ?? false {
                    thumbImage = UIImage(contentsOfFile: defaultImagePath!.path)!
                } else {
                    thumbImage = self.generateThumbImage(document!);
                }
                try thumbImage.pngData()?.write(to: thumbURL, options: NSData.WritingOptions.atomicWrite);
                DispatchQueue.main.async(execute: {
                    onCompletion(nil,packageURL);
                });
            }
        }
        catch let failError as NSError {
            DispatchQueue.main.async(execute: {
                onCompletion(failError,nil);
            });
        }
    }
    
    fileprivate func generateThumbImage(_ pdfDocument : PDFDocument) -> UIImage
    {
        let pageBox = PDFDisplayBox.cropBox;
        
        let page : PDFPage = pdfDocument.page(at: 0)!;
        var mediaBox = page.bounds(for: pageBox);
        
        let trasnform = page.transform(for: pageBox);
        mediaBox = mediaBox.applying(trasnform);
        
        mediaBox.origin = CGPoint.zero;
        
        let thumbnailSize = CGSize(width: 300,height: 400);
        
        let pageRect = FTUtils.aspectFit(mediaBox, targetRect: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height));
        let image = page.thumbnail(of: pageRect.size, for: pageBox);
        return image;
    }
}
