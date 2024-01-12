//
//  FTSideBarItem.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 09/05/22.
//

import Foundation
import FTStyles
import SwiftUI
import MobileCoreServices

class FTSideBarItem: NSObject, FTSideMenuEditable, Identifiable, ObservableObject {
    override var debugDescription: String {
        return title + "-" + (shelfCollection?.title ?? "")
    }
    var id: String = ""
    var title: String = ""

    var icon: FTIcon = .folder

    var isEditable: Bool = true

    var highlighted: Bool = false
    var allowsItemDropping: Bool = false

    @Published var isEditing: Bool = false

    var type: FTSideBarItemType = .home

    private(set) var shelfCollection: FTShelfItemCollection?

    var highlightColor: Color {
        if !self.isEditing && !self.highlighted {
            return Color.appColor(.sideBarSelectedTint)
        } else if self.allowsItemDropping && self.highlighted {
            return Color.appColor(.gray6)
        } else {
            return Color.clear
        }
    }

    func setShelfCollection(_ collection: FTShelfItemCollection?) {
        self.shelfCollection = collection;
    }
    
    convenience init(id: String = UUID().uuidString,title: String,
                     icon: FTIcon,
                     isEditable: Bool = true,
                     isEditing: Bool = false,
                     type: FTSideBarItemType,
                     allowsItemDropping: Bool = false) {
        self.init()
        self.title = title
        self.icon = icon
        self.isEditable = isEditable
        self.isEditing = isEditing
        self.type = type
        self.allowsItemDropping = allowsItemDropping
        self.id = id
    }

    convenience init(shelfCollection: FTShelfItemCollection) {
        self.init()
        self.title = shelfCollection.displayTitle
        self.icon = FTIcon.folder
        self.isEditing = false
        self.type = .category
        self.allowsItemDropping = true
        self.shelfCollection = shelfCollection
    }

    override init() {
        super.init()
    }
    func rename(newName: String) {
        self.title = newName
        self.isEditing = false
    }
//    override var hash: Int {
//        hash.combine(id)
//    }
    static func == (lhs: FTSideBarItem, rhs: FTSideBarItem) -> Bool {
        return lhs.title == rhs.title &&
        lhs.isEditable == rhs.isEditable &&
        lhs.isEditing == rhs.isEditing &&
        lhs.id == rhs.id
    }
}
extension FTSideBarItem: NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeData as String]
    }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        do {
            let dict = ["shelfItemCollectionPath": self.shelfCollection?.URL.path ?? ""] as [String : Any];
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                              format: .xml,
                                                              options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
