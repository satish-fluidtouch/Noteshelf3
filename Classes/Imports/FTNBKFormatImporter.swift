//
//  FTNBKFormatImporter.swift
//  Noteshelf
//
//  Created by Amar on 15/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive

class FTNBKFormatImporter: NSObject,SSZipArchiveDelegate {
    
    fileprivate var importURL : URL!;
    fileprivate weak var collection : FTShelfItemCollection!;
    fileprivate weak var group : FTGroupItemProtocol?;
    
    var deleteSourceFileOnCompletion = true;
    
    convenience init(url : URL, collection : FTShelfItemCollection, group: FTGroupItemProtocol?) {
        self.init();
        self.importURL = url;
        self.collection = collection;
        self.group = group;
    }
    
    func startImporting(onUpdate : ((CGFloat) -> Void)?,
                        onCompletion : @escaping (NSError?,FTShelfItemProtocol?) ->Void)
    {
        let task = startBackgroundTask();
        
        FTNSDocumentUnzipper.unzipFile(atPath: self.importURL.path,
                                       onUpdate: onUpdate)
        {(path,error) in
            if(nil != error){
                if(self.deleteSourceFileOnCompletion) {
                    try? FileManager().removeItem(at: self.importURL);
                }
                endBackgroundTask(task);
                onCompletion(error,nil);
            }
            else {
                FTDocumentFactory.prepareForImportingAtURL(URL.init(fileURLWithPath: path!)) { (error, document) in
                    if(nil == error) {
                        let fileURL = document?.URL;
                        let title = fileURL!.deletingPathExtension().lastPathComponent;
                        self.collection.addShelfItemForDocument(fileURL!,
                                                                toTitle: title,
                                                                toGroup: self.group,
                                                                onCompletion: { (error, item) in
                                                                    if(self.deleteSourceFileOnCompletion) {
                                                                        try? FileManager().removeItem(at: self.importURL);
                                                                    }
                                                                    endBackgroundTask(task);
                                                                    onCompletion(error,item);
                                                                    FTCLSLog("Book Imported");
                        });
                    }
                    else {
                        if(self.deleteSourceFileOnCompletion) {
                            try? FileManager().removeItem(at: self.importURL);
                        }
                        endBackgroundTask(task);
                        onCompletion(error,nil);
                    }
                };
            }
        }
    }
}
