//
//  FTSidebarVM+ItemContexualOperations.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension FTSidebarViewModel {
    func getContextualOptionsForSideBarType(_ type: FTSideBarItemType) -> [FTSidebarItemContextualOption] {
        var contextualOptions: [FTSidebarItemContextualOption] = []
        let openInNewWindowSupportedTypes: [FTSideBarItemType] = [.home,.templates,.media,.bookmark,.audio,.starred,.unCategorized,.category]
        let renameSupportedTypes: [FTSideBarItemType] = [.category,.tag]
        let deleteSupportedTypes: [FTSideBarItemType] = [.trash,.category,.tag]
        if openInNewWindowSupportedTypes.contains(type) {
            contextualOptions.append(.openInNewWindow)
        }
        if renameSupportedTypes.contains(type) {
            contextualOptions.append(type == .category ? .renameCategory : .renameTag)
        }
        if deleteSupportedTypes.contains(type) {
            if type == .trash {
                contextualOptions.append(.emptyTrash)
            } else {
                contextualOptions.append(type == .category ? .trashCategory : .deleteTag)
            }
        }
        return contextualOptions
    }
    func performContexualMenuOperation(_ option: FTSidebarItemContextualOption) {
        guard let item = sidebarItemContexualMenuVM.sideBarItem else {
            fatalError("longpressed sidebaritem missing")
        }
        self.currentDraggedSidebarItem = nil
        switch option {
        case .openInNewWindow:
            self.openSideBarItemInNewWindow(item)
        case .renameCategory,.renameTag:
            self.finalizeEditOfAllSections()
            item.isEditing = true
        case .trashCategory,.emptyTrash,.deleteTag:
            print("Shows individual confirmation alerts")
        }
    }
}
