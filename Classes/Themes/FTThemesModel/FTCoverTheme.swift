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

class FTCoverTheme : FTTheme {
    private var thumbnailURL: URL

    override init (url: URL) {
        let thumbURL: URL
        let pdfUrl = url.appendingPathComponent("template").appendingPathExtension("pdf")
        if FileManager().fileExists(atPath: pdfUrl.path) {
            thumbURL = pdfUrl
        }  else {
            let thumbPath = url.appendingPathComponent("thumbnail2x.png")
            if (FileManager.default.fileExists(atPath: thumbPath.path)) {
                thumbURL = thumbPath
            } else if let url = Bundle.main.url(forResource: "default_cover_image", withExtension: "png") {
                thumbURL = url
            } else {
                fatalError("Default cover image not found in bundle")
            }
        }
        self.thumbnailURL = thumbURL
        
        super.init(url: url)
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
        var thumbnail: UIImage = UIImage(named: "defaultNoCover")!
        if let image = UIImage(contentsOfFile: self.thumbnailURL.path) { // This ll be executed only for no cover
            thumbnail = image
        } else {
            if let image = self.cachedThumbnailIfExists() {
                thumbnail = image
            } else if let pdf = PDFDocument(url: self.thumbnailURL), let img = pdf.drawImagefromPdf() {
                self.cacheThumbnail(image: img)
                thumbnail = img
            }
        }
        return thumbnail
    }

    private func cacheThumbnail(image: UIImage) {
        if let data = image.pngData() {
            do {
                try data.write(to: cachedThumbnailURL)
            } catch {
                print("Failed to save the thumbnail to the cache directory: \(error)")
            }
        }
    }

    private func cachedThumbnailIfExists() -> UIImage? {
        if let cachedData = try? Data(contentsOf: cachedThumbnailURL) {
            if let cachedImage = UIImage(data: cachedData) {
                return cachedImage
            }
        }
        return nil
    }

    private var cachedThumbnailURL: URL {
        let reqURL = self.cachedFolderURL.appendingPathComponent(displayName)
        return reqURL
    }

    private var cachedFolderURL: URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let reqURL = cacheDirectory.appendingPathComponent("CoverThumbnails")
        if !FileManager.default.fileExists(atPath: reqURL.path) {
            do {
                try FileManager.default.createDirectory(at: reqURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
        return reqURL
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
