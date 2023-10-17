//
//  FTNotebookTitleSearchProcessor.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 04/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTNotebookTitleSearchProcessor: NSObject, FTSearchProcessor {
    private var token: String = FTUtils.getUUID()
    var onSectionFinding: (([FTSearchSectionProtocol], String) -> Void)?
    var onCompletion: ((String) -> ())?

    var progress = Progress();
    private var shelfCategories: [FTShelfItemCollection] = []
    private var searchKey: String = ""

    private lazy var searchOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.ft.ns3.search.title"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
    convenience init(with searchKey:String) {
        self.init()
        self.searchKey = searchKey
    }
    func setDataToProcess(shelfCategories: [FTShelfItemCollection],
                          shelfItems: [FTShelfItemProtocol]) {
        self.shelfCategories = shelfCategories
        self.progress.totalUnitCount = Int64(self.shelfCategories.count);
    }

    func startProcessing() -> String {
        self.processAllBooksForTitles()
        return self.token
    }
    
    func cancelSearching() {
        self.searchOperationQueue.cancelAllOperations()
    }
    private func processAllBooksForTitles(){
        let task = startBackgroundTask();
        let operation: BlockOperation = BlockOperation()
        operation.addExecutionBlock {[weak self, weak operation] in
            guard let `self` = self else {
                return
            }
            var searchSections = [FTSearchSectionProtocol]()
            //******************************************
            
            //Category Titles Search - Begin
            let categories = self.shelfCategories.filter { (eachShelf) -> Bool in
                return eachShelf.displayTitle.lowercased().contains(self.searchKey.lowercased())
            }
            if !categories.isEmpty {
                let sectionResult = FTSearchSectionCategories()
                sectionResult.searchKey = self.searchKey
                categories.forEach { (shelf) in
                    let categoryItem = FTSearchResultCategory.init(with: shelf)
                    categoryItem.parentSection = sectionResult
                    sectionResult.items.append(categoryItem)
                }
                DispatchQueue.main.async {
                    self.onSectionFinding?([sectionResult], self.token)
                }
            }
            //Category Titles Search - End
            var items = [FTSearchResultBookProtocol]()
            let sectionResult = FTSearchSectionTitles()
            sectionResult.searchKey = self.searchKey
            
            for i in 0 ..< self.shelfCategories.count {
                if operation?.isCancelled ?? false {
                    break;
                }

                let shelf = self.shelfCategories[i]
                let sema = DispatchSemaphore.init(value: 0)
                shelf.shelfItems(.byName, parent: nil, searchKey: self.searchKey, onCompletion: { (searchedItems) in
                    for shelfItem in searchedItems {
                        guard operation?.isCancelled == false else {
                            break;
                        }
                        let gridItem = FTSearchResultBook()
                        gridItem.parentSection = sectionResult
                        gridItem.shelfItem = shelfItem
                        items.append(gridItem)
                    }
                    sema.signal();
                });
                sema.wait();
                self.progress.completedUnitCount += 1
            }
            
            if !items.isEmpty {
                sectionResult.items = items
                searchSections.append(sectionResult)
            }

            //******************************************
            DispatchQueue.main.async {
                self.onSectionFinding?(searchSections, self.token)
            }
            if let isCancelled = operation?.isCancelled, isCancelled == false {
                self.onCompletion?(self.token)
            }
            endBackgroundTask(task)
        }
        self.searchOperationQueue.addOperation(operation)
    }
}
