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

@objcMembers class FTDocumentItem : NSObject,FTDocumentItemProtocol,FTShelfImage,FTDocumentItemTempAttributes
{
    var uuid : String = FTUtils.getUUID();
    var documentUUID: String?
    var tempFileModificationDate: Date?

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
        if isDownloaded {
            return self.URL.fileLastOpenedDate;
        }
        return fileModificationDate;
    }
    
    required init(fileURL : Foundation.URL)
    {
        URL = fileURL;
        super.init();
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "FinishedDownload"),
                                               object: nil,
                                               queue: nil,
                                               using:
            { [weak self] (notification) in
                if self?.downloaded == false,
                    let object = notification.object as? FTDocumentItem,
                    object != self,
                    object.URL == self?.URL {
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
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "FinishedDownload"),
                                                    object: self,
                                                    userInfo: nil);
                }
            }
        }
    };

    func updateLastOpenedDate() {
        let newDate = Date();
        _fileLastOpenedDate = newDate;
        self.URL.updateLastOpenedDate(newDate);
        if nil != self.parent {
            (self.parent as? FTGroupItem)?.resetCachedDates(modified: false, lastOpened: true);
        }
    }
    
    //download progress info
    var isDownloaded : Bool {
        get {
            return self.downloaded;
        }
        set {
            if(nil == self.documentUUID
                && newValue == true
                && self.isDownloaded == false) {
                if(nil != metadataItem) {
                    FTDocumentUUIDReader.shared.readDocumentUUID(self.URL) { (documentUUID) in
                        self.documentUUID = documentUUID;
                        self.URL.readLastOpenedDate { date in
                            self._fileLastOpenedDate = date;
                            self.downloaded = newValue;
                            if let shelfCollection = self.shelfCollection as? FTShelfItemDocumentStatusChangePublisher {
                                shelfCollection.documentItem(self, didChangeDownloadStatus: newValue);
                            }
                        }
                    }
                }
                else {
                    self._fileLastOpenedDate = self.URL.fileLastOpenedDate;
                    let metaURL = self.URL.appendingPathComponent("\(METADATA_FOLDER_NAME)/\(PROPERTIES_PLIST)");
                    if let dictionary = NSDictionary.init(contentsOf: metaURL) {
                        self.documentUUID = dictionary[DOCUMENT_ID_KEY] as? String;
                    }
                    self.downloaded = newValue;
                }
            }
            else {
                if(newValue) {
                    self.URL.readLastOpenedDate { date in
                        self._fileLastOpenedDate = date;
                        self.downloaded = newValue;
                    }
                }
                else {
                    self.downloaded = newValue;
                }
            }
        }
    };
    
    var downloadProgress = Float(0) {
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
    
    var isDownloading  : Bool = false {
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
    var isUploaded : Bool = true {
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
    
    var uploadProgress = Float(0) {
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
    
    var isUploading  : Bool = false {
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
        
        if let metadataValue = metadataItem.isDownloading() {
            let value = metadataValue.boolValue;
            if(value != self.isDownloading) {
                self.isDownloading = value;
                if(value) {
                    self.downloadProgress = (metadataItem.percentDownloaded()?.floatValue)!;
                }
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
        
        if let metadataValue = metadataItem.isUploaded() {
            let value = metadataValue.boolValue;
            if(value != self.isUploaded) {
                self.isUploaded = value;
                if(!value) {
                    self.uploadProgress = Float(0);
                }
            }
        }
    }

    func updateIsUploading(_ metadataItem: NSMetadataItem) {
        if let metadataValue = metadataItem.isUploading() {
            let value = metadataValue.boolValue;
            if(value != self.isUploading) {
                self.isUploading = value;
                if(value) {
                    self.uploadProgress = (metadataItem.percentUploaded()?.floatValue)!;
                }
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
