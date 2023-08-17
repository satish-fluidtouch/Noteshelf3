//
//  FTNotebookAllSearchProcessor.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 04/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTNotebookAllSearchProcessor: NSObject, FTSearchProcessor {
    private var token: String = FTUtils.getUUID()
    var onSectionFinding: (([FTSearchSectionProtocol], String) -> Void)?
    var onCompletion: ((String) -> ())?
    
    private var searchKey: String = ""
    private var tags: [String] = []
    private var shelfItems: [FTShelfItemProtocol] = []
    private var shelfCategories: [FTShelfItemCollection] = []
    
    var progress = Progress()
    private var currentProcessor: FTSearchProcessor?
    
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
        self.shelfCategories = shelfCategories
        self.shelfItems = shelfItems
        self.progress.totalUnitCount = Int64(self.shelfCategories.count + self.shelfItems.count);
    }
    
    func startProcessing() -> String {
        if !self.tags.isEmpty {
            self.processAllBooksForTags()
        } else if !self.searchKey.isEmpty {
            self.processAllBooksForTitles()
        } else {
            debugPrint("Programmer error during global search initiation")
        }
        return self.token
    }
    
    func cancelSearching() {
        self.currentProcessor?.cancelSearching()
    }

    private func processAllBooksForTitles(){
        var processingToken: String = ""
        self.currentProcessor = FTSearchProcessorFactory.getProcessor(forType: FTGlobalSearchType.titles, searchKey: searchKey)
        self.currentProcessor?.setDataToProcess(shelfCategories: self.shelfCategories, shelfItems: [FTShelfItemProtocol]())
         processingToken = self.currentProcessor!.startProcessing()
        self.progress.addChild(self.currentProcessor!.progress, withPendingUnitCount: Int64(self.shelfCategories.count))

        //=============================
        self.currentProcessor?.onSectionFinding = {[weak self] (items, token) in
            if processingToken == token {
                self?.onSectionFinding?(items, self?.token ?? "")
            }
        }
        //=============================
        self.currentProcessor?.onCompletion = {[weak self] (token) in
            if processingToken == token {
                self?.processAllBooksForContent()
            }
        }
        //=============================
    }

    private func processAllBooksForTags() {
        var processingToken: String = ""
        self.currentProcessor = FTSearchProcessorFactory.getProcessor(forType: FTGlobalSearchType.tags, searchKey: self.searchKey, tags: self.tags)
        self.currentProcessor?.setDataToProcess(shelfCategories: self.shelfCategories, shelfItems: self.shelfItems)
        processingToken = self.currentProcessor!.startProcessing()
        self.progress.addChild(self.currentProcessor!.progress, withPendingUnitCount: Int64(self.shelfItems.count))

        //=============================
        self.currentProcessor?.onSectionFinding = {[weak self] (items, token) in
            if processingToken == token {
                if self?.searchKey.isEmpty ?? false {
                    self?.onSectionFinding?(items, self?.token ?? "")

                    //=============================
                    self?.currentProcessor?.onCompletion = {[weak self] (token) in
                        if processingToken == token {
                            self?.onCompletion?(self?.token ?? "")
                        }
                    }
                    //=============================

                } else {
                    var titleResultedShelfItems: [FTShelfItemProtocol] = []
                    var contentToSearchShelfItems: [FTShelfItemProtocol] = []

                    items.forEach { searchSection in
                        if let resultBooks = searchSection.items as? [FTSearchResultBookProtocol] {
                            resultBooks.forEach { resultBook in
                                if let shelfItem = resultBook.shelfItem {
                                    contentToSearchShelfItems.append(shelfItem)
                                    if let key = self?.searchKey, shelfItem.title.contains(key) {
                                        titleResultedShelfItems.append(shelfItem)
                                    }
                                }
                            }
                        }
                    }
                    self?.shelfItems = contentToSearchShelfItems
                    let reqResultItems = self?.getCompoundResultedBooksWithTitles(shelfItems: titleResultedShelfItems) ?? []
                    if !reqResultItems.isEmpty {
                        self?.onSectionFinding?(reqResultItems, self?.token ?? "")
                    }
                    self?.processAllBooksForContent()
                }
            }
        }
    }

    private func getCompoundResultedBooksWithTitles(shelfItems: [FTShelfItemProtocol]) -> [FTSearchSectionProtocol] {
        if shelfItems.isEmpty || self.searchKey.isEmpty {
            return []
        }
        var items = [FTSearchResultBookProtocol]()
        let sectionResult = FTSearchSectionTitles()
        sectionResult.searchKey = self.searchKey
        shelfItems.forEach({ (shelfItem) in
            let gridItem = FTSearchResultBook()
            gridItem.parentSection = sectionResult
            gridItem.shelfItem = shelfItem
            items.append(gridItem)
        })
        var searchSections = [FTSearchSectionProtocol]()
        if !items.isEmpty {
            sectionResult.items = items
            searchSections.append(sectionResult)
        }
        return searchSections
    }

    private func processAllBooksForContent(){
        var processingToken: String = ""
        self.currentProcessor = FTSearchProcessorFactory.getProcessor(forType: FTGlobalSearchType.content, searchKey: self.searchKey)
        self.currentProcessor?.setDataToProcess(shelfCategories: [FTShelfItemCollection](), shelfItems: self.shelfItems)
        processingToken = self.currentProcessor!.startProcessing()
        self.progress.addChild(self.currentProcessor!.progress, withPendingUnitCount: Int64(self.shelfItems.count))
        
        //=============================
        self.currentProcessor?.onSectionFinding = {[weak self] (items, token) in
            if processingToken == token {
                self?.onSectionFinding?(items, self?.token ?? "")
            }
        }
        //=============================
        self.currentProcessor?.onCompletion = {[weak self] (token) in
            if processingToken == token {
                self?.onCompletion?(self?.token ?? "")
            }
        }
        //=============================
    }
}
