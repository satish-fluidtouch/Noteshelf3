//
//  FTNCoverThemeGenerator.swift
//  Noteshelf
//
//  Created by Amar on 2/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTCoverThemeGenerator: NSObjectProtocol {
    func generateCoverTheme(fromImage image: UIImage,
                            themeInfo: FTCustomCoverThemeInfo) -> (error: NSError?, url: URL?)
}

extension FTCoverThemeGenerator {
    func generateCoverTheme(fromImage image: UIImage,
                            themeInfo: FTCustomCoverThemeInfo) -> (error: NSError?, url: URL?) {
        let coverThemeTitle = FTUtils.getUUID()+".nsc"
        var tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory())
        tempURL = tempURL.appendingPathComponent(coverThemeTitle)
        let resizedImage = image.resizedImage(portraitCoverSize).makeCover(shouldAddSpine: true)
        let scale = Int(UIScreen.main.scale)
        let pdfImage = image.addSpineToImage()
        let path = FTPDFFileGenerator().generateCoverPDFFile(withImages: [pdfImage, resizedImage])
        let pdfDocument = PDFDocument(url: Foundation.URL(fileURLWithPath: path))
        do {
            try FileManager.init().createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
            var thumbURL = tempURL.appendingPathComponent("thumbnail@\(scale)x.png")
            if (scale == 1) {
                thumbURL = tempURL.appendingPathComponent("thumbnail.png")
            }
            let pdfURL = tempURL.appendingPathComponent("template.pdf")
            try resizedImage.pngData()?.write(to: thumbURL, options: NSData.WritingOptions.atomicWrite)
            let pdfData = pdfDocument?.dataRepresentation()
            try pdfData?.write(to: pdfURL, options: NSData.WritingOptions.atomicWrite)
            let metaData = NSMutableDictionary.init()
            let themeTitle = themeInfo.title.replacingOccurrences(of: ".nsc", with: "")
            metaData.setObject(themeTitle, forKey: "display_title" as NSCopying)
            let metaDataURL = tempURL.appendingPathComponent("metadata.plist")
            metaData.write(to: metaDataURL, atomically: true)
            return (nil, tempURL)
        }
        catch let failError as NSError {
            return (failError,nil)
        }
    }
        
    private func addSpineToPdf(document: PDFDocument) {
        UIGraphicsBeginPDFContextToFile(document.documentURL!.path, CGRect.zero, nil)
        let image = UIImage(named: "cover_spine")!
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        self.renderContext(context: context, pdfDocument: document)
        let pdfPage = document.page(at: 0)
        let bounds = pdfPage?.bounds(for: .cropBox)
        let imagePosition = CGRect(x: 0, y: 0, width: 80, height: bounds!.height)
        image.draw(at: imagePosition.origin)
        UIGraphicsEndPDFContext()
    }
    
    private func renderContext(context : CGContext, pdfDocument: PDFDocument) {
        UIGraphicsBeginPDFPage();
        let pageRect = UIGraphicsGetPDFContextBounds();
        let pdfPage = pdfDocument.page(at: 0);
        context.saveGState();
        context.translateBy(x: 0, y: pageRect.size.height);
        context.scaleBy(x: 1, y: -1);
        pdfPage?.transform(context, for: .cropBox);
        pdfPage?.draw(with: .cropBox, to: context);
        context.restoreGState();
    }
}


extension PDFDocument {
    
}
