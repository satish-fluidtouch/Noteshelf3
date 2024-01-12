//
//  FTSidebarSectionSystem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 12/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSidebarSectionSystem: FTSidebarSection {
    override var type: FTSidebarSectionType {
        get {return .all}
        set {}
    }
    
    override var supportsRearrangeOfItems: Bool {
        get {return false;}
        set {}
    }
    
    init() {
        super.init(type: .all, items: [], supportsRearrangeOfItems: false);
        self.prepreItems();
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeUnfiledCategoryLocation(_:)), name: .didChangeUnfiledCategoryLocation, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didChangeUnfiledCategoryLocation, object: nil)
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
}

private extension FTSidebarSectionSystem {
    func prepreItems() {
        
        let homeSidebarItem = FTSideBarItem(title: "sidebar.topSection.home",
                                            icon: FTIcon.allNotes,
                                            type: .home)
        homeSidebarItem.setShelfCollection(FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection);

        // Favorites
        let favoritesSidebarItem = FTSideBarItem(title: "Starred",
                                                 icon: .favorites,
                                                 type: .starred,
                                                 allowsItemDropping: true)
        favoritesSidebarItem.setShelfCollection(FTNoteshelfDocumentProvider.shared.starredShelfItemCollection());

        //Uncategorized
        let unCategorizedSidebarItem = FTSideBarItem(title: "Unfiled",
                                                     icon: .unsorted,
                                                     type: .unCategorized,
                                                     allowsItemDropping: true)
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { collection in
            unCategorizedSidebarItem.setShelfCollection(collection)
        }
         //Templates
        let templatesSidebarItem = FTSideBarItem(title: "Templates",
                                                 icon: .templates,
                                                 type: .templates)
        //Trash
        let trashSidebarItem = FTSideBarItem(title: "Trash",
                                             icon: .trash,
                                             type: .trash,
                                             allowsItemDropping: true)
        FTNoteshelfDocumentProvider.shared.trashShelfItemCollection { trashCollection in
            trashSidebarItem.setShelfCollection(trashCollection)
        }

        self.items =  [
            homeSidebarItem
            ,favoritesSidebarItem
            ,unCategorizedSidebarItem
            ,templatesSidebarItem
            ,trashSidebarItem
        ];
    }

    @objc func didChangeUnfiledCategoryLocation(_ notification : Notification) {
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { collection in
            if let item = self.items.first(where: {$0.type == .unCategorized}) {
                item.setShelfCollection(collection)
            }
        }
    }
}
