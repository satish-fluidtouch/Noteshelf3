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
    private let maxImageSize = CGSize(width: 500, height: 500);
    
    private(set) lazy var resourceReadQueue: OperationQueue = {
        let operationqueue = OperationQueue();
        operationqueue.maxConcurrentOperationCount = 1;
        return operationqueue;
    }();

    func mediaResource(_ documentID: String, resourceURL: URL,onCompletion: @escaping (UIImage?)->()) {
        if let cachedImage = self.cachedImage(resourceURL) {
            onCompletion(cachedImage);
            return;
        }
        
        let documentURL = FTDocumentCache.shared.cachedLocation(for: documentID);
        let fileCoorinator = NSFileCoordinator.init(filePresenter: nil)
        var imageToReturn: UIImage?;
        let writeIntent = NSFileAccessIntent.readingIntent(with: documentURL, options: .withoutChanges);
        fileCoorinator.coordinate(with: [writeIntent], queue: self.resourceReadQueue) { error in
            guard nil == error else {
                onCompletion(imageToReturn);
                return;
            }
            let imagePath = resourceURL.path(percentEncoded: false);
            if let image = UIImage(contentsOfFile: imagePath) {
                if image.size.width > self.maxImageSize.width || image.size.height > self.maxImageSize.height {
                    imageToReturn = image.preparingThumbnail(of: self.maxImageSize);
                    let modifiedTime = resourceURL.fileModificationDate;
                    if let data = imageToReturn?.pngData() {
                        do {
                            try data.write(to: resourceURL, options: .atomic)
                            try FileManager().setAttributes([.modificationDate:modifiedTime], ofItemAtPath: imagePath);
                            self.addImage(image, imageURL: resourceURL);
                            debugLog("image updated: \(resourceURL.lastPathComponent)");
                        }
                        catch {
                            debugLog("error: \(error)");
                        }
                    }
                }
                else {
                    imageToReturn = image;
                    self.addImage(image, imageURL: resourceURL);
                }
            }
            onCompletion(imageToReturn);
        }
    }
    
    private func cachedImage(_ imageURL: URL) -> UIImage? {
        recursiveLock.lock();
        defer {
            recursiveLock.unlock();
        }
        let hash = imageURL.hashKey as AnyObject
        let cachedEntry = self.imageCache.object(forKey: hash)
        if let imageFromCache = cachedEntry?.object(forKey: "image") as? UIImage
            , let storedDate = cachedEntry?.object(forKey: "date") as? Date {
            if storedDate.compare(imageURL.fileModificationDate) == .orderedAscending {
                self.imageCache.removeObject(forKey: hash);
                return nil;
            } else {
                return imageFromCache;
            }
        } else {
            return nil;
        }
    }
    
    private func addImage(_ image: UIImage,imageURL: URL) {
        let hash = imageURL.hashKey as AnyObject
        let entry: [String : Any] = ["image": image, "date": imageURL.fileModificationDate]
        recursiveLock.lock();
        self.imageCache.setObject(entry as AnyObject, forKey: hash)
        recursiveLock.unlock();
    }
}
