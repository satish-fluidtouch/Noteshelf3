//
//  FTStoreLibraryViewModel.swift
//  TempletesStore
//
//  Created by Siva on 16/03/23.
//

import Foundation
import UIKit

enum FTStoreLibraryType: Int {
    case libraries = 0
    case noRecords = 1
}

internal typealias StoreLibraryDatasource = UICollectionViewDiffableDataSource<FTStoreLibraryType, AnyHashable>
internal typealias StoreLibrarySnapshot = NSDiffableDataSourceSnapshot<FTStoreLibraryType, AnyHashable>

class FTStoreLibraryViewModel {
    private let libraryHandler = FTStoreLibraryHandler.shared
    private var libraryData: [FTTemplateStyle] = []
    var dataSource: StoreLibraryDatasource!
    var snapshot = StoreLibrarySnapshot()
    var applySnapshotClosure: (() -> Void)?

    func loadLibraryTemplates() {
        Task {
            let templates = try await libraryHandler.libraryTemplates()
            libraryData = templates
            createAndApplySnapshot()
        }
    }

    func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }

        self.snapshot.deleteAllItems()

        if libraryData.isEmpty {
            let type = FTStoreLibraryType.noRecords
            self.snapshot.appendSections([type])
            self.snapshot.appendItems([], toSection: type)
            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            self.applySnapshotClosure?()
            return
        }
        let type = FTStoreLibraryType.libraries
        self.snapshot.appendSections([type])
        self.snapshot.appendItems(libraryData, toSection: type)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
        self.applySnapshotClosure?()
    }

    func items() -> [FTTemplateStyle] {
        return libraryData
    }

    func itemAt(index: Int) -> FTTemplateStyle? {
        if !libraryData.isEmpty {
            return libraryData[index]
        }
        return nil
    }

    func templatesCount() -> Int {
        return libraryData.count
    }

}
