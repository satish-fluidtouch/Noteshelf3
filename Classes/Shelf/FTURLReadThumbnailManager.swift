//
//  FTURLReadThumbnailManager.swift
//  Noteshelf
//
//  Created by Amar on 4/7/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTThumbReadCallbacks : NSObject
{
    var callbacks = [(UIImage?,String?) -> Void]();
    var token : String = FTUtils.getUUID();
}

@objcMembers class FTURLReadThumbnailManager: NSObject {
    static var sharedInstance : FTURLReadThumbnailManager = FTURLReadThumbnailManager();
    
    //*****************
    private var imageCache: FTThumbnailCacheProtocol = FTThumbnailCache()
    //*****************
    
    fileprivate var thumbReadOperationQueue = OperationQueue();
    fileprivate var readCallbacks = [Int : FTThumbReadCallbacks]();
    
    private override init() {
        super.init();

        let notificationBlock : (_ noti:Notification) -> Void = { [weak self] (notification) in
            self?.thumbReadOperationQueue.cancelAllOperations();
        }

        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(forName:UIScene.didEnterBackgroundNotification,
                                                   object: nil,
                                                   queue: nil, using:notificationBlock)
        } else {
            NotificationCenter.default.addObserver(forName:UIApplication.didEnterBackgroundNotification,
                                                   object: nil,
                                                   queue: nil, using:notificationBlock)
        }
    }
    
    func clearStoredThumbnailCache() {
        self.imageCache.clearStoredThumbnailCache()
    }
    
    func thumnailForItem(_ item : FTDiskItemProtocol,
                         onCompletion : @escaping (UIImage?,String?) -> Void) -> String?
    {
        let cachedImage = self.imageCache.cachedImageForItem(item: item)
        if(nil != cachedImage) {
            onCompletion(cachedImage,nil);
            return nil;
        }

        if(!FileManager().fileExists(atPath: item.URL.path)) {
            onCompletion(nil,nil);
            return nil;
        }

        let hash = item.URL.thumbnailCacheHash()
        var callbackItem = self.readCallbacks[hash];
        if(nil != callbackItem) {
            callbackItem?.callbacks.append(onCompletion);
            return callbackItem!.token;
        }
        else {
            callbackItem = FTThumbReadCallbacks();
            self.readCallbacks[hash] = callbackItem;
            callbackItem?.callbacks.append(onCompletion);
        }
        
        thumbReadOperationQueue.addOperation {
            let completionBlockExecution : (UIImage?, FTDiskItemProtocol) -> Void = { (image, item) in
                DispatchQueue.main.async {
                    let hash = item.URL.thumbnailCacheHash()
                    self.addImageToCache(image: image, url: item.URL)
                    let callbackItem = self.readCallbacks[hash];
                    if(nil != callbackItem) {
                        let token = callbackItem!.token;
                        let callbacks = callbackItem!.callbacks;
                        self.readCallbacks.removeValue(forKey: hash);
                        for eachCallback in callbacks {
                            eachCallback(image,token);
                        }
                    }
                }
            };
            
            let nsURL = item.URL as NSURL;
            var image : UIImage?;
            image = (item as? FTShelfImage)?.image;
            if(nil == image) {
                #if !NS2_SIRI_APP && !NOTESHELF_ACTION
                if item.URL.downloadStatus() != .downloaded {
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
        };
        return callbackItem!.token;
    }
    
    func addImageToCache(image: UIImage?, url: URL)
    {
        self.imageCache.addImageToCache(image: image, url: url)
    }
}
