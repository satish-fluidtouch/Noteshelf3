//
//  FTNS2BookURLThumbnailReader.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 31/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTNS2BookURLThumbnailReader: NSObject {
    fileprivate var readCallbacks = [Int : FTThumbReadCallbacks]();

    @discardableResult
    func thumbnail(for item: FTDiskItemProtocol
                   , reuseToken: String?
                   , queue: OperationQueue
                   , cache: FTThumbnailCacheProtocol
                   , onCompletion: @escaping (UIImage?,String?) -> ()) -> String? {
        let cachedImage = cache.cachedImageForItem(item: item)
        if(nil != cachedImage) {
            onCompletion(cachedImage,nil);
            return nil;
        }

        if(!FileManager().fileExists(atPath: item.URL.path)) {
            onCompletion(nil,nil);
            return nil;
        }

        let hash = item.URL.thumbnailCacheHash()
        let callbackItem: FTThumbReadCallbacks
        if let callBack = self.readCallbacks[hash] {
            callbackItem = callBack;
            callbackItem.callbacks.append(onCompletion);
            return callbackItem.token;
        }
        else {
            callbackItem = FTThumbReadCallbacks();
            if let _token = reuseToken {
                callbackItem.token = _token;
            }
            self.readCallbacks[hash] = callbackItem;
            callbackItem.callbacks.append(onCompletion);
        }
        
        queue.addOperation {
            let completionBlockExecution : (UIImage?, FTDiskItemProtocol) -> Void = { (image, item) in
                DispatchQueue.main.async {
                    let hash = item.URL.thumbnailCacheHash()
                    cache.addImageToCache(image: image, url: item.URL)
                    if let callbackItem = self.readCallbacks[hash] {
                        let token = callbackItem.token;
                        let callbacks = callbackItem.callbacks;
                        self.readCallbacks.removeValue(forKey: hash);
                        for eachCallback in callbacks {
                            eachCallback(image,token);
                        }
                    }
                }
            };
            
            let nsURL = item.URL as NSURL;
            var image : UIImage?;
            if(nil == image) {
#if !NS2_SIRI_APP && !NOTESHELF_ACTION
                if (item as? FTDocumentItemProtocol)?.isDownloaded == false {
                    completionBlockExecution(nil,item);
                    return
                }
#endif
                let thumbURL = nsURL.appendingPathComponent("cover-shelf-image.png");
                var error : NSError?;
                let coordinator = NSFileCoordinator.init(filePresenter: nil);
                coordinator.coordinate(readingItemAt: thumbURL!, options: NSFileCoordinator.ReadingOptions.immediatelyAvailableMetadataOnly, error: &error, byAccessor: { (readURL) in
                    image = UIImage.init(contentsOfFile: readURL.path);
                    completionBlockExecution(image, item);
                });
            }
            else {
                completionBlockExecution(image,item);
            }
        }
        return callbackItem.token;

    }

}
