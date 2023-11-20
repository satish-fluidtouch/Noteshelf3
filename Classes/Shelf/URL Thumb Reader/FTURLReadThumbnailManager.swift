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
    
    private lazy var ns3ThumbnailReader: FTNS3BookURLThumbnailReader = {
        return FTNS3BookURLThumbnailReader();
    }();
    private lazy var ns2ThumbnailReader: FTNS2BookURLThumbnailReader = {
        return FTNS2BookURLThumbnailReader();
    }();

    fileprivate var thumbReadOperationQueue = OperationQueue();
    fileprivate var readCallbacks = [Int : FTThumbReadCallbacks]();
    
    private override init() {
        super.init();

        thumbReadOperationQueue.name = "FTThumbnailREADER";
//        thumbReadOperationQueue.maxConcurrentOperationCount = 1;
        
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

        @discardableResult
        func readThumbnailFromCache(reuseToken: String?) -> String {
            return self.ns2ThumbnailReader.thumbnail(for: item
                                                     , isNS2Book: item.URL.isNS2Book
                                                     , reuseToken: reuseToken
                                                     , queue: self.thumbReadOperationQueue
                                                     , cache: self.imageCache
                                                     , onCompletion: onCompletion);
        }

        // For NS2 we are keeping the old approach of image caching
        guard !item.URL.isNS2Book else {
            return readThumbnailFromCache(reuseToken: nil)
        }

        if FTDeveloperOption.useQuickLookThumbnailing {
            // For NS3 we will be using QLThumbnail, if it fails, we will fallback to old image reading approach
            return ns3ThumbnailReader.thumbnail(for: item, queue: thumbReadOperationQueue) { image, token, fetchError in
                if nil != fetchError {
                    readThumbnailFromCache(reuseToken: token)
                }
                else {
                    self.imageCache.removeImageCache(url: item.URL);
                    onCompletion(image,token);
                }
            }
        } else {
            // If we explicilty disabled the QL thumbnail
            return readThumbnailFromCache(reuseToken: nil)
        }
    }
    
    func addImageToCache(image: UIImage?, url: URL)
    {
        self.imageCache.addImageToCache(image: image, url: url)
    }
}
