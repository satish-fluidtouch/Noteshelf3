//
//  FTShelfItemCollectionAll.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 08/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTShelfItemCollectionAll: NSObject, FTShelfItemCollection, FTShelfItemSorting {    
    var URL: URL
    var uuid: String = FTUtils.getUUID();
    var type: RKShelfItemType = RKShelfItemType.shelfCollection;

    var childrens: [FTShelfItemProtocol] = []
    
    var collectionType : FTShelfItemCollectionType {
        return .allNotes;
    };
    var displayTitle: String {
        return NSLocalizedString("AllNotes", comment: "All Notes")
    }
    required init(fileURL: URL) {
        URL = fileURL;
    }
    var collectionError: NSError {
        return NSError.init(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey : "Error"])
    }
    func shelfItems(_ sortOrder: FTShelfSortOrder, parent: FTGroupItemProtocol?, searchKey: String?, onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void)) {
        let options = FTFetchShelfItemOptions()
        FTNoteshelfDocumentProvider.shared.fetchAllShelfItems(option:options) {[weak self] (shelfItems) -> (Void) in
            guard let `self` = self else {
                completionBlock([])
                return
            }
            self.childrens = self.sortItems(shelfItems, sortOrder: sortOrder)
            completionBlock(self.childrens)
        }
    }
    
    func renameShelfItem(_ shelfItem: FTShelfItemProtocol, toTitle: String, onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        if shelfItem.shelfCollection == nil {
            FTCLSLog("AllNotesCollection - shelfCollection Error")
            block(self.collectionError, nil)
            return
        }
        shelfItem.shelfCollection.renameShelfItem(shelfItem, toTitle: toTitle, onCompletion: block)
    }
    
    func removeShelfItem(_ shelfItem: FTShelfItemProtocol, onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        if shelfItem.shelfCollection == nil {
            FTCLSLog("AllNotesCollection - shelfCollection Error")
            block(self.collectionError, nil)
            return
        }
        shelfItem.shelfCollection.removeShelfItem(shelfItem, onCompletion: block)
    }
    
    func addShelfItemForDocument(_ path: URL, toTitle: String, toGroup: FTGroupItemProtocol?, onCompletion block: @escaping (NSError?, FTDocumentItemProtocol?) -> Void) {
        
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { (unfiledShelf) in
           unfiledShelf?.addShelfItemForDocument(path, toTitle: toTitle, toGroup: toGroup, onCompletion: block)
        }
    }
    func createGroupItem(_ groupName: String, inGroup: FTGroupItemProtocol?, shelfItemsToGroup items: [FTShelfItemProtocol]?, onCompletion block: @escaping (NSError?, FTGroupItemProtocol?) -> Void) {
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { (unfiledShelf) in
           unfiledShelf?.createGroupItem(groupName, inGroup: inGroup, shelfItemsToGroup: items, onCompletion: block)
        }
    }
    func moveShelfItems(_ shelfItems: [FTShelfItemProtocol], toGroup: FTShelfItemProtocol?, toCollection: FTShelfItemCollection!, onCompletion block: @escaping (NSError?, [FTShelfItemProtocol]) -> Void) {
        FTNoteshelfDocumentProvider.shared.uncategorizedNotesCollection { (unfiledShelf) in
           unfiledShelf?.moveShelfItems(shelfItems, toGroup: toGroup, toCollection: unfiledShelf, onCompletion: block)
        }
    }

    func isNS2Collection() -> Bool {
        return false
    }
}
extension FTShelfItemCollectionAll {
    func canPerformDrop() -> Bool {
        return false
    }
}
