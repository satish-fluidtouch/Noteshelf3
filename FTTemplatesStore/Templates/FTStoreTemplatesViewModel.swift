//
//  FTStoreTemplatesViewModel.swift
//  TempletesStore
//
//  Created by Siva on 08/05/23.
//

import Foundation
import UIKit


class FTStoreTemplatesViewModel {
    var items: [DiscoveryItem] = []
    var dataSource: TemplatesDatasource!
    var snapshot = TemplatesSnapshot()

    func loadTemplates() {
        Task {
            createAndApplySnapshot()
        }
    }

    func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }

        self.snapshot.deleteAllItems()

        if items.isEmpty {
            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            return
        }
        self.snapshot.appendSections([0])
        self.snapshot.appendItems(items, toSection: 0)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
    }

    func sectionInfo(at section: Int) -> TemplateInfo? {
        let sectionType = self.snapshot.sectionIdentifiers[section]
        let sectionItem = self.snapshot.itemIdentifiers(inSection: sectionType).first
        return sectionItem
    }

    func itemInfo(at indexPath: IndexPath) -> TemplateInfo? {
        let sectionType = self.snapshot.sectionIdentifiers[indexPath.section]
        let sectionItems = self.snapshot.itemIdentifiers(inSection: sectionType)
        return sectionItems[indexPath.row]
    }

}
