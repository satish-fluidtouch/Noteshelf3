//
//  FTImageLoader.swift
//  Noteshelf-Today
//
//  Created by Matra on 19/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation

private let FTDateKey = "date"
private let FTImageKey = "image"
private let FTFolderKey = "cachedImages"

class FTClassKitShelfImageCache: NSObject {

    static let imageCache = NSCache<NSString, AnyObject>()
    
    static func imageForKey(_ key : String) -> UIImage? {
        let cachedData = imageCache.object(forKey: key as NSString)
        if cachedData != nil {
            return cachedData!.object(forKey: FTImageKey) as? UIImage
        }
        return nil
    }
    
    static func saveImageWithIdentifier(_ identifier : String ,image : UIImage , completion : (() -> Void)?) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsURL.appendingPathComponent(FTFolderKey, isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        let imageURL = folderURL.appendingPathComponent("\(identifier).png")
        let cachedData = imageCache.object(forKey: identifier as NSString)
        if cachedData != nil {
            let modifiedDate = cachedData!.object(forKey: FTDateKey) as! Date
            if modifiedDate  == imageURL.fileModificationDate {
                completion?()
            }
            else {
                let imageInfo = [FTDateKey : folderURL.fileModificationDate, FTImageKey : image as Any] as [String : Any]
                imageCache.setObject(imageInfo as AnyObject, forKey: identifier as NSString)
                completion?()
            }
        }else {
            if !fileManager.fileExists(atPath: imageURL.path) {
                let imageData = UIImagePNGRepresentation(image)
                try? imageData?.write(to: imageURL, options: Data.WritingOptions.atomic);
            }
            let imageInfo = [FTDateKey : folderURL.fileModificationDate, FTImageKey : image as Any] as [String : Any]
            imageCache.setObject(imageInfo as AnyObject, forKey: identifier as NSString)
            completion?()
        }
    }
    
    static func removeAllCachedImages() {
        imageCache.removeAllObjects()
    }
    
    static func removeImageForKey(key : String) {
        if imageCache.object(forKey: key as NSString) != nil {
            imageCache.removeObject(forKey: key as NSString)
        }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsURL.appendingPathComponent(FTFolderKey, isDirectory: true)
        let imageURL = folderURL.appendingPathComponent("\(key).png")
        if fileManager.fileExists(atPath: imageURL.path) {
            try? fileManager.removeItem(at: imageURL)
        }
    }
}
