//
//  FTFileItemCopyTask.swift
//  Noteshelf
//
//  Created by Amar on 3/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FileManager
{
    static func coordinatedCopyAtURL(_ fromURL : URL,toURL : URL,onCompletion : @escaping (Bool,NSError?)->Void)
    {
        DispatchQueue.global().async {
            let fileCoorinator = NSFileCoordinator.init(filePresenter: nil);
            var error : NSError?;
            fileCoorinator.coordinate(readingItemAt: fromURL,
                                                      options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                                      writingItemAt: toURL,
                                                      options: NSFileCoordinator.WritingOptions.forReplacing,
                                                      error: &error,
                                                      byAccessor:
                { (readingURL, writingURL) in
                    var catchError : NSError?;
                    do {
                        _ = try FileManager.init().copyItem(at: readingURL, to: writingURL);
                    }
                    catch let failerror as NSError {
                        catchError = failerror;
                    }
                    DispatchQueue.main.async(execute: {
                        onCompletion((catchError != nil) ? false : true , catchError);
                    });
            });
            if(nil != error) {
                DispatchQueue.main.async(execute: {
                    onCompletion(false,error);
                });
            }
        };
    }
    
    static func coordinatedMoveAtURL(_ fromURL : URL,toURL : URL,onCompletion : @escaping (Bool,NSError?)->Void)
    {
        DispatchQueue.global().async {
            let fileCoorinator = NSFileCoordinator.init(filePresenter: nil);
            var error : NSError?;
            fileCoorinator.coordinate(writingItemAt: fromURL,
                                                      options: NSFileCoordinator.WritingOptions.forMoving,
                                                      writingItemAt: toURL,
                                                      options: NSFileCoordinator.WritingOptions.forReplacing,
                                                      error: &error,
                                                      byAccessor:
                { (fromWritingURL, toWritingURL) in
                    var catchError : NSError?;
                    do {
                        _ = try FileManager.init().moveItem(at: fromWritingURL, to: toWritingURL);
                    }
                    catch let failerror as NSError {
                        catchError = failerror;
                    }
                    DispatchQueue.main.async(execute: {
                        onCompletion((catchError != nil) ? false : true , catchError);
                    });
            });
            if(nil != error) {
                DispatchQueue.main.async(execute: {
                    onCompletion(false,error);
                });
            }
        };
    }
    
    static func copyCoordinatedItemAtURL(_ fromURL : URL,toNonCoordinatedURL toURL : URL,onCompletion : @escaping (Bool,NSError?)->Void)
    {
        DispatchQueue.global().async {
            let fileCoorinator = NSFileCoordinator.init(filePresenter: nil);
            var error : NSError?;
            fileCoorinator.coordinate(readingItemAt: fromURL,
                                                      options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                                      error: &error,
                                                      byAccessor:
                { (readingURL) in
                    var catchError : NSError?;
                    do {
                        try FileManager.init().copyItem(at: readingURL, to: toURL);
                    }
                    catch let failError as NSError {
                        catchError = failError;
                    }
                    
                    DispatchQueue.main.async(execute: {
                        onCompletion((catchError != nil) ? false : true ,catchError);
                    });
            });
            if(nil != error) {
                DispatchQueue.main.async(execute: {
                    onCompletion(false ,error);
                });
            }
        };
    }

    static func moveNonCoordinatedItemAtURL(_ fromURL : URL,toCoordinatedURL toURL : URL,onCompletion : @escaping (Bool,NSError?)->Void)
    {
        DispatchQueue.global().async {
            let fileCoorinator = NSFileCoordinator.init(filePresenter: nil);
            var error : NSError?;
            fileCoorinator.coordinate(writingItemAt: toURL,
                                                      options: NSFileCoordinator.WritingOptions.forReplacing,
                                                      error: &error,
                                                      byAccessor:
                { (writingURL) in
                    var catchError : NSError?;
                    do {
                        try FileManager.init().moveItem(at: fromURL, to: writingURL);
                    }
                    catch let failError as NSError {
                        catchError = failError;
                    }
                    DispatchQueue.main.async(execute: {
                        onCompletion((catchError != nil) ? false : true ,catchError);
                    });
            });
            if(nil != error) {
                DispatchQueue.main.async(execute: {
                    onCompletion(false ,error);
                });
            }
        };
    }
    
    static func replaceCoordinatedItem(atURL : URL,
                                       fromLocalURL fromURL : URL,
                                       onCompletion : @escaping (Error?)->())
    {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        if(atURL.isUbiquitousFileExists()) {
            let sourceModificationDate = fromURL.fileModificationDate;
            let destModificationDate = atURL.fileModificationDate;
            
            if(destModificationDate.compare(sourceModificationDate) != .orderedDescending) {
                let plistFileIntent = NSFileAccessIntent.writingIntent(with: atURL, options: NSFileCoordinator.WritingOptions.forReplacing);
                let cooridinator = NSFileCoordinator.init();
                cooridinator.coordinate(with: [plistFileIntent],
                                        queue: OperationQueue.init(),
                                        byAccessor: { (error) in
                                            var catchError : Error? = error;
                                            if(nil == error) {
                                                do {
                                                    _ = try FileManager().replaceItemAt(plistFileIntent.url, withItemAt: fromURL);
                                                }
                                                catch let fileError {
                                                    catchError = fileError;
                                                }
                                            }
                                            DispatchQueue.main.async(execute: {
                                                onCompletion(catchError);
                                            });
                                            
                })
            }
            else {
                DispatchQueue.main.async(execute: {
                    onCompletion(nil);
                });
            }
        }
        else {
            var catchError : Error? = nil;
            do {
                if(atURL.isCloudItem()) {
                    try FileManager().setUbiquitous(true, itemAt: fromURL, destinationURL: atURL);
                }
                else {
                    _ = try FileManager().replaceItemAt(atURL, withItemAt: fromURL);
                }
            }
            catch let fileError {
                catchError = fileError;
            }
            DispatchQueue.main.async(execute: {
                onCompletion(catchError);
            });
        }
        #endif
    }
}
