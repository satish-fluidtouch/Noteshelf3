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
        }  else { // transparent no cover is handled with png image
            let thumbPath = url.appendingPathComponent("thumbnail2x.png")
            if (FileManager.default.fileExists(atPath: thumbPath.path)) {
                thumbURL = thumbPath
            } else if let url = Bundle.main.url(forResource: "defaultNoCover", withExtension: "png") {
                thumbURL = url
            } else {
                fatalError("Default cover image not found in bundle")
            }
        }
        self.thumbnailURL = thumbURL
        
        super.init(url: url)
    }
    
    override func isValidTheme() -> Bool {
        let templateURL = self.themeFileURL.appendingPathComponent("template.pdf")
        let fileExisits = FileManager().fileExists(atPath: templateURL.path)
        return fileExisits
    }
    
    //MARK:- FTTheme methods
    override func themeTemplateURL() -> URL {
        return self.thumbnailURL;
    }
    
    override func themeThumbnail() -> UIImage {
        let thumbnail: UIImage
        if let image = UIImage(contentsOfFile: self.thumbnailURL.path) { // This ll be executed only for NO COVER
            thumbnail = image
        } else {
            thumbnail = self.getThumbnailI()
        }
        return thumbnail
    }

    private lazy var cachedThumbnailURL: URL = {
        let uniqueKey = self.themeFileURL.lastPathComponent.deletingPathExtension
        let reqURL = self.cachedFolderURL.appendingPathComponent(uniqueKey)
        return reqURL
    }()

    private lazy var cachedFolderURL: URL = {
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
    }()

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

private extension FTCoverTheme {
    func getThumbnailI() -> UIImage {
        var reqImg: UIImage = UIImage(named: "defaultNoCover")!
        if let image = self.cachedThumbnailIfExists() {
            reqImg = image
        } else if let pdf = PDFDocument(url: self.thumbnailURL), let img = pdf.drawImagefromPdf() {
            self.cacheThumbnail(image: img)
            reqImg = img
        }
        return reqImg
    }

    func cacheThumbnail(image: UIImage) {
        if let data = image.pngData() {
            do {
                try data.write(to: cachedThumbnailURL)
            } catch {
                print("Failed to save the thumbnail to the cache directory: \(error)")
            }
        }
    }

    func cachedThumbnailIfExists() -> UIImage? {
        if let cachedData = try? Data(contentsOf: cachedThumbnailURL) {
            if let cachedImage = UIImage(data: cachedData) {
                return cachedImage
            }
        }
        return nil
    }
}

class FTNoCoverTheme: FTCoverTheme {
    override init (url: URL) {
        super.init(url: url)
        self.hasCover = false
    }

    override func isValidTheme() -> Bool {
        return true
    }
}
