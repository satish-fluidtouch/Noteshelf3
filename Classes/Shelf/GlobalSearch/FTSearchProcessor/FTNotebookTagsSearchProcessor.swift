//
//  FTNotebookTagsSearchProcessor.swift
//  Noteshelf3
//
//  Created by Narayana on 17/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTNotebookTagsSearchProcessor: NSObject, FTSearchProcessor {
    private var token: String = FTUtils.getUUID()
    var onSectionFinding: (([FTSearchSectionProtocol], String) -> Void)?
    var onCompletion: ((String) -> ())?

    var progress = Progress()

    private var tags: [String] = []
    private var shelfItems: [FTShelfItemProtocol] = []
    private var isCancelled: Bool = false;

    deinit {
#if DEBUG
        NSLog(">>>>> deinit \(self.classForCoder)");
#endif
    }

    convenience init(with tags: [String]) {
        self.init()
        self.tags = tags
    }

    func setDataToProcess(shelfCategories: [FTShelfItemCollection], shelfItems: [FTShelfItemProtocol]) {
        self.shelfItems = shelfItems
        self.progress.totalUnitCount = Int64(shelfItems.count + shelfCategories.count)
    }

    func startProcessing() -> String {
        self.processAllBooksForTags()
        return self.token
    }

    private func processAllBooksForTags() {
        let task = startBackgroundTask()
        
        progress.totalUnitCount = 1;
        DispatchQueue.global(qos: .background).async {[weak self] in
            guard let self, !self.isCancelled else {
                self?.progress.completedUnitCount += 1;
                self?.onCompletion?(self?.token ?? "")
                endBackgroundTask(task)
                return;
            }
            
            if !self.tags.isEmpty {
                let tags = FTTagsProvider.shared.getTagsfor(self.tags,shouldCreate: false);
                var documentIDs = Set<String>();
                tags.enumerated().forEach { eachItem in
                    let items = eachItem.element.documentIDs;
                    documentIDs = documentIDs.union(items);
                }
                
                var filteredDocuments = [String:String]();
                documentIDs.forEach { eachItem in
                    let document = FTCachedDocument(documentID: eachItem);
                    let tags = Set(document.docuemntTags);
                    if self.tags.allSatisfy(tags.contains(_:)) {
                        filteredDocuments[eachItem] = document.relativePath ?? "";
                    }
                }
                
                self.progress.totalUnitCount += Int64(filteredDocuments.count);
                self.progress.completedUnitCount += 1;
                let sectionResult = FTSearchSectionTitles()
                sectionResult.items = [FTSearchResultBookProtocol]();
                func findShelfItems() {
                    guard let firstValue = filteredDocuments.first else {
                        self.onCompletion?(self.token)
                        endBackgroundTask(task)
                        return;
                    }
                    
                    let key = firstValue.key;
                    let relativePath = filteredDocuments.removeValue(forKey: firstValue.key) ?? "";
                    
                    var docItem: FTShelfItemProtocol?
                    for eachItem in self.shelfItems {
                        if eachItem.uuid == key {
                            docItem = eachItem;
                            break;
                        }
                        else if !relativePath.isEmpty
                                    ,eachItem.URL.relativePathWRTCollection() == relativePath {
                            docItem = eachItem;
                        }
                    }
                    
                    if let shelfItem = docItem {
                        let gridItem = FTSearchResultBook()
                        gridItem.parentSection = sectionResult
                        gridItem.shelfItem = shelfItem;
                        sectionResult.items.append(gridItem);
                        sectionResult.items.sort { item1, item2 in
                            item1.title.compare(item2.title, options: [.caseInsensitive,.numeric], range: nil, locale: nil) == .orderedAscending;
                        }
                        self.onSectionFinding?([sectionResult], self.token)
                    }
                    self.progress.completedUnitCount += 1;
                    findShelfItems()
                }
                findShelfItems();
            }
            else {
                self.onCompletion?(self.token);
            }
        }
    }

    func cancelSearching() {
        self.isCancelled = true;
    }
}
