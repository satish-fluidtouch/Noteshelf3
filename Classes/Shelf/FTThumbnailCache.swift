//
//  FTThumbnailCache.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 09/11/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

protocol FTThumbnailCacheProtocol: NSObjectProtocol {
    func addImageToCache(image : UIImage?, url: URL)
    func cachedImageForItem(item: FTDiskItemProtocol) -> UIImage?
    func clearStoredThumbnailCache()
}

class FTThumbnailCache: NSObject, FTThumbnailCacheProtocol {
    private var imageReadCache = NSCache<AnyObject, AnyObject>();
    
    func clearStoredThumbnailCache() {
        self.imageReadCache.removeAllObjects()
        try? FileManager().removeItem(atPath: self.thumbnailCachePath())
    }
    
    private lazy var cachePath: String? = {
        let fileManager = FileManager()
        #if BETA
        if let cacheDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID())?.appendingPathComponent("Library").path {
            let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent("ThumbnailCache")
            return url.path
        }
        #else
        if let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last {
            let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent("ThumbnailCache")
            return url.path
        }
        #endif
        return nil
    }()
    
    private func thumbnailCachePath() -> String
    {
        var cacheLocation = ""
        if let cacheDirectoryPath = self.cachePath {
            cacheLocation = cacheDirectoryPath
            var isDir : ObjCBool = false
            if FileManager.default.fileExists(atPath: cacheLocation, isDirectory: &isDir) == false || !isDir.boolValue
            {
                try? FileManager.default.createDirectory(atPath: cacheLocation, withIntermediateDirectories: true, attributes:nil)
            }
        }
        return cacheLocation
    }
    
    private func imagePath(for url: URL) -> String {
        let hash = url.thumbnailCacheHash()
        let imagePath = self.thumbnailCachePath() + "/" + "\(hash).png"
        return imagePath
    }
    
    func addImageToCache(image: UIImage?, url: URL)
    {
        if let coverImage = image {
            //**********
            let hash = url.thumbnailCacheHash()
            let entry: [String : Any] = ["image": coverImage, "date": url.fileModificationDate]
            self.imageReadCache.setObject(entry as AnyObject, forKey: hash as AnyObject)
            //**********
            var imageFileURL = URL.init(fileURLWithPath: self.imagePath(for: url))
            let imageData = coverImage.pngData()
            try? imageData?.write(to: imageFileURL, options: Data.WritingOptions.atomic);
            var val = URLResourceValues.init()
            val.contentModificationDate = url.fileModificationDate
            try? imageFileURL.setResourceValues(val)
        }
    }
    
    private func removeImageCache(url: URL)
    {
        //**********
        let hash = url.thumbnailCacheHash()
        self.imageReadCache.removeObject(forKey: hash as AnyObject)
        //**********
        let imageFileURL = URL.init(fileURLWithPath: self.imagePath(for: url))
        try? FileManager().removeItem(at: imageFileURL)
    }
    
    func cachedImageForItem(item: FTDiskItemProtocol) -> UIImage?
    {
        var cachedImage: UIImage?
        guard let shelfItem = item as? FTShelfItemProtocol else {
            return nil
        }
        
        //**********
        let hash = shelfItem.URL.thumbnailCacheHash()
        let cachedEntry = self.imageReadCache.object(forKey: hash as AnyObject)
        if let storedDate = cachedEntry?.object(forKey: "date") as? Date {
            if shelfItem.fileModificationDate.compare(storedDate) != .orderedDescending {
                cachedImage = cachedEntry?.object(forKey: "image") as? UIImage
            }
        }
        
        //**********
        
        if cachedImage == nil {
            let imageFileURL = URL.init(fileURLWithPath: self.imagePath(for: shelfItem.URL))
            if FileManager().fileExists(atPath: imageFileURL.path) {
                let storedDate = imageFileURL.fileModificationDate
                let shelfItemModifiedDate = shelfItem.fileModificationDate
                
                //System returning 18388399949.0 & 18388399949.63288 values though the dates are same, so checking for ".orderedDescending"
                if(shelfItemModifiedDate.compare(storedDate) != .orderedDescending) {
                    if let image = UIImage.init(contentsOfFile: imageFileURL.path) {
                        let entry: [String : Any] = ["image": image, "date": shelfItemModifiedDate]
                        self.imageReadCache.setObject(entry as AnyObject, forKey: hash as AnyObject)
                        cachedImage = image
                    }
                }
                else {
                    self.removeImageCache(url: item.URL)
                }
            }
        }
        return cachedImage;
    }
}
