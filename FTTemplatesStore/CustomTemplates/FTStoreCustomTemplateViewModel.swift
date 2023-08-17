//
//  FTCustomTemplateViewModel.swift
//  TempletesStore
//
//  Created by Siva on 21/03/23.
//

import Foundation
import PDFKit
import UIKit

let pdfThumnailSize = CGSize(width: 228.0, height: 304.0)

enum FTStoreCustomType: Int {
    case templates = 0
    case noRecords = 1
}

internal typealias StoreCustomDatasource = UICollectionViewDiffableDataSource<FTStoreCustomType, AnyHashable>
internal typealias StoreCustomSnapshot = NSDiffableDataSourceSnapshot<FTStoreCustomType, AnyHashable>

class FTStoreCustomTemplateViewModel {
    var dataSource: StoreCustomDatasource!
    var snapshot = StoreCustomSnapshot()
    private let handler = FTStoreCustomTemplatesHandler.shared
    private var templates: [FTTemplateStyle] = []

    func loadTemplates() {
        if let customTemplates = try? handler.templates() {
            templates = customTemplates
            createAndApplySnapshot()
        }
    }
}

extension FTStoreCustomTemplateViewModel {
    func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }

        self.snapshot.deleteAllItems()
        if templates.isEmpty {
            let type = FTStoreCustomType.noRecords
            self.snapshot.appendSections([type])
            self.snapshot.appendItems([type], toSection: type)

            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            return
        }
        let type = FTStoreCustomType.templates
        self.snapshot.appendSections([type])
        self.snapshot.appendItems(templates, toSection: type)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
    }

    func items() -> [FTTemplateStyle] {
        return templates
    }
    
    func itemAt(index: Int) -> FTTemplateStyle? {
        if !templates.isEmpty {
            return templates[index]
        }
        return nil
    }

    func templatesCount() -> Int {
        return templates.count
    }

}
