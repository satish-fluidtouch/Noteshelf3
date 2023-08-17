//
//  FTNSDocumentUnzipper.swift
//  Noteshelf
//
//  Created by Amar on 10/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive

class FTNSDocumentUnzipper: NSObject {
    static func unzipFile(atPath : String,
                          onUpdate : ((CGFloat) -> Void)?,
                          onCompletion:@escaping (String?,NSError?)->Void)
    {
        self.decompressFile(atPath: atPath,
                            onUpdate: onUpdate,
                            currentIteration: 0,
                            onCompletion: onCompletion);
    }
    
    
    private static func decompressFile(atPath path : String,
                                       onUpdate : ((CGFloat) -> Void)?,
                                       currentIteration iteration : Int,
                                       onCompletion:@escaping (String?,NSError?)->Void)
    {
        let cacheURL = NSURL.init(fileURLWithPath: FTUtils.applicationCacheDirectory()) as URL;
        var outputPath = cacheURL.appendingPathComponent("Unzipper");
        try? FileManager().removeItem(at: outputPath);
        
        SSZipArchive.unzipFile(atPath: path, toDestination: outputPath.path, progressHandler: { (path, sizeInfo, entryNumber,total) in
            if(nil != onUpdate) {
                let progress = CGFloat(entryNumber)/CGFloat(total);
                onUpdate!(progress);
            }
        }) { (path, success, error) in
            if(!success || (nil != error)) {
                onCompletion(nil,error! as NSError);
                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                if let err = error {
                    let attri : [String: Any] = ["error":err,"Loc":"Book Import"]
                    FTLogError("Unarchive Failed", attributes: attri);
                }
                #endif
            }
            else {
                do {
                    let files = try FileManager().contentsOfDirectory(atPath: outputPath.path);
                    outputPath = outputPath.appendingPathComponent(files.last!);
                    if(outputPath.pathExtension == "zip") {
                        if(iteration < 3) {
                            let newIteration = iteration+1;
                            var tempPath = NSURL.init(fileURLWithPath: NSTemporaryDirectory()) as URL;
                            tempPath.appendPathComponent(outputPath.lastPathComponent);
                            try? FileManager().removeItem(at: tempPath);
                            try FileManager().moveItem(at: outputPath, to: tempPath);
                            self.decompressFile(atPath: tempPath.path,
                                                onUpdate: onUpdate,
                                                currentIteration : newIteration,
                                                onCompletion: {(outPath,error) in
                                                    try? FileManager().removeItem(at: tempPath);
                                                    onCompletion(outPath,error);
                            });
                        }
                        else {
                            let error = NSError.init(domain: "NSIMPORTERROR", code: 1002, userInfo: nil);
                            onCompletion(nil,error);
                        }
                    }
                    else {
                        /*
                        added below check to compare the file names one with coming from SSziparchive after unzip and
                        the one with input file name. This is bcoz in case of chinese / japanese filename on unzip using SSZipArchive
                         the file name is used to change to something elese due to string encoding used in ZipArchive.
                         To overcome this issue we are forced to compare the names and change if needed.
                        */
                        let inputURL = URL.init(fileURLWithPath: path);
                        let fileName = inputURL.deletingPathExtension().lastPathComponent;
                        let curFileName = outputPath.deletingPathExtension().lastPathComponent;
                        
                        if fileName != curFileName {
                            let ext = outputPath.pathExtension;
                            let newURL =  outputPath.deletingLastPathComponent().appendingPathComponent(fileName).appendingPathExtension(ext);
                            try? FileManager().moveItem(at: outputPath, to: newURL);
                            outputPath = newURL;
                        }
                        onCompletion(outputPath.path,nil);
                    }
                }
                catch let error as NSError
                {
                    onCompletion(nil,error);
                }
            }
        };
    }

}
