//
//  FTCategoryTemplatesViewModel.swift
//  TempletesStore
//
//  Created by Siva on 21/02/23.
//

import UIKit
import FTCommon

internal typealias CategoryTemplatesDatasource = UITableViewDiffableDataSource<Int, DiscoveryItem>
internal typealias CategoryTemplatesSnapshot = NSDiffableDataSourceSnapshot<Int, DiscoveryItem>

class FTCategoryTemplatesViewModel {
    var datasource: CategoryTemplatesDatasource!
    var snapshot = CategoryTemplatesSnapshot()
    var categoryTemplate: TemplateInfo!

    func reloadTableView() {
        guard self.datasource != nil else { return }

        self.snapshot.deleteAllItems()

        if let packs = categoryTemplate.items, packs.isEmpty {
            self.datasource.apply(self.snapshot, animatingDifferences: true)
            return
        }
        if let discoveryitems = categoryTemplate.items {
            for(index, discoveryitem) in discoveryitems.enumerated() {
                self.snapshot.appendSections([index])
                self.snapshot.appendItems([discoveryitem], toSection: index)
            }
        }
        self.datasource.apply(self.snapshot, animatingDifferences: true)

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
    
    var headerTitle: String {
        return categoryTemplate.title
    }

    var headerSubTitle: String {
        return categoryTemplate.subTitle
    }

    var tags: [FTTagModel] {
        var tags = [FTTagModel]()
        if let packs = categoryTemplate.items {
            packs.forEach { pack in
                tags.append(FTTagModel(text: pack.title))
            }
        }
        return tags
    }

}
