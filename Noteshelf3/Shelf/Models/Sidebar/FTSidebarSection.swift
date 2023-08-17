//
//  FTSidebarSection.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 09/05/22.
//

import Foundation
class FTSidebarSection: FTSectionDisplayable, FTSideMenuDeletable, Identifiable, ObservableObject {

    var type: FTSidebarSectionType

    var id = UUID().uuidString

    var title: String {
        type.displayTitle ?? ""
    }

    var canShowAddItem: Bool {
        type.showAddNewOption
    }

    var supportsRearrangeOfItems: Bool = false

    @Published var items: [FTSideBarItem] = []

    var isCreating: Bool = false

    var newItemIcon: FTIcon {
        type == .tags ? FTIcon.tags : FTIcon.folder
    }

    required init(type: FTSidebarSectionType, items: [FTSideBarItem],supportsRearrangeOfItems: Bool) {
        self.type = type
        self.items = items
        self.supportsRearrangeOfItems = supportsRearrangeOfItems
    }

    func addNewItemWith(title: String) {
        self.items.insert(FTSideBarItem(title: title,
                                        icon: newItemIcon,
                                        isEditable: true,
                                        isEditing: false,
                                        type: .category), at: 0)
    }
    func finaliseEdit() {
        for index in 0..<self.items.count {
            self.items[index].isEditing = false
        }
    }
    func finaliseHightlight() {
        for index in 0..<self.items.count {
            self.items[index].highlighted = false
        }
    }
//    func unSelectSectionItems() {
//        for index in 0..<self.items.count {
//            self.items[index].isSelected = false
//        }
//    }
    func moveItemToTrash(_ item: FTSideBarItem) {
        if type == .categories || type == .tags {
            self.items.removeAll(where: { $0.id == item.id })
        }
    }
}
