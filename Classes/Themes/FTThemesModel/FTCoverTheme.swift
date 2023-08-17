//
//  FTCoverTheme.swift
//  FTTemplatePicker
//
//  Created by Sameer on 27/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import Foundation
import UIKit
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
import SDWebImage
#endif

class FTCoverTheme : FTTheme{
    private var thumbnailURL: URL;
    override init (url: URL) {
        let thumbURL : URL;
        let screenScale = UIScreen.main.scale;
        let pdfUrl = url.appendingPathComponent("template").appendingPathExtension("pdf")
        if FileManager().fileExists(atPath: pdfUrl.path) {
            thumbURL = pdfUrl
        } else if(screenScale == 1) {
            thumbURL = url.appendingPathComponent("thumbnail.png");
        } else {
            var screenIntValue = Int(screenScale);
            var thumbPath = url.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
            
            while ((screenIntValue > 0) && (!FileManager.default.fileExists(atPath: thumbPath.path))) {
                screenIntValue -= 1;
                thumbPath = url.appendingPathComponent("thumbnail@\(screenIntValue)x.png");
            }
            
            if (FileManager.default.fileExists(atPath: thumbPath.path)) {
                thumbURL = thumbPath;
            }
            else{
                if let url = Bundle.main.url(forResource: "default_cover_image", withExtension: "png"){
                    thumbURL = url;
                }
                else{
                    fatalError("Default cover image not found in bundle")
                }
            }
        }
        
        thumbnailURL = thumbURL
        super.init(url: url);
    }
    
    override func isValidTheme() -> Bool {
        let templateURL = self.themeFileURL.screenScaleURL(for: "thumbnail.png");
        if let tempURL = templateURL {
            return FileManager().fileExists(atPath: tempURL.path);
        }
        return false;
    }
    
    //MARK:- FTTheme methods
    override func themeTemplateURL() -> URL {
        return self.thumbnailURL;
    }
    
    override func themeThumbnail() -> UIImage {
        if let image = UIImage.init(contentsOfFile: self.thumbnailURL.path) {
            return image
        } else {
            if let pdf = PDFDocument(url: self.thumbnailURL) {
                return pdf.drawImagefromPdf() ?? UIImage(named: "defaultNoCover")!
            }
        }
        return UIImage(named: "defaultNoCover")!
    }

    
    override func preview() async -> UIImage? {
        return UIImage.init(contentsOfFile: thumbnailURL.path)
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    override func willDelete() {
        let key = SDWebImageManager.shared.cacheKey(for: self.thumbnailURL);
        SDImageCache.shared.removeImage(forKey:  key, withCompletion: nil);
    }
    #endif
}

class FTNoCoverTheme: FTCoverTheme {
    override init (url: URL) {
        super.init(url: url)
        self.hasCover = false
    }
}
