//
//  FTStoreSectionHandler.swift
//  TempletesStore
//
//  Created by Siva on 22/02/23.
//

import Foundation
import Combine
import UIKit

protocol FTStoreSectionHandler {
    init(actionStream: PassthroughSubject<FTStoreActions, Never>)
    func tableView(_ cellModel: StoreInfo,
                   _ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
}

class StoreSectionContainer {
    var sectionHandlers: [Int: FTStoreSectionHandler] = [:]
    init(handlers: [FTStoreSectionHandler]) {
        for(index, handler) in handlers.enumerated() {
            sectionHandlers[index] = handler
        }
    }

    func tableView(_ cellModel: StoreInfo,
                   _ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionHandler = sectionHandlers[indexPath.section] else { return UITableViewCell() }
        return sectionHandler.tableView(cellModel, tableView, cellForRowAt: indexPath)
    }

}

class BannerSectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let plannerCell = tableView.dequeueReusableCell(withIdentifier: FTStoreBannerTableCell.reuseIdentifier) as? FTStoreBannerTableCell else { return UITableViewCell() }
        plannerCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return plannerCell
    }
}

class CategorySectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let categoryCell = tableView.dequeueReusableCell(withIdentifier: FTStoreCategoryTableCell.reuseIdentifier) as? FTStoreCategoryTableCell else { return UITableViewCell() }
        categoryCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return categoryCell
    }
}

class TemplatesSectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let plannerCell = tableView.dequeueReusableCell(withIdentifier: FTStorePlannerTableCell.reuseIdentifier) as? FTStorePlannerTableCell else { return UITableViewCell() }
        plannerCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return plannerCell
    }
}

class StickersSectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let stickersCell = tableView.dequeueReusableCell(withIdentifier: FTStoreStickersTableCell.reuseIdentifier) as? FTStoreStickersTableCell else { return UITableViewCell() }
        stickersCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return stickersCell
    }
}

class JournalSectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let journalCell = tableView.dequeueReusableCell(withIdentifier: FTStoreJournalTableCell.reuseIdentifier) as? FTStoreJournalTableCell else { return UITableViewCell() }
        journalCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return journalCell
    }
}


class CategoryPlannerSectionHandler: FTStoreSectionHandler {
    private let actionStream: PassthroughSubject<FTStoreActions, Never>
    required init(actionStream: PassthroughSubject<FTStoreActions, Never>) {
        self.actionStream = actionStream
    }

    func tableView(_ cellModel: StoreInfo, _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let plannerCell = tableView.dequeueReusableCell(withIdentifier: FTStorePlannerTableCell.reuseIdentifier) as? FTStorePlannerTableCell else { return UITableViewCell() }
        plannerCell.prepareCellWith(templatesStoreInfo: cellModel, actionStream: actionStream)
        return plannerCell
    }
}
