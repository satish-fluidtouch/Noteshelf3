//
//  SideMenuDropDelegate.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 06/06/22.
//

import Foundation
import SwiftUI
import MobileCoreServices

struct SideBarDropDelegate: DropDelegate {
    @ObservedObject var viewModel: FTSidebarViewModel
    func performDrop(info: DropInfo) -> Bool {
        viewModel.highlightItem = nil
        viewModel.fadeDraggedSidebarItem = nil
        viewModel.currentDraggedSidebarItem = nil
        viewModel.finalizeHighlightOfAllItems()
        viewModel.dropDelegate?.endDragAndDropOperation()
        return true
    }
    func dropEntered(info: DropInfo) {
        if viewModel.currentSideBarDropItem?.type == .category { // fading only when drop is inside categories section
            viewModel.fadeDraggedSidebarItem = viewModel.currentDraggedSidebarItem
        }
    }
    func dropExited(info: DropInfo) {
        print("drop exited in side bar")
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
struct SideBarItemDropDelegate: DropDelegate {
@ObservedObject var viewModel: FTSidebarViewModel
   weak var droppedItem: FTSideBarItem?

    func performDrop(info: DropInfo) -> Bool {
        let items = info.itemProviders(for: [.data])
        for item in items {
            item.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, error in
                if let data = data {
                    if let shelfItemData = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                       let shelfItemPath = shelfItemData[shelfItemURLKey] as? String,
                       let collectionName = shelfItemData[collectionNameKey] as? String {
                       viewModel.moveDraggedShelfItemWithPath(shelfItemPath, collectionName:collectionName)
                    }
                }
            }
        }
        droppedItem?.highlighted = false
        viewModel.currentDraggedSidebarItem = nil
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let droppedItem {
            viewModel.currentSideBarDropItem = droppedItem
            guard let draggedItem = self.viewModel.currentDraggedSidebarItem else {
                return
            }
            if draggedItem != droppedItem, let activeReorderingSection = viewModel.activeReorderingSidebarSectionType {
                let sectionItems = viewModel.menuItems.first(where: {$0.type == activeReorderingSection})?.items
                if let from = sectionItems?.firstIndex(of: draggedItem),
                   let to = sectionItems?.firstIndex(of: droppedItem) {
                    withAnimation(.default) {
                        self.viewModel.moveItemInCategory(activeReorderingSection,fromOrder: from, toOrder: to > from ? to + 1 : to)
                    }
                }
            }
        }
    }

    func dropExited(info: DropInfo) {
        droppedItem?.highlighted = false
       viewModel.highlightItem = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard let droppedItem else {
            return nil
        }
        if viewModel.currentDraggedSidebarItem != nil, viewModel.activeReorderingSidebarSectionType == .categories { // Reordering
            if droppedItem.type != .category { // if drop item is not categories, we are putting back the dragged item in its last ordered position in order to avoid reorder empty space of dragged item.
                viewModel.fadeDraggedSidebarItem = nil
            }
            return DropProposal(operation: .move)
        }else if viewModel.currentDraggedSidebarItem == nil , droppedItem.allowsItemDropping { // drop from shelf on sidebar items
            droppedItem.highlighted = true
            viewModel.highlightItem = droppedItem
            return DropProposal(operation: .move)
        }
        return DropProposal(operation: .forbidden)
    }
}
