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
    private let recursiveLock = NSRecursiveLock();
    
    //*****************
    private var imageCache: FTThumbnailCacheProtocol = FTThumbnailCache()
    //*****************
    
    fileprivate var thumbReadOperationQueue = OperationQueue();
    fileprivate var readCallbacks = [Int : FTThumbReadCallbacks]();
    
    private override init() {
        super.init();

        thumbReadOperationQueue.name = "FTThumbnailREADER";
        thumbReadOperationQueue.maxConcurrentOperationCount = 1;
        
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
        let reqid = item.URL.hashKey;
        recursiveLock.lock();
        self.QLRequestCache.removeValue(forKey: reqid);
        recursiveLock.unlock();
    }
    
    func cancelPreviousQLRequest(_ item: FTDiskItemProtocol) {
        let reqid = item.URL.hashKey;
        recursiveLock.lock();
        let request = self.QLRequestCache[reqid]
        recursiveLock.unlock();
        
        if let _request = request {
            QLThumbnailGenerator.shared.cancel(_request);
            self.removeQLRequest(item);
        }
    }
    
    func addQLRequestToCache(_ item: FTDiskItemProtocol,request: QLThumbnailGenerator.Request) {
        let reqid = item.URL.hashKey;
        recursiveLock.lock();
        self.QLRequestCache[reqid] = request;
        recursiveLock.unlock();
    }
    
    func thumbnailForNS3Book(_ item : FTDiskItemProtocol,
                             onCompletion : @escaping (UIImage?,String?) -> Void) -> String? {
        let token = UUID().uuidString;
        self.cancelPreviousQLRequest(item);
        
        func fetchImage() {
            let operation = FTThumbnailRequestOperation(url: item.URL);
            operation.completionBlock = { [weak self] in
                runInMainThread {
                    self?.removeQLRequest(item)
                    var imgToReturn = operation.thumbnailImage;
                    if nil == imgToReturn {
                        imgToReturn = self?.imageCache.cachedImageForItem(item: item);
                    }
                    onCompletion(imgToReturn,token);
                }
            };
            operation.onStartRequest = { [weak self] request in
                runInMainThread {
                    self?.addQLRequestToCache(item, request: request);
                }
            }
            thumbReadOperationQueue.addOperation(operation);
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

private class FTThumbnailRequestOperation: Operation {
    private var fileURL: URL;
    private(set) var thumbnailImage: UIImage?;
    var onStartRequest: ((QLThumbnailGenerator.Request)->())?;
    
    init(url: URL) {
        fileURL = url;
    }
    
    private var startedExecuting = false;
    private var _isfinished: Bool = false {
        willSet {
            if startedExecuting {
                self.willChangeValue(forKey: "isFinished")
            }
        }
        didSet {
            if startedExecuting {
                self.didChangeValue(forKey: "isFinished");
            }
        }
    }
    
    override var isAsynchronous: Bool {
        return true;
    }
    
    override var isFinished: Bool {
        return _isfinished;
    }
    
    override func main() {
        self.startedExecuting = true;
        let request = fileURL.fetchQLThumbnail(completion: { image in
            self.thumbnailImage = image;
            self._isfinished = true;
        })
        onStartRequest?(request);
        onStartRequest = nil;
    }
    
    override func cancel() {
        super.cancel();
        self._isfinished = true;
    }
}
