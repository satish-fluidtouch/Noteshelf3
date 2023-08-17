//
//  FTGoogleDriveFileDownloader.swift
//  Noteshelf
//
//  Created by Amar on 8/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//
#if !targetEnvironment(macCatalyst)
import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher

class FTGoogleDriveFileDownloader : NSObject,FTCloudDownloadProtocol
{
    func downloadItems(_ items: [AnyObject], onCompletion: @escaping ((String?, NSError?) -> (Void))) -> Progress {
        let progress = Progress.init();
        return progress
    }
    
    fileprivate var downloadFetcher : GTMSessionFetcher?;
    
    var title: String!
    {
        return "Google Drive";
    }
    
    func downloadItem(_ item: AnyObject, onCompletion: @escaping ((String?, NSError?) -> (Void))) -> Progress {
        let driveFile = item as! GTLRDrive_File;
        
        let  query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: driveFile.identifier!);

        let progress = Progress.init();
        progress.totalUnitCount = driveFile.size!.int64Value;
        progress.localizedDescription = NSLocalizedString("Downloading", comment: "Downloading...");

        progress.isCancellable = true;
        progress.cancellationHandler = {
            self.downloadFetcher?.stopFetching();            
            progress.cancellationHandler = nil;
            onCompletion(nil,self.downloadCancelError);
        };
        
        let fileName = (driveFile.name! as NSString).validateFileName() as NSString;
        let destPath = NSTemporaryDirectory().appendingFormat("%@", fileName);
        _ = try? FileManager.init().removeItem(atPath: destPath);

        let driveService = FTGoogleDriveManager.shared().driveService;
        let request = driveService?.request(for: query);
        let fetcher = driveService?.fetcherService.fetcher(with: request! as URLRequest);

        fetcher?.destinationFileURL = URL.init(fileURLWithPath:destPath);

        fetcher?.downloadProgressBlock = {
            (bytesWritten,totalBytesWritten,totalBytesExpectedToWrite) in
            progress.completedUnitCount = totalBytesWritten;
        }
        
        fetcher?.beginFetch { (data, error) in
            progress.cancellationHandler = nil;
            onCompletion(destPath,error as NSError?);
        };
        self.downloadFetcher = fetcher;
        
        return progress;
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(#function) in \(String(describing: #file.components(separatedBy: "/").last))");
        #endif
    }
}
#endif
