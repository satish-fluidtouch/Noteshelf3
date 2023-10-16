//
//  FTNotebookContentSearchProcessor.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 04/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTNotebookContentSearchProcessor: NSObject, FTSearchProcessor {
    private var token: String = FTUtils.getUUID()
    var onSectionFinding: (([FTSearchSectionProtocol], String) -> Void)?
    var onCompletion: ((String) -> ())?
    
    var progress = Progress();
    private var shelfItems: [FTShelfItemProtocol] = []
    private var searchKey: String = ""
    private var tags:[String] = []

    private lazy var searchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.ft.ns3.search.content"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
    convenience init(with searchKey:String, tags: [String]) {
        self.init()
        self.searchKey = searchKey
        self.tags = tags
    }

    func setDataToProcess(shelfCategories: [FTShelfItemCollection],
                          shelfItems: [FTShelfItemProtocol]) {
        self.shelfItems = shelfItems
        self.progress.totalUnitCount = Int64(self.shelfItems.count);
    }

    func startProcessing() -> String {
        self.processAllBooksForContent()
        return self.token
    }
    
    func cancelSearching() {
        self.progress.cancel();
        self.searchOperationQueue.cancelAllOperations()
    }
    
    private func processAllBooksForContent(){
        let task = startBackgroundTask();

        self.shelfItems.forEach { (shelfItem) in
            let blockOperation = FTGlobalSearchOperation();
            blockOperation.addExecutionBlock { [weak self, weak blockOperation] in
                let isDownloaded = (shelfItem as? FTDocumentItemProtocol)?.isDownloaded ?? false
                if isDownloaded == false || shelfItem.URL.isPinEnabledForDocument() {
                    self?.progress.completedUnitCount += 1
                    blockOperation?.taskCompleted()
                    return
                }

                let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read);
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { [weak self] (token, document, _) in
                    if let doc = document {
                        guard let self,
                              let notebook = doc as? FTDocumentSearchProtocol else {
                            blockOperation?.taskCompleted();
                            FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                                            token: token,
                                                                            onCompletion: nil);
                            return;
                        }
                        let searchSectionItem : FTSearchSectionContent = FTSearchSectionContent();
                        searchSectionItem.searchKey = self.searchKey
                        blockOperation?.document = doc;
                        blockOperation?.documentToken = token;
                        searchSectionItem.sectionHeaderItem = shelfItem
                        //==============================
                        let childProgress = notebook.searchDocumentsForKey(self.searchKey,
                                                                           tags: [],
                                                                           onFinding: { (page, isCancelled) in
                                if(!isCancelled) {
                                    if let searchingInfo = (page as? FTPageSearchProtocol)?.searchingInfo {
                                        let pageItem = FTSearchResultPage.init()
                                        pageItem.parentSection = searchSectionItem
                                        searchingInfo.pageUUID = page.uuid
                                        pageItem.searchingInfo = searchingInfo
                                        pageItem.shelfItem = shelfItem
                                        searchSectionItem.addSearchItem(pageItem)
                                    }
                                }
                        }, onCompletion: {[weak self] (isCancelled) in
                            if isCancelled == false {
                                guard let self else {
                                    blockOperation?.taskCompleted();
                                    return
                                }
                                if !searchSectionItem.items.isEmpty {
                                    self.onSectionFinding?([searchSectionItem], self.token)
                                }
                                blockOperation?.taskCompleted();
                            }
                        });
                        //==============================
                        self.progress.addChild(childProgress, withPendingUnitCount: 1)
                    }
                    else {
                        self?.progress.completedUnitCount += 1
                        blockOperation?.taskCompleted()
                    }
                }
            }
            self.searchOperationQueue.addOperation(blockOperation);
        }

        let operation = BlockOperation {

        };
        
        operation.completionBlock = {[weak self] in
            if let weakSelf = self {
                weakSelf.onCompletion?(weakSelf.token)
            }
            endBackgroundTask(task)
        }
        self.searchOperationQueue.addOperation(operation);
    }
}
