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
    private var currentTask: Task<Void, Never>?

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
        let viewModel = FTShelfTagsPageModel()

        if !self.tags.isEmpty {
                viewModel.processTags(reqItems: self.shelfItems, selectedTags: self.tags, progress: progress) { result in
                let booksInfo = result.filter({ $0.type == .book })
                var items = [FTSearchResultBookProtocol]()
                let sectionResult = FTSearchSectionTitles()

                let searchedBooks = booksInfo.map({ $0.documentItem })
                searchedBooks.forEach({ (shelfItem) in
                    let gridItem = FTSearchResultBook()
                    gridItem.parentSection = sectionResult
                    gridItem.shelfItem = shelfItem
                    items.append(gridItem)
                })

                let pageInfo = result.filter({ $0.type == .page })
                var searchPageContent: [FTSearchSectionContent] = []

                pageInfo.forEach { eachPageInfo in
                    let searchSectionItem: FTSearchSectionContent = FTSearchSectionContent()
                    searchSectionItem.sectionHeaderItem = eachPageInfo.documentItem
                    let searchingInfo = FTPageSearchingInfo()
                    let pageItem = FTSearchResultPage.init()
                    pageItem.parentSection = searchSectionItem
                    searchingInfo.pageUUID = eachPageInfo.pageUUID
                    searchingInfo.pageIndex = eachPageInfo.pageIndex
                    pageItem.searchingInfo = searchingInfo
                    pageItem.shelfItem = eachPageInfo.documentItem
                    searchSectionItem.addSearchItem(pageItem)
                    searchPageContent.append(searchSectionItem)
                }

                if !items.isEmpty {
                    var searchSections = [FTSearchSectionProtocol]()
                    sectionResult.items = items
                    searchSections.append(sectionResult)
                    self.onSectionFinding?(searchSections, self.token)
                }

                if !searchPageContent.isEmpty {
                    self.onSectionFinding?(searchPageContent, self.token)
                }

                if items.isEmpty && searchPageContent.isEmpty {
                    self.onSectionFinding?([], self.token)
                }

                //                            if let isCancelled = operation?.isCancelled, isCancelled == false {
                self.onCompletion?(self.token)
                //                            }
                endBackgroundTask(task)
            }
        }
    }

    func cancelSearching() {
        self.currentTask?.cancel()
    }
}
