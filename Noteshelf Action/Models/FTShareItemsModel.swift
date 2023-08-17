//
//  FTShareItemsModel.swift
//  Noteshelf Action
//
//  Created by Sameer on 16/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTShareItem: AnyObject {
    var id: String {get set}
    var title: String {get set}
    var itemType: FTShareItemType {get set}
    var collection: FTShelfItemCollection? {get set}
    var shelfItem: FTShelfItemProtocol? {get set}
    func fetchImage() -> UIImage?
}

class FTCategoryShareItem: FTShareItem {
    var collection: FTShelfItemCollection?
    var shelfItem: FTShelfItemProtocol?
    var id: String = ""
    var title: String  = ""
    var itemType: FTShareItemType = .category
    
    convenience init(id: String, title: String, type: FTShareItemType, collection: FTShelfItemCollection) {
        self.init()
        self.title = title
        self.id = id
        self.itemType = type
        self.collection = collection
    }
    
    func fetchImage() -> UIImage? {
        var image = "folder"
        if collection?.isUnfiledNotesShelfItemCollection ?? false {
            image = "tray"
        }
        return UIImage(systemName: image)?.withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 17))).withTintColor(.appColor(.accent))
    }

}

class FTShelfShareItem: FTCategoryShareItem {
    convenience init(id: String, title: String, type: FTShareItemType, shelfItem: FTShelfItemProtocol, collection: FTShelfItemCollection) {
        self.init()
        self.title = title
        self.id = id
        self.itemType = type
        self.shelfItem = shelfItem
        self.collection = collection
    }
}
