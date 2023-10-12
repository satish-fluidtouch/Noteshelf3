//
//  NSMetadataItem_Cloud.swift
//  Noteshelf
//
//  Created by Amar on 7/11/16.
//
//

import Foundation
import FTDocumentFramework

private let globalQueue = OperationQueue.init();

extension NSMetadataItem
{
    var modificationDate: Date {
        var modifiedDate = self.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date
        if(modifiedDate == nil) {
            modifiedDate = self.creationDate;
        }
        return modifiedDate ?? Date();
    }
    
    var creationDate: Date {
        let modifiedDate = self.value(forAttribute: NSMetadataItemFSCreationDateKey) as? Date
        return modifiedDate ?? Date();
    }
    
    func lastUpdated() -> NSNumber
    {
        let date = self.modificationDate;
        let value = NSNumber.init(value: date.timeIntervalSinceReferenceDate as Double);
        return value;
    }
    
    func isItemDownloaded() -> Bool
    {
        var isDownloaded = false;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String,
            (value == NSMetadataUbiquitousItemDownloadingStatusCurrent ||
             value == NSMetadataUbiquitousItemDownloadingStatusDownloaded) {
            isDownloaded = true;
        }
        return isDownloaded;
    }

    func URL() -> Foundation.URL
    {
        var fileURL = self.value(forAttribute: NSMetadataItemURLKey) as! Foundation.URL;
        fileURL = FTDocumentUtils.url(byDeletingLeadingSlash: fileURL);
        return fileURL;
    }
    
    func downloadStatus() -> String?
    {
        var downloadStatus :  String?;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String {
            downloadStatus = value;
        }
        return downloadStatus;
    }
    
    func isDownloading() -> Bool
    {
        var downloading = false;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? NSNumber {
            downloading = value.boolValue;
        }
        return downloading;
    }
    
    func isUploaded() -> Bool
    {
        var uploaded = false;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? NSNumber {
            uploaded = value.boolValue;
        }
        return uploaded;
    }

    func isUploading() -> Bool
    {
        var uploading = false;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemIsUploadingKey) as? NSNumber {
            uploading = value.boolValue;
        }
        return uploading;
    }
    
    func percentDownloaded() -> NSNumber?
    {
        var number :  NSNumber?;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? NSNumber {
            number = value;
        }
        return number;
    }
    
    func percentUploaded() -> NSNumber?
    {
        var number :  NSNumber?;
        if let value = self.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? NSNumber {
            number = value;            
        }
        return number;
    }
}
