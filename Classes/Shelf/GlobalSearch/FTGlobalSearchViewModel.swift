//
//  FTGlobalSearchViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 01/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTGlobalSearchResultType: Int {
    case results = 0
    case noResults = 1
}

internal typealias FTGlobalSearchDataSource = UICollectionViewDiffableDataSource<FTGlobalSearchResultType, AnyHashable>
internal typealias FTGlobalSearchSnapShot = NSDiffableDataSourceSnapshot<FTGlobalSearchResultType, AnyHashable>

class FTGlobalSearchViewModel {
    var dataSource: FTGlobalSearchDataSource!
    var snapshot = FTGlobalSearchSnapShot()
    
    var applySnapshotClosure: (() -> Void)?
    var onSectionFinding: ((_ items: [FTSearchSectionProtocol]) -> Void)?
    var onCompletion: ((_ token: String) -> ())?
    var onProgressUpdate: ((_ progress: CGFloat) -> Void)?

    private(set) var searchedSections: [FTSearchSectionProtocol] = []
    private var searchHelper: FTGlobalSearchProvider?

    init() {
        self.searchHelper = FTGlobalSearchProvider(with: [FTGlobalSearchType.titles, FTGlobalSearchType.content, FTGlobalSearchType.tags])
    }

    func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }
        self.snapshot.deleteAllItems()

        if searchedSections.isEmpty {
            let type = FTGlobalSearchResultType.noResults
            self.snapshot.appendSections([type])
            self.snapshot.appendItems([], toSection: type)
            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            self.applySnapshotClosure?()
            return
        }
        if let sections = self.searchedSections as? [AnyHashable] {
            let type = FTGlobalSearchResultType.results
            self.snapshot.appendSections([type])
            self.snapshot.appendItems(sections, toSection: type)
            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            self.applySnapshotClosure?()
        }
    }

    func cancelSearch() {
        self.searchedSections.removeAll()
        self.createAndApplySnapshot()
        self.searchHelper?.cancelSearching()
    }

    func searchForNotebooks(with info: FTSearchInputInfo, in categories: [FTShelfItemCollection], onCurrentSectionFinding: ((_ section: FTSearchSectionProtocol, _ index: Int) -> Void)?, onCompletion: ((_ token: String) -> ())?) {
        let reqSearchKey = info.textKey.trimmingCharacters(in: .whitespaces)
        self.searchHelper?.fetchSearchResults(with: reqSearchKey, tags: info.tags, shelfCategories: categories, onSectionFinding: {[weak self] (items) in
            guard let self = self, !items.isEmpty else {
                return
            }
            items.forEach { itemSection in
                if !self.searchedSections.contains(where: { section in
                    return itemSection.uuid == section.uuid
                }) {
                    var sectionIndexSet = IndexSet()
                    for i in 0 ..< items.count {
                        sectionIndexSet.insert(self.searchedSections.count + i)
                    }
                    self.searchedSections.append(contentsOf: items)
                } else {
                    if let index = self.searchedSections.firstIndex(where: { section in
                        section.uuid == itemSection.uuid
                    }) {
                        onCurrentSectionFinding?(itemSection)
                    }
                }
            }
        }, onCompletion: onCompletion)

        self.searchHelper?.onProgressUpdate = {[weak self] (progress) in
            self?.onProgressUpdate?(progress)
        }
    }
}
