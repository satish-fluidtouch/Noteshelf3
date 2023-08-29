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
#if DEBUG
// Intentionally adding DEBUG condition here to break the build when we do not remove this variable in beta/release
private var FTSideBarItemCount = 0
#endif
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

    weak var shelfCollection: FTShelfItemCollection?

    var highlightColor: Color {
        if !self.isEditing && !self.highlighted {
            return Color.appColor(.sideBarSelectedTint)
        } else if self.allowsItemDropping && self.highlighted {
            return Color.appColor(.gray6)
        } else {
            return Color.clear
        }
    }

    @Published var numberOfChildren: Int = 0

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
        self.title = NSLocalizedString(shelfCollection.displayTitle, comment: "collection name")
        self.icon = FTIcon.folder
        self.isEditing = false
        self.type = .category
        self.allowsItemDropping = true
        self.shelfCollection = shelfCollection
        if let collection = self.shelfCollection {
            self.numberOfChildren = collection.childrens.count
        }
    }

    override init() {
        super.init()
        FTSideBarItemCount += 1
        self.addObserverForCollectionChildrenCount()
        print(">>>> FTSideBarItem INIT \(FTSideBarItemCount)")
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
    func addObserverForCollectionChildrenCount(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateChildrenCountIfRequired(_:)), name: NSNotification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil)
    }
    @objc func updateChildrenCountIfRequired(_ notification : Notification){
        if let userInfo = notification.userInfo {
            if let collectionName = userInfo["shelfCollectionTitle"] as? String, collectionName == shelfCollection?.displayTitle, let count = userInfo["shelfItemsCount"] as? Int , count != numberOfChildren {
                numberOfChildren = count
            }
        }
    }
    deinit {
        FTSideBarItemCount -= 1
        print(">>>> FTSideBarItem DEINIT \(FTSideBarItemCount)")

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: shelfCollectionItemsCountNotification), object: nil)
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
