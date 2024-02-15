//
//  CKRecord_WatchRecord_Extension.swift
//  Noteshelf
//
//  Created by Amar on 07/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import CloudKit

@objc enum FTDownloadStatus : Int {
    case notDownloaded
    case downloading
    case downloaded
}

let audioFileExtension : String = "m4a";
let audioMetadataFileExtension : String = "plist";

extension URL {
    func isUbiquitousFileExists() -> Bool {
        return FileManager().isUbiquitousItem(at: self)
    }
    #if os(watchOS)
    func urlByDeleteingPrivate() -> URL  {
        var fileItemURL = self.standardizedFileURL;
        let filePath = fileItemURL.path;
        let searchString = "/private";
        if(filePath.hasPrefix(searchString)) {
            let range = filePath.startIndex..<filePath.endIndex;
            
            fileItemURL = URL.init(fileURLWithPath: filePath.replacingOccurrences(of: searchString, with: "", options: String.CompareOptions.anchored, range: range));
        }
        return fileItemURL;
    }
    #endif

    func isAudioMetadataFile() -> Bool {
        if(self.pathExtension == audioMetadataFileExtension) {
            return true;
        }
        return false;
    }

    func isAudioFile() -> Bool {
        if(self.pathExtension == audioFileExtension) {
            return true;
        }
        return false;
    }

    func downloadStatus() -> FTDownloadStatus {
        do {
            let reachable = try self.checkPromisedItemIsReachable();
            if(reachable) {
                #if os(iOS)
                if(!self.isUbiquitousFileExists()) {
                    return FTDownloadStatus.downloaded;
                }
                #endif
                
                if(self.isDownloaded()) {
                    return FTDownloadStatus.downloaded;
                }
                else if(self.isDownloading()) {
                    return FTDownloadStatus.downloading;
                }
                else {
                    return FTDownloadStatus.notDownloaded;
                }
            }
        }
        catch {
        }
        return FTDownloadStatus.notDownloaded;
    }
    
    private func urlDownloadStatus() -> URLUbiquitousItemDownloadingStatus {
        var status = URLUbiquitousItemDownloadingStatus.notDownloaded;
        do {
            let value = try self.promisedItemResourceValues(forKeys: Set([URLResourceKey.ubiquitousItemDownloadingStatusKey]));
            let newValue = value.ubiquitousItemDownloadingStatus;
            if(newValue != nil) {
                status = newValue!;
            }
        }
        catch {
#if DEBUG
            print("Error while fetching status \(error.localizedDescription)")
#endif
        }
        return status;
    }
    
    private func isDownloaded() -> Bool {
        let status = self.urlDownloadStatus();
        if(status == .current) {
            return true;
        }
        return false;
    }
    
    private func isDownloadRequested() -> Bool {
        var isDownloadRequested = false;
        do {
            let value = try self.promisedItemResourceValues(forKeys: Set([URLResourceKey.ubiquitousItemDownloadRequestedKey]));
            let isRequested = value.ubiquitousItemDownloadRequested;
            if(nil != isRequested) {
                isDownloadRequested = isRequested!;
            }
        }
        catch {
            
        }
        return isDownloadRequested;
    }
    
    private func isDownloading() -> Bool {
        var isDownloading = false;
        do {
            let value = try self.promisedItemResourceValues(forKeys: Set([URLResourceKey.ubiquitousItemIsDownloadingKey]));
            let isDownloadingvalue = value.ubiquitousItemIsDownloading;
            if(nil != isDownloadingvalue) {
                isDownloading = isDownloadingvalue!;
            }
            if(self.isDownloadRequested()) {
                isDownloading = true;
            }
        }
        catch {
            
        }
        return isDownloading;
    }
}
