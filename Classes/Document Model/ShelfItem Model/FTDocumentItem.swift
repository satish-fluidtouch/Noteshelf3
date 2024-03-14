//
//  FTDocumentItem.swift
//  Noteshelf
//
//  Created by Amar on 14/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

let CloudBookDownloadDebuggerLog = true;

protocol FTDocumentItemTempAttributes: NSObjectProtocol {
    var tempFileModificationDate: Date? {get set};
}

extension NSNotification.Name {
    static let didChangeURL =  NSNotification.Name(rawValue: "DidChangeURL")
}

@objcMembers class FTDocumentItem : NSObject,FTDocumentItemProtocol,FTDocumentItemTempAttributes
{
    var uuid : String = FTUtils.getUUID();
    var documentUUID: String?
    var tempFileModificationDate: Date?

    private weak var finishDownloadNotificationObserver: NSObjectProtocol?;
    
    weak var metadataItem: NSMetadataItem?;
    var fileCreationDate: Date {
        if let metadata = metadataItem {
            return metadata.creationDate
        }
        if FileManager().fileExists(atPath: self.URL.path) {
            return self.URL.fileCreationDate;
        }
        return Date();
    }
    
    private var _fileLastOpenedDate: Date?;
    var fileLastOpenedDate: Date {
        if isDownloaded, nil == _fileLastOpenedDate {
            if let docID = self.documentUUID {
#if !NOTESHELF_ACTION
                debugLog("fileModDate: reading lastOpenedDocument : \(self.URL.title)")
                let cache = FTDocumentCache.shared.cachedLocation(for: docID);
                _fileLastOpenedDate = cache.fileLastOpenedDate;
#endif
            }
        }
        if let inlastopenedDate = _fileLastOpenedDate
            , inlastopenedDate.compare(self.fileModificationDate) == .orderedAscending {
            _fileLastOpenedDate = self.fileModificationDate;
        }
        return _fileLastOpenedDate ?? self.fileModificationDate;
    }
    
    required init(fileURL : Foundation.URL)
    {
        URL = fileURL;
        super.init();
        // This is Mainly used to set the download status for the starred items.
        self.finishDownloadNotificationObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "FinishedDownload_\(self.URL.hashKey)"),
                                               object: nil,
                                               queue: nil,
                                               using:
                                                { [weak self] (notification) in
            if self?.downloaded == false
                ,let object = notification.object as? FTDocumentItem
                ,object != self {
                self?.documentUUID = object.documentUUID;
                self?.downloaded = object.downloaded;
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshRecent"),
                                                object: self,
                                                userInfo: nil);
            }
        })
    }

    override var hash: Int {
        return self.uuid.hashValue;
    }
    
    private(set) var downloaded = false {
        willSet{
            if(newValue != self.downloaded) {
                self.willChangeValue(forKey: "downloaded");
            }
        }
        didSet{
            if(oldValue != self.downloaded) {
                self.didChangeValue(forKey: "downloaded");
                if(self.downloaded) {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "FinishedDownload_\(self.URL.hashKey)"),
                                                    object: self,
                                                    userInfo: nil);
                }
            }
        }
    };

    func updateLastOpenedDate() {
        self.setLastOpenedDate(Date());
        if nil != self.parent {
            (self.parent as? FTGroupItem)?.resetCachedDates(modified: false, lastOpened: true);
        }
    }
    
    //download progress info
    @objc dynamic var isDownloaded : Bool {
        get {
            return self.downloaded;
        }
        set {
            if(nil == self.documentUUID
                && newValue == true
                && self.isDownloaded == false) {
                
                FTDocumentPropertiesReader.shared.readDocumentUUID(self.URL) { (docProperties) in
                    self.documentUUID = docProperties.documentID;
                    if FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE {
                        self._fileLastOpenedDate = nil;
                        if let date = docProperties.lastOpnedDate {
                            self.setLastOpenedDate(date)
                        }
                    }
                    self.downloaded = newValue;
                    if nil != self.metadataItem
                        , let shelfCollection = self.shelfCollection as? FTShelfItemDocumentStatusChangePublisher {
                        shelfCollection.documentItem(self, didChangeDownloadStatus: newValue);
                    }
                }
            }
            else {
                if(newValue) {
                    if FTDocumentPropertiesReader.USE_EXTENDED_ATTRIBUTE {
                        FTDocumentPropertiesReader.shared.readDocumentUUID(self.URL) { (docProperties) in
                            debugLog("fileModDate: Updating last openDate : \(self.URL.title)")
                            self._fileLastOpenedDate = nil;
                            if let date = docProperties.lastOpnedDate {
                                self.setLastOpenedDate(date)
                            }
                            self.downloaded = newValue;
                            if nil != self.metadataItem
                                , let shelfCollection = self.shelfCollection as? FTShelfItemDocumentStatusChangePublisher {
                                shelfCollection.documentItem(self, didChangeDownloadStatus: newValue);
                            }
                        }
                    }
                    else {
                        self.downloaded = newValue;
                    }
                }
                else {
                    self.downloaded = newValue;
                }
            }
        }
    };
    
    @objc dynamic var downloadProgress = Float(0) {
        willSet {
            if(newValue != self.downloadProgress) {
                self.willChangeValue(forKey: "downloadProgress");
            }
        }
        didSet {
            if(oldValue != self.downloadProgress) {
                //debug purpose
                if(CloudBookDownloadDebuggerLog && (self.downloadProgress != 100)) {
                    if(oldValue == 0) {
                        FTCLSLog("Book: \(self.displayTitle): Download started \(self.downloadProgress)");
                    }
                    else if(oldValue < 75 && self.downloadProgress >= 75) {
                        FTCLSLog("Book: \(self.displayTitle): Download Progress 75%");
                    }
                    else if(oldValue < 50 && self.downloadProgress >= 50) {
                        FTCLSLog("Book: \(self.displayTitle): Download Progress 50%");
                    }
                    else if(oldValue < 25 && self.downloadProgress >= 25) {
                        FTCLSLog("Book: \(self.displayTitle): Download Progress 25%");
                    }
                }
                //debug purpose
                self.didChangeValue(forKey: "downloadProgress");
            }
        }
    };
    
    @objc dynamic var isDownloading  : Bool = false {
        willSet {
            if(newValue != self.isDownloading) {
                self.willChangeValue(forKey: "isDownloading");
            }
        }
        didSet {
            if(oldValue != self.isDownloading) {
                self.didChangeValue(forKey: "isDownloading");
            }
        }
    };
    
    var URL : URL {
        didSet {
            if(oldValue != self.URL) {
                NotificationCenter.default.post(name: .didChangeURL, object: self, userInfo: nil)
            }
        }
    };
    
    //upload progress info
    @objc dynamic var isUploaded : Bool = true {
        willSet {
            if(newValue != self.isUploaded) {
                self.willChangeValue(forKey: "isUploaded");
            }
        }
        didSet {
            if(oldValue != self.isUploaded) {
                self.didChangeValue(forKey: "isUploaded");
            }
        }
    };
    
    @objc dynamic var uploadProgress = Float(0) {
        willSet {
            if(newValue != self.uploadProgress) {
                self.willChangeValue(forKey: "uploadProgress");
            }
        }
        didSet {
            if(oldValue != self.uploadProgress) {
                self.didChangeValue(forKey: "uploadProgress");
            }
        }
    };
    
    @objc dynamic var isUploading  : Bool = false {
        willSet {
            if(newValue != self.isUploading) {
                self.willChangeValue(forKey: "isUploading");
            }
        }
        didSet {
            if(oldValue != self.isUploading) {
                self.didChangeValue(forKey: "isUploading");
            }
        }
    };
    
    weak var parent : FTGroupItemProtocol? ;
    weak var shelfCollection: FTShelfItemCollection!

    deinit {
        if let observer = self.finishDownloadNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #if DEBUG
        debugPrint("deinit :\(self.URL.path.removingPercentEncoding ?? ""))");
        #endif
    }
    
    var fileModificationDate: Date {
        if let _date = self.tempFileModificationDate {
            return _date;
        }
        if self.metadataItem != nil {
            return self.metadataItem?.modificationDate ?? Date();
        }
        return self.URL.fileModificationDate
    }
    
    func updateShelfItemInfo(_ metadataItem : NSMetadataItem)
    {
        self.metadataItem = metadataItem;
        if let tempTime = self.tempFileModificationDate,
            tempTime.compare(self.URL.fileModificationDate) == ComparisonResult.orderedAscending {
            self.tempFileModificationDate = nil;
        }
        
        self.URL = metadataItem.URL();
        
        self.updateIsDownloaded(metadataItem);
        self.updateIsDownloading(metadataItem);
        self.updatePercenDownload(metadataItem);
        
        self.updateIsUploaded(metadataItem);
        self.updateIsUploading(metadataItem);
        self.updatePercentUpload(metadataItem);
    }
}

private extension FTDocumentItem {
    
    func updateIsDownloaded(_ metadataItem: NSMetadataItem) {
        let value = metadataItem.isItemDownloaded();
        if(value != self.isDownloaded) {
            self.isDownloaded = value;
            if(!value) {
                self.downloadProgress = Float(0);
            }
        }
    }
    
    func updateIsDownloading(_ metadataItem: NSMetadataItem) {
        let metadataValue = metadataItem.isDownloading()
        if metadataValue != self.isDownloading {
            self.isDownloading = metadataValue;
            if(metadataValue) {
                self.downloadProgress = (metadataItem.percentDownloaded()?.floatValue)!;
            }
        }
    }
    
    func updatePercenDownload(_ metadataItem: NSMetadataItem) {
        if let metadataValue = metadataItem.percentDownloaded() {
            let value = metadataValue.floatValue;
            if(value != self.downloadProgress) {
                self.downloadProgress = value;
            }
        }
    }

    func updateIsUploaded(_ metadataItem: NSMetadataItem) {
        
        let metadataValue = metadataItem.isUploaded()
        if(metadataValue != self.isUploaded) {
            self.isUploaded = metadataValue;
            if(!metadataValue) {
                self.uploadProgress = Float(0);
            }
        }
    }

    func updateIsUploading(_ metadataItem: NSMetadataItem) {
        let metadataValue = metadataItem.isUploading()
        if(metadataValue != self.isUploading) {
            self.isUploading = metadataValue;
            if(metadataValue) {
                self.uploadProgress = (metadataItem.percentUploaded()?.floatValue)!;
            }
        }
    }

    func updatePercentUpload(_ metadataItem: NSMetadataItem) {
        if let metadataValue = metadataItem.percentUploaded() {
            let value = metadataValue.floatValue;
            if(value != self.uploadProgress) {
                self.uploadProgress = value;
            }
        }
    }
}

private extension FTDocumentItem {
    func setLastOpenedDate(_ date: Date) {
#if !NOTESHELF_ACTION
        guard let docID = self.documentUUID else {
            _fileLastOpenedDate = date;
            return;
        }
        var cache = FTDocumentCache.shared.cachedLocation(for: docID);
        guard FileManager().fileExists(atPath: cache.path(percentEncoded: false))  else {
            _fileLastOpenedDate = date;
            return;
        }
        if let fileModDate = cache.getExtendedAttribute(for: .lastOpenDateKey)?.dateValue {
            if fileModDate.compare(date) == ComparisonResult.orderedAscending {
                debugLog("fileModDate: income date is lastest :\(self.URL.relativePathWRTCollection())  - \(fileModDate) -\(date)")
                _fileLastOpenedDate = date;
                debugLog("fifileModDate: before update: \(cache.fileModificationDate)")
                try? cache.updateLastOpenedDate(date)
                debugLog("fifileModDate: after update: \(cache.fileModificationDate)")
            }
            else {
                debugLog("fileModDate: cache date is lastest :\(self.URL.relativePathWRTCollection())  - \(fileModDate) -\(date)")
                _fileLastOpenedDate = fileModDate;
            }
        }
        else {
            _fileLastOpenedDate = date;
            try? cache.updateLastOpenedDate(date)
        }
#else
        _fileLastOpenedDate = date;
#endif
    }
}
