//
//  FTURLReadThumbnailManager.swift
//  Noteshelf
//
//  Created by Amar on 4/7/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import QuickLookThumbnailing

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
    
    private var QLRequestCache = [String: QLThumbnailGenerator.Request] ();
    
    func thumnailForItem(_ item : FTDiskItemProtocol,
                         onCompletion : @escaping (UIImage?,String?) -> Void) -> String?
    {
        guard item.URL.isNS2Book else {
            return self.thumbnailForNS3Book(item, onCompletion: onCompletion);
        }
        
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

private extension FTURLReadThumbnailManager {
    func removeQLRequest(_ item: FTDiskItemProtocol) {
        objc_sync_enter(self.QLRequestCache)
        let reqid = item.URL.hashKey;
        self.QLRequestCache.removeValue(forKey: reqid);
        objc_sync_exit(self.QLRequestCache)
    }
    
    func cancelPreviousQLRequest(_ item: FTDiskItemProtocol) {
        objc_sync_enter(self.QLRequestCache)
        let reqid = item.URL.hashKey;
        if let request = self.QLRequestCache[reqid] {
            QLThumbnailGenerator.shared.cancel(request);
            self.removeQLRequest(item);
        }
        objc_sync_exit(self.QLRequestCache)
    }
    
    func addQLRequestToCache(_ item: FTDiskItemProtocol,request: QLThumbnailGenerator.Request) {
        objc_sync_enter(self.QLRequestCache)
        let reqid = item.URL.hashKey;
        self.QLRequestCache[reqid] = request;
        objc_sync_exit(self.QLRequestCache)
    }
    
    func thumbnailForNS3Book(_ item : FTDiskItemProtocol,
                             onCompletion : @escaping (UIImage?,String?) -> Void) -> String? {
        let token = UUID().uuidString;
        self.cancelPreviousQLRequest(item);
        
        func fetchImage() {
            let request = item.URL.fetchQLThumbnail(completion: { [weak self] image in
                self?.removeQLRequest(item)
                onCompletion(image,token);
            })
            self.addQLRequestToCache(item, request: request);
        }

        let modifiedime = item.URL.fileModificationDate.timeIntervalSinceReferenceDate;
        let currentTime = Date().timeIntervalSinceReferenceDate;
        let thresholdTimeDifference: TimeInterval = 0.5;
        if currentTime - modifiedime > thresholdTimeDifference {
            fetchImage();
        }
        else {
            runInMainThread(thresholdTimeDifference) {
                fetchImage();
            }
        }
        return token
    }
}
