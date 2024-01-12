//
//  FTSidebarSectionUserShelfs.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionUserShelfs: FTSidebarSection {
    override var type: FTSidebarSectionType {
        get {return .categories}
        set {}
    }
    
    override var supportsRearrangeOfItems: Bool {
        get { return true}
        set {}
    }
    
    init() {
        super.init(type: .all, items: [], supportsRearrangeOfItems: false);
        self.prepreItems();
        NotificationCenter.default.addObserver(self, selector: #selector(self.categoryDidUpdate(_:)), name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .categoryItemsDidUpdateNotification, object: nil)
    }
    
}

private extension FTSidebarSectionUserShelfs {
    private func prepreItems() {
        userCreatedSidebarItems { [weak self] sidebarItems in
            guard let self = self else { return }
            runInMainThread { [weak self] in
                self?.items = sidebarItems;
            }
        }
    }
    
    private func userCreatedSidebarItems(onCompeltion : @escaping([FTSideBarItem]) -> Void) {
        var currentItems = Array(self.items);
        FTNoteshelfDocumentProvider.shared.fetchAllCollections { collections in
            DispatchQueue.global().async {
                var sidebarItems = [FTSideBarItem]();
                collections.forEach { eachCollection in
                    guard !eachCollection.isUnfiledNotesShelfItemCollection else {
                        return;
                    }
                    if let item = currentItems.first(where: {$0.id == eachCollection.uuid}) {
                        sidebarItems.append(item);
                        if item.title != eachCollection.title {
                            item.title = eachCollection.title
                        }
                    }
                    else {
                        let item = FTSideBarItem(shelfCollection: eachCollection);
                        sidebarItems.append(item);
                    }
                }
                let itemsToSet = sidebarItems;//self.sortCategoriesBasedOnStoredPlistOrder(sidebarItems,performURLResolving: true)
                onCompeltion(itemsToSet);
            }
        }
    }

    @objc func categoryDidUpdate(_ notification : Notification) {
        self.prepreItems()
    }
}
