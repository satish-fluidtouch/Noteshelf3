//
//  FTCustomTemplateHandler.swift
//  FTTemplates
//
//  Created by Narayana on 11/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import PDFKit
import FTCommon

public class FTCustomTemplateHandler: NSObject {
    let themeLibrary: FTThemesLibrary!
    let url: URL!

    public init(url: URL) {
        self.themeLibrary = FTThemesLibrary(libraryType: .papers)
        self.url = url
    }
}

// Public function exposed outside
extension FTCustomTemplateHandler {
   public func generateCustomTemplate(title: String, filePath: URL, onCompletion: @escaping ((NSError?, URL?)->Void)) {
        self.themeLibrary.generatePaperThemeForPDFAtURL(filePath, title: title, onCompletion: { (error, url) in
            onCompletion(error, url)
        })
    }
}


protocol FTCustomThemeGenerator: NSObjectProtocol {
    func generatePaperTheme(fromPDFURL url: URL, onCompletion: @escaping ((NSError?, URL?)->Void))
}

extension FTCustomThemeGenerator
{
    func generatePaperTheme(fromPDFURL url: URL, onCompletion: @escaping ((NSError?, URL?)->Void)) {
        let coverThemeTitle = FTCommonUtils.getUUID()+".nsp"

        let tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory())
        let packageURL = tempURL.appendingPathComponent(coverThemeTitle)
        do {
            let scale = Int(UIScreen.main.scale);
            try FileManager.init().createDirectory(at: packageURL, withIntermediateDirectories: true, attributes: nil)

            let templateURL = packageURL.appendingPathComponent("template.pdf")
            try FileManager.default.copyItem(at: url, to: templateURL)

            let thumbURL = packageURL.appendingPathComponent("thumbnail@\(scale)x.png");
            let document = PDFDocument.init(url: templateURL)
            if(document == nil) {
                DispatchQueue.main.async(execute: {
                    onCompletion(NSError.init(domain: "FTThemeGenerator", code: 1002, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("PDFFailToLoad", comment: "PDFFailToLoad")]),nil)
                })
            }
            else {
                let thumbImage = self.generateThumbImage(document!)
                try thumbImage.pngData()?.write(to: thumbURL, options: NSData.WritingOptions.atomicWrite);
                DispatchQueue.main.async(execute: {
                    onCompletion(nil,packageURL)
                })
            }
        }
        catch let failError as NSError {
            DispatchQueue.main.async(execute: {
                onCompletion(failError,nil)
            })
        }
    }

    private func generateThumbImage(_ pdfDocument : PDFDocument) -> UIImage {
        let pageBox = PDFDisplayBox.cropBox

        let page: PDFPage = pdfDocument.page(at: 0)!
        var mediaBox = page.bounds(for: pageBox)

        let trasnform = page.transform(for: pageBox)
        mediaBox = mediaBox.applying(trasnform)

        mediaBox.origin = CGPoint.zero

        let thumbnailSize = CGSize(width: 300,height: 400)

        let pageRect = FTCommonUtils.aspectFit(mediaBox, targetRect: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let image = page.thumbnail(of: pageRect.size, for: pageBox)
        return image
    }
}
