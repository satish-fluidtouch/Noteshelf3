//
//  FTGrouping.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTGrouping: NSObject {
    var collection: FTShelfItemCollection
    var parentGroup: FTGroupItemProtocol?

    init(collection: FTShelfItemCollection, parentGroup: FTGroupItemProtocol? = nil) {
        self.collection = collection
        self.parentGroup = parentGroup
    }
    func createGroup(name: String?,
                     items: [FTShelfItemProtocol],
                     onCompeltion:((NSError?,FTGroupItemProtocol?)->())?)
    {
        let groupName: String;
        let groupNameWithourTrailingScpaes = name?.trimmingCharacters(in: .whitespaces);
        if let inName = groupNameWithourTrailingScpaes, !inName.isEmpty {
            groupName = inName;
        }
        else {
            groupName = NSLocalizedString("Group", comment: "Group")
        }

        collection.createGroupItem(groupName,
                                        inGroup: parentGroup,
                                        shelfItemsToGroup: items)
        { [weak self] (error, groupItem) in
            if nil == error {
                self?.updatePublishedRecords(itmes: items,
                                             isDeleted: false,
                                             isMoved: true);
            }
            onCompeltion?(error,groupItem);
        }
    }
    func updatePublishedRecords(itmes movedItems: [FTShelfItemProtocol],
                                isDeleted: Bool = false,
                                isMoved: Bool = false)
    {
        movedItems.forEach { (movedItem) in
            guard let documentItem = movedItem as? FTDocumentItemProtocol,
                let documentUUID = documentItem.documentUUID else {
                    return;
            }

            let autobackupItem = FTAutoBackupItem(URL: documentItem.URL,
                                                  documentUUID: documentUUID);
            if(isDeleted) {
                FTSiriShortcutManager.shared.removeShortcutSuggestionForUUID(documentUUID)
                FTShortcutStorage.removeShortcutDataForUUID((documentUUID))

                FTCloudBackUpManager.shared.shelfItemDidGetDeleted(autobackupItem);
            }
            else {
                FTCloudBackUpManager.shared.startPublish();
            }

            let evernotePublishManager = FTENPublishManager.shared;
            if evernotePublishManager.isSyncEnabled(forDocumentItem: documentItem) {
                if(isDeleted) {
                    FTENPublishManager.recordSyncLog("User deleted notebook: \(String(describing: documentUUID))");
                    evernotePublishManager.disableSync(for: documentItem);
                    evernotePublishManager.disableBackupForShelfItem(withUUID: documentUUID);
                }
                else {
                    evernotePublishManager.updateSyncRecord(forShelfItem: documentItem,
                                                            withDocumentUUID: documentUUID)
                }
            }
        }
    }
    func move(_ shelfItems: [FTShelfItemProtocol],completion: @escaping (NSError?, [FTShelfItemProtocol]) -> Void) {
        guard let item = shelfItems.first else {
            completion(nil,[])
            return
        }
        item.shelfCollection.moveShelfItems(shelfItems,
                                            toGroup: parentGroup,
                                            toCollection: collection,
                                            onCompletion:
            {[weak self] (error, movedItems) in
                if nil == error {
                    self?.updatePublishedRecords(itmes: movedItems,
                                                 isDeleted: self?.collection.isTrash ?? false,
                                                 isMoved: true);
                }
            completion(error,movedItems)
        });
    }
}
