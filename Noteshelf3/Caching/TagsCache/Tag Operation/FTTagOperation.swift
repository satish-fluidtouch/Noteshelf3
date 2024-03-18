//
//  FTTagOperation.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias FTTagOperationBlock = (_ documentID: String
                                 ,_ document: FTNoteshelfDocument
                                 ,_ documentItem: FTShelfItemProtocol
                                 ,_ token: FTDocumentOpenToken
                                 ,_ onTaskCompletion: @escaping ()->()) -> ();

class FTTagOperation: NSObject {
    func perfomAction(_ onCompletion: (()->())?) -> Progress? {
        fatalError("subclass should override");
    }
    
    final func enumerateDocumentItems(_ documentItems: [FTShelfItemProtocol]
                                      , operationToPerform :@escaping FTTagOperationBlock
                                      , onCompletion: @escaping ()->()) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = Int64(documentItems.count);
        var documentUUIDToProcess = documentItems;
        
        func performAction(_ onCompletion: @escaping ()->()) {
            guard !documentUUIDToProcess.isEmpty else {
                onCompletion();
                return;
            }
            
            func next() {
                progress.completedUnitCount += 1;
                performAction(onCompletion)
            }
            
            let docID = documentUUIDToProcess.removeFirst();
            if let docItem = docID as? FTDocumentItemProtocol {
                func performOpen(_ item: FTDocumentItemProtocol) {
                    progress.localizedDescription = "Updating: " + item.displayTitle
                    let request = FTDocumentOpenRequest(url: item.URL, purpose: .write)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let document = document as? FTNoteshelfDocument {
                            operationToPerform(document.documentUUID,document,item,token) {
                                next();
                            }
                        }
                        else {
                            next();
                        }
                    }
                }
                
                if !docItem.isDownloaded {
                    progress.localizedDescription = "Downloading: " + docItem.displayTitle
                    let coordinator = NSFileCoordinator(filePresenter: nil)
                    coordinator.coordinate(with: [NSFileAccessIntent.readingIntent(with: docItem.URL, options: [])], queue: OperationQueue()) { error in
                        if nil != error || docItem.isPinEnabledForDocument() {
                            next();
                            return;
                        }
                        performOpen(docItem);
                    }
                }
                else {
                    performOpen(docItem);
                }
            }
            else {
                next();
            }
        }
        
        runInMainThread {
            FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
            performAction({
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                onCompletion();
            })
        }
        return progress;
    }
    
    final func enumerateDocuments(_ documentIDS:[String]
                                  , operationToPerform :@escaping FTTagOperationBlock
                                  , onCompletion: @escaping ()->()) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = Int64(documentIDS.count);
        var documentUUIDToProcess = documentIDS;
        
        func performAction(_ onCompletion: @escaping ()->()) {
            guard !documentUUIDToProcess.isEmpty else {
                onCompletion();
                return;
            }
            
            func next() {
                progress.completedUnitCount += 1;
                performAction(onCompletion)
            }
            
            let docID = documentUUIDToProcess.removeFirst();
            let relativePath = FTCachedDocument(documentID: docID).relativePath;
            FTNoteshelfDocumentProvider.shared.document(with: docID,orRelativePath: relativePath) { documentItem in
                if let docItem = documentItem {
                    func performOpen() {
                        progress.localizedDescription = "Updating: " + docItem.displayTitle
                        let request = FTDocumentOpenRequest(url: docItem.URL, purpose: .write)
                        FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                            if let document = document as? FTNoteshelfDocument {
                                operationToPerform(docID,document,docItem,token) {
                                    next();
                                }
                            }
                            else {
                                next();
                            }
                        }
                    }
                    
                    if !docItem.isDownloaded {
                        progress.localizedDescription = "Downloading: " + docItem.displayTitle
                        let coordinator = NSFileCoordinator(filePresenter: nil)
                        coordinator.coordinate(with: [NSFileAccessIntent.readingIntent(with: docItem.URL, options: [])], queue: OperationQueue()) { error in
                            if nil != error || docItem.isPinEnabledForDocument() {
                                next();
                                return;
                            }
                            performOpen();
                        }
                    }
                    else {
                        performOpen();
                    }
                }
                else {
                    next();
                }
            }
        }
        
        runInMainThread {
            FTNoteshelfDocumentProvider.shared.disableCloudUpdates();
            performAction({
                FTNoteshelfDocumentProvider.shared.enableCloudUpdates();
                onCompletion();
            })
        }
        return progress;
    }
}
