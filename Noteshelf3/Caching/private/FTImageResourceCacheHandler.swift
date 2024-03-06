//
//  FTImageResourceCacheHandler.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 20/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTImageResourceCacheHandler: NSObject {
    private let imageCache = NSCache<AnyObject, AnyObject>();
    private let recursiveLock = NSRecursiveLock()

    func cachedImage(_ imageURL: URL) -> UIImage? {
        let hash = imageURL.hashKey as AnyObject
        recursiveLock.lock();
        let cachedEntry = self.imageCache.object(forKey: hash)
        recursiveLock.unlock();
        if let imageFromCache = cachedEntry?.object(forKey: "image") as? UIImage
            , let storedDate = cachedEntry?.object(forKey: "date") as? Date {
            if storedDate.compare(imageURL.fileModificationDate) == .orderedAscending {
                recursiveLock.lock();
                self.imageCache.removeObject(forKey: hash);
                recursiveLock.unlock();
                return nil;
            } else {
                return imageFromCache;
            }
        } else {
            return nil;
        }
    }
    
    func addImage(_ image: UIImage,imageURL: URL) {
        let hash = imageURL.hashKey as AnyObject
        let entry: [String : Any] = ["image": image, "date": imageURL.fileModificationDate]
        recursiveLock.lock();
        self.imageCache.setObject(entry as AnyObject, forKey: hash)
        recursiveLock.unlock();
    }
}
