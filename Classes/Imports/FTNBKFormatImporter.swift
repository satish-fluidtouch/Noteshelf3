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
    fileprivate weak var shelfItem : FTShelfItemProtocol?;

    var deleteSourceFileOnCompletion = true;
    
    convenience init(url : URL, collection : FTShelfItemCollection, group: FTGroupItemProtocol?, shelfItem: FTShelfItemProtocol?) {
        self.init();
        self.importURL = url;
        self.collection = collection;
        self.group = group;
        self.shelfItem = shelfItem;
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
                let filePath = URL(fileURLWithPath: path!);
                if let shelfItem = self.shelfItem {
                    let docrequest = FTDocumentOpenRequest(url: filePath, purpose: .read)
                    FTNoteshelfDocumentManager.shared.openDocument(request: docrequest) { docToken, ftDocument, error in
                        if let ftDocument = ftDocument as? FTNoteshelfDocument, error == nil {
                            let pages = ftDocument.pages().map { eachPage in
                                return eachPage as! FTThumbnailable
                            }
                            _ = ftDocument.movePages(pages, toDocument: shelfItem.URL, pin: nil) { error in
                                FTNoteshelfDocumentManager.shared.saveAndClose(document: ftDocument, token: docToken) { _ in
                                    endBackgroundTask(task);
                                    onCompletion(error as NSError?, shelfItem);
                                }
                            }
                        } else {
                            endBackgroundTask(task);
                            onCompletion(nil, nil);
                        }
                    }
                } else {
                    let recoveryPath = filePath.appending(path: NOTEBOOK_RECOVERY_PLIST);
                    if FileManager.default.fileExists(atPath: recoveryPath.path(percentEncoded: false)) {
                        try? FileManager.default.removeItem(at: recoveryPath)
                    }
                    
                    FTDocumentFactory.prepareForImportingAtURL(filePath) { (error, document) in
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
}
