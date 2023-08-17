//
//  FTGoogleDriveFilePDFDownloader.swift
//  Noteshelf
//
//  Created by Amar on 10/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//
#if !targetEnvironment(macCatalyst)
import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher

class FTGoogleDriveFilePDFDownloader : NSObject,FTCloudDownloadProtocol
{
    func downloadItems(_ items: [AnyObject], onCompletion: @escaping ((String?, NSError?) -> (Void))) -> Progress {
        let progress = Progress.init();
        return progress
    }
    
    func downloadItem(_ item : AnyObject,onCompletion:@escaping ((String?,NSError?)->(Void))) -> Progress
    {
        let file = item as! GTLRDrive_File;
        var downloadFetcher : GTMSessionFetcher?;
        var uploadTicket : GTLRServiceTicket?;
        
        let progress = Progress.init();
        progress.totalUnitCount = 100;
        progress.localizedDescription = NSLocalizedString("Downloading", comment: "Downloading...");

        progress.isCancellable = true;
        progress.cancellationHandler = {
            if(downloadFetcher != nil) {
                downloadFetcher?.stopFetching();
            }
            else {
                uploadTicket?.cancel();
            }
            progress.cancellationHandler = nil;
            onCompletion(nil,self.downloadCancelError);
        };
        
        self.getMimeType(file,completionHandler:{ (mimeType,error) in
            if(nil == error) {
                uploadTicket = self.copyFile(file,mimeType : mimeType!,updateHandler: { (percentage) in
                    let percentComplete = (Float(percentage)*0.5)*100
                    progress.completedUnitCount = Int64(percentComplete);
                    },onCompletion : { (error,uploadedFile) in
                        if(nil == error) {
                            downloadFetcher = self.downloadFile(uploadedFile!,updateHandler : { (percentage) in
                                let percentComplete = (Float(percentage)*0.5)*100
                                progress.completedUnitCount = Int64(percentComplete)+50;
                                }, onCompletion:{ (location,error) in
                                    self.deleteFile(uploadedFile!,onCompletion : { (_) in
                                        onCompletion(location,error);
                                    });
                            });
                        }
                        else {
                            onCompletion(nil,error);
                        }
                });
            }
            else {
                onCompletion(nil,error);
            }
        });
        return progress;
    }
    
    fileprivate func getMimeType(_ driveFile : GTLRDrive_File,
                             completionHandler:@escaping ((String?,NSError?) -> Void))
    {
        let query = GTLRDriveQuery_AboutGet.query();
        query.fields =  "importFormats,exportFormats";
        let service = FTGoogleDriveManager.shared().driveService;
        service?.executeQuery(query) { (_,someObject,error) in
            var mimeType : String?;
            if(nil == error) {
                let importFormats = (someObject as! GTLRDrive_About).importFormats;
                let json = importFormats?.json;
                if(nil != json) {
                    mimeType = (json!.object(forKey: driveFile.mimeType!) as? [String])!.last;
                }
            }
            completionHandler(mimeType,error as NSError?);
        }
    }
    
    fileprivate func copyFile(_ driveFile : GTLRDrive_File,
                          mimeType : String,
                          updateHandler : @escaping ((CGFloat) -> Void),
                          onCompletion : @escaping ((NSError?,GTLRDrive_File?) -> Void)) -> GTLRServiceTicket
    {
        let emptyFile = GTLRDrive_File();
        let query = GTLRDriveQuery_FilesCopy.query(withObject: emptyFile,fileId:driveFile.identifier!);
        emptyFile.mimeType = mimeType;
        
        let service = FTGoogleDriveManager.shared().driveService!;
        
        
        let queryCompletion = { (serviceTicket: GTLRServiceTicket, uploadedFile: Any?, error: Error?) in
            onCompletion(error as NSError?,uploadedFile as? GTLRDrive_File);
        };
        
        let ticket = service.executeQuery(query, completionHandler: queryCompletion);
        
        ticket.objectFetcher!.sendProgressBlock = { (bytesSent,totalBytesSent,totalBytesExpectedToSend) in
            let percentage = CGFloat(totalBytesSent)/CGFloat(totalBytesExpectedToSend)
            updateHandler(percentage);
        }
        return ticket;
    }
    
    fileprivate func downloadFile(_ driveFile : GTLRDrive_File,
                              updateHandler : @escaping ((CGFloat )-> Void),
                              onCompletion : @escaping ((String?,NSError?)->Void)) -> GTMSessionFetcher
    {
        let fileName = ((driveFile.name! as NSString).validateFileName() as NSString).deletingPathExtension;
        let destPath = NSTemporaryDirectory().appendingFormat("%@.pdf", fileName);
        _ = try? FileManager.init().removeItem(atPath: destPath);
        
        let driveService = FTGoogleDriveManager.shared().driveService;
        let  query = GTLRDriveQuery_FilesExport.queryForMedia(withFileId: driveFile.identifier!,mimeType:"application/pdf");
        let request = driveService!.request(for: query);
        let fetcher = driveService!.fetcherService.fetcher(with: request as URLRequest);
        
        fetcher.destinationFileURL = URL(fileURLWithPath:destPath);
        
        fetcher.downloadProgressBlock = {
            (bytesWritten,totalBytesWritten,totalBytesExpectedToWrite) in
            let value = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite);
            updateHandler(CGFloat(value));
        }
        
        let fetchCompletion = { (data: Data?, error: Error?) in
            onCompletion(destPath, error as NSError?);
        };
        fetcher.beginFetch(completionHandler: fetchCompletion);
        return fetcher;
    }
    
    
    fileprivate func deleteFile(_ file : GTLRDrive_File, onCompletion : @escaping ((NSError?) -> Void))
    {
        let deleteQuery = GTLRDriveQuery_FilesDelete.query(withFileId: file.identifier!);
        let driveService = FTGoogleDriveManager.shared().driveService;
        
        let queryCompletion = { (serviceTicket: GTLRServiceTicket, object: Any?, error: Error?) in
            onCompletion(error as NSError?);
        };
        
        driveService?.executeQuery(deleteQuery, completionHandler: queryCompletion)
    }
}
#endif
