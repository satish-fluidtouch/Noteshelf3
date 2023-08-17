//
//  FTPageThumbnail.swift
//  Noteshelf
//
//  Created by Amar on 25/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTPageThumbnail : NSObject,FTPageThumbnailProtocol {
    fileprivate weak var page : FTPageProtocol?;
    fileprivate var thumbImage : UIImage?;
    fileprivate var documentUUID : String!;
    fileprivate var pageUUID : String!;
    fileprivate weak var thumbnailGenerator: FTThumbnailGenerator?
    
    @objc var shouldGenerateThumbnail : Bool = false{
        didSet{
            if(oldValue != shouldGenerateThumbnail) {
                if let curPage = self.page {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                    object: curPage,
                                                    userInfo: ["value" : shouldGenerateThumbnail]);
                }
            }
        }
    };

    required convenience init(page : FTPageProtocol, documentUUID: String, thumbnailGenerator: FTThumbnailGenerator?) {
        self.init();
        self.page = page;
        self.documentUUID = documentUUID;
        self.pageUUID = page.uuid;
        self.thumbnailGenerator = thumbnailGenerator
        
        weak var weakSelf = self;
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "FTDidFinishGeneratingThumbnail"), object: self.page, queue: nil) { (notification) in
                let image = notification.userInfo?["image"] as? UIImage
                let date = notification.userInfo?["updatedDate"] as? Date
                weakSelf?.updateThumbnail(image,updatedDate: date);
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { _ in
            weakSelf?.thumbImage = nil;
        }
    }

    func cachedThumbnailInfo(onCompletion: @escaping ((UIImage?,String) -> Void)) {
        let thumbnailPath = self.thumbnailPath()
        let pageUUID = self.pageUUID
        var img = self.thumbImage
        if nil == img && FileManager().fileExists(atPath: thumbnailPath) {
            DispatchQueue.global().async { [weak self] in
                img = UIImage.init(contentsOfFile: thumbnailPath)
                DispatchQueue.main.async {
                    self?.thumbImage = img
                    onCompletion(img, pageUUID!)
                }
            }
        } else {
            onCompletion(img, pageUUID!)
        }
    }

    func thumbnailImage(onUpdate: @escaping ((UIImage?,String) -> Void))
    {
        var fileExists = (nil == self.thumbImage) ? false : true;
        
        let pageUUID = self.pageUUID;
        if(nil == self.thumbImage) {
            let thumbnailPath = self.thumbnailPath();
            if FileManager().fileExists(atPath: thumbnailPath) {
                fileExists = true;
                self.cachedThumbnailInfo { img, str in
                    if let cachedImg = img {
                        onUpdate(cachedImg, str)
                    }
                }
            }
        }
        
        if(self.page != nil && !self.shouldGenerateThumbnail) {
            var date : AnyObject?;
            let fileURL = URL.init(fileURLWithPath: self.thumbnailPath());
            _ = try? (fileURL as NSURL).getResourceValue(&date, forKey: URLResourceKey.contentModificationDateKey);
            
            let lastUpdatedDate  = Date.init(timeIntervalSinceReferenceDate: Double(self.page!.lastUpdated.int32Value));
            if ((date as? Date)?.compare(lastUpdatedDate) == .orderedAscending)
            {
                self.shouldGenerateThumbnail = true;
            }
        }
        if(!fileExists || self.shouldGenerateThumbnail) {
            self.shouldGenerateThumbnail = true;
            if let pdfPage = self.page {
                self.thumbnailGenerator?.generateThumbnail(for: pdfPage)
            }
        }
        if(nil != self.thumbImage || !fileExists) {
            onUpdate(self.thumbImage,pageUUID!);
        }
    }

    func updateThumbnail(_ image : UIImage?,updatedDate date : Date?)
    {
        if(nil != image) {
            self.thumbImage = image;
            self.shouldGenerateThumbnail = false;
            let thumbPath = self.thumbnailPath();

            DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
                _ = try? image!.pngData()?.write(to: URL(fileURLWithPath: thumbPath), options: NSData.WritingOptions.atomicWrite);
                if(nil != date) {
                    let fileURL = URL.init(fileURLWithPath: thumbPath);
                    _ = try? (fileURL as NSURL).setResourceValue(date, forKey: URLResourceKey.contentModificationDateKey);
                }
            };
        }
    }
    
    func delete()
    {
        _ = try? FileManager.default.removeItem(atPath: self.thumbnailPath());
    }
    func cancelThumbnailGeneration() {
        if let pdfPage = self.page {
            self.thumbnailGenerator?.cancelThumbnailGeneration(for: pdfPage)
        }
    }

    fileprivate func thumbnailPath() -> String
    {
        let thumbnailFolderPath = URL.thumbnailFolderURL();
        let documentPath = thumbnailFolderPath.appendingPathComponent(self.documentUUID);
        var isDir = ObjCBool.init(false);
        if(!FileManager.default.fileExists(atPath: documentPath.path, isDirectory: &isDir) || !isDir.boolValue) {
            _ = try? FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil);
        }
        let thumbnailPath  = documentPath.appendingPathComponent(self.pageUUID);
        return thumbnailPath.path;
    }
}
