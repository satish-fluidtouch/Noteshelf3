//
//  FTNS3BookURLThumbnailReader.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 31/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import QuickLookThumbnailing
import FTCommon

class FTNS3BookURLThumbnailReader: NSObject {
    private let recursiveLock = NSRecursiveLock();
    private var QLRequestCache = [String: QLThumbnailGenerator.Request] ();
    
    func thumbnail(for item : FTDiskItemProtocol,
                   queue: OperationQueue,
                   onCompletion : @escaping (UIImage?,String?,Error?) -> Void) -> String? {
        let token = UUID().uuidString;
        self.cancelPreviousQLRequest(item);

        if let existingToken = self.fetchFromCurrentOpenedDocument(item, onCompletion: onCompletion) {
            return existingToken;
        }
        
        func fetchImage() {
            let operation = FTThumbnailRequestOperation(url: item.URL);
            operation.completionBlock = { [weak self] in
                runInMainThread {
                    self?.removeQLRequest(item)
                    let imgToReturn = operation.thumbnailImage;
                    onCompletion(imgToReturn,token,operation.fetchError);
                }
            };
            operation.onStartRequest = { [weak self] request in
                runInMainThread {
                    self?.addQLRequestToCache(item, request: request);
                }
            }
            queue.addOperation(operation);
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
    
    private func fetchFromCurrentOpenedDocument(_ item : FTDiskItemProtocol,
                                                onCompletion : @escaping (UIImage?,String?,Error?) -> Void) -> String? {
#if !NS2_SIRI_APP && !NOTESHELF_ACTION
        if FTNoteshelfDocumentManager.shared.isDocumentAlreadyOpen(for: item.URL) {
            let request = FTDocumentOpenRequest.init(url: item.URL, purpose: FTDocumentOpenPurpose.write);
            let tokenToReturn = UUID().uuidString;
            FTNoteshelfDocumentManager.shared.openDocument(request: request, onCmmpletion: {(_token,document,error) in
                if let doc = document {
                    onCompletion(doc.shelfImage,tokenToReturn,nil);
                    FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: _token, onCompletion: nil)
                }
                else {
                    onCompletion(nil,tokenToReturn,error);
                }
            });
            return tokenToReturn;
        }
        return nil;
#else
        return nil;
#endif
    }
}

private extension FTNS3BookURLThumbnailReader {
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
}

private class FTThumbnailRequestOperation: Operation {
    private var fileURL: URL;
    private(set) var thumbnailImage: UIImage?;
    private(set) var fetchError: Error?;
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
        let request = fileURL.fetchQLThumbnail(completion: { (image,error) in
            self.thumbnailImage = image;
            self.fetchError = error;
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
