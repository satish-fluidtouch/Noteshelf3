//
//  FTGlobalSearchProvider.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 31/05/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTGlobalSearchProvider: NSObject {
    fileprivate var searchProgress: Progress?
    private var _searchKey: String = ""
    var searchKey: String {
        return _searchKey
    }

    private var currentProcessorToken = UUID().uuidString;

    private var allShelfItems: [FTShelfItemProtocol] = [FTShelfItemProtocol]()
    private var allShelfCategories: [FTShelfItemCollection] = [FTShelfItemCollection]()
    
    private var searchProcessor: FTSearchProcessor?
    var onProgressUpdate: ((_ progress: CGFloat) -> Void)?
    private var observer : AnyObject?;
    
    deinit {
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
    required convenience init(with searchTypes: [FTGlobalSearchType]) {
        self.init()

        let options = FTFetchShelfItemOptions()
        FTNoteshelfDocumentProvider.shared.fetchAllCollections( onCompeltion: {[weak self] (shelfCategories) -> (Void) in
            self?.allShelfCategories = shelfCategories
            FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option:options) {[weak self] (shelfItems) -> (Void) in
                self?.allShelfItems = (FTNoteshelfDocumentProvider.shared as FTShelfItemSorting).sortItems(shelfItems, sortOrder: FTShelfSortOrder.byName)
            }
        })
    }
    func cancelSearching(){
        self.observer?.invalidate()
        self.searchProcessor?.cancelSearching()
        self.searchProcessor = nil
        self.searchProgress?.cancel()
    }

    func fetchSearchResults(with searchKey: String, tags: [String] = [], shelfCategories: [FTShelfItemCollection] = [], onSectionFinding: ((_ items: [FTSearchSectionProtocol]) -> Void)?, onCompletion: ((_ token: String) -> ())?) {
        
        self.cancelSearching()
        var currentToken: String = ""
        let shelfCategories = shelfCategories.isEmpty ? self.allShelfCategories : shelfCategories
        //=============================
        self._searchKey = searchKey
        self.searchProcessor = FTSearchProcessorFactory.getProcessor(forType: FTGlobalSearchType.all, searchKey: searchKey, tags: tags)

        if shelfCategories.isEmpty {
            let nonNs2Books = self.allShelfItems.filter { !$0.URL.isNS2Book }
            fetchResults(items: nonNs2Books)
        } else {
            let options = FTFetchShelfItemOptions()
            let token = UUID().uuidString;
            self.currentProcessorToken = token;

            FTNoteshelfDocumentProvider.shared.fetchShelfItems(forCollections: shelfCategories, option: options, parent: nil) { [self] (shelfItems) in
                let nonNs2Books = shelfItems.filter { !$0.URL.isNS2Book }
                if token == self.currentProcessorToken {
                    fetchResults(items: nonNs2Books)
                }
            }
        }
        
        func fetchResults(items: [FTShelfItemProtocol]) {
            guard let searchProcessor = self.searchProcessor else {
                onCompletion?(currentToken);
                return;
            }
            
            self.searchProcessor?.setDataToProcess(shelfCategories: shelfCategories, shelfItems: items)
            currentToken = searchProcessor.startProcessing()
            self.searchProgress = self.searchProcessor?.progress
            
            self.observer = self.searchProgress?.observe(\.fractionCompleted,
                                                         options: [.new, .old]) { [weak self] (progress, _) in
                                                            let fraction = Float(progress.fractionCompleted);
                                                            self?.onProgressUpdate?(CGFloat(fraction))
            }
            self.searchProcessor?.onSectionFinding = {(items, token) in
                if currentToken == token {
                    onSectionFinding?(items)
                }
            }
            self.searchProcessor?.onCompletion = {(token) in
                if currentToken == token {
                    onCompletion?(currentToken)
                }
            }
        }
    }
}
