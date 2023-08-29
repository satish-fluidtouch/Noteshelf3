//
//  FTSidebarViewModel + NS2.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 08/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTSidebarViewModel {
    func fetchNS2Categories(completion:  @escaping  (([FTSideBarItem]) -> Void)) {
        // used this macro to make this work in Simulators, as we will not be having the NS2 app installed while debugging.
#if !DEBUG
        guard FTDocumentMigration.supportsMigration() else {
            completion([])
            return
        }
#endif
        FTNoteshelfDocumentProvider.shared.ns2Shelfs { collections in
            let newlyCreatedSidebarItems = collections.map { shelfItem -> FTSideBarItem in
                let item = FTSideBarItem(shelfCollection: shelfItem)
                item.id = shelfItem.uuid
                item.isEditable = false
                item.allowsItemDropping = false
                item.type = .ns2Category
                return item
            }
            completion(newlyCreatedSidebarItems)
        }
    }
}
