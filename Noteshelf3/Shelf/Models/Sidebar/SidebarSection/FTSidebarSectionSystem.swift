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
        get {
            return .all;
        }
        set {
            
        }
    }
    
    override var supportsRearrangeOfItems: Bool {
        get {
            return false;
        }
        set {
            
        }
    }
    
    init() {
        super.init(type: .all, items: [], supportsRearrangeOfItems: false);
        self.prepreItems();
    }
    
    required init(type: FTSidebarSectionType, items: [FTSideBarItem], supportsRearrangeOfItems: Bool) {
        fatalError("init(type:items:supportsRearrangeOfItems:) has not been implemented")
    }
    
    func prepreItems() {
        
        let homeSidebarItem = FTSideBarItem(title: "sidebar.topSection.home",
                                            icon: FTIcon.allNotes,
                                            isEditable: true,
                                            type: .home)
        homeSidebarItem.setShelfCollection(FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection);

        // Favorites
        let favoritesSidebarItem = FTSideBarItem(title: "Starred",
                                                 icon: .favorites,
                                                 isEditable: true,
                                                 type: .starred,
                                                 allowsItemDropping: true)
        favoritesSidebarItem.setShelfCollection(FTNoteshelfDocumentProvider.shared.starredShelfItemCollection());

        //Uncategorized
        let unCategorizedSidebarItem = FTSideBarItem(title: "Unfiled",
                                                     icon: .unsorted,
                                                     isEditable: true,
                                                     type: .unCategorized,
                                                     allowsItemDropping: true)
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { collection in
            unCategorizedSidebarItem.setShelfCollection(collection)
        }
         //Templates
        let templatesSidebarItem = FTSideBarItem(title: "Templates",
                                                 icon: .templates,
                                                 isEditable: true,
                                                 type: .templates)
        //Trash
        let trashSidebarItem = FTSideBarItem(title: "Trash",
                                             icon: .trash,
                                             isEditable: true,
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
    
}
