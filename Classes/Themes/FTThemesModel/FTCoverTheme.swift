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

class FTCoverTheme: FTTheme {
    private var thumbnailURL: URL?

    override init (url: URL) {
        let pdfUrl = url.appendingPathComponent("template").appendingPathExtension("pdf")
        if FileManager().fileExists(atPath: pdfUrl.path) {
            self.thumbnailURL = pdfUrl
        }
        super.init(url: url)
    }
    
    override func isValidTheme() -> Bool {
        let templateURL = self.themeFileURL.appendingPathComponent("template.pdf")
        let fileExisits = FileManager().fileExists(atPath: templateURL.path)
        return fileExisits
    }
    
    //MARK:- FTTheme methods
    override func themeTemplateURL() -> URL {
        if let url = self.thumbnailURL {
            return url
        }
        return self.themeFileURL
    }
    
    override func themeThumbnail() -> UIImage {
        var reqImg: UIImage = UIImage(named: "defaultNoCover")!
        if let image = self.cachedThumbnailIfExists() {
            reqImg = image
        } else if let url = self.thumbnailURL, let pdf = PDFDocument(url: url), let img = pdf.drawImagefromPdf() {
            self.cacheThumbnail(image: img)
            reqImg = img
        }
        return reqImg
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

    override func preview() -> UIImage? {
        if let url = self.thumbnailURL {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }

    override func deleteThumbnailFromCache() { // will be used incase of custom cover deletion.
        let uniqueKey = self.themeFileURL.lastPathComponent.deletingPathExtension
        let reqURL = self.cachedFolderURL.appendingPathComponent(uniqueKey)
        if FileManager.default.fileExists(atPath: reqURL.path) {
            do {
                try FileManager.default.removeItem(at: reqURL)
            }
            catch {
                debugPrint("Failed delete the cover thumbnail due to reason",error.localizedDescription)
            }
        }
    }
}

private extension FTCoverTheme {
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

    override func themeTemplateURL() -> URL {
        return self.themeFileURL
    }

    override func themeThumbnail() -> UIImage {
        return UIImage(named: "defaultNoCover")!
    }

    override func isValidTheme() -> Bool {
        return true
    }

    override func preview() -> UIImage? {
        return self.themeThumbnail()
    }
}
