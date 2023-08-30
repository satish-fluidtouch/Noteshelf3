//
//  FTCloudBackupIgnoreList.swift
//  Noteshelf
//
//  Created by Amar on 27/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc enum FTBackupIgnoreType : Int {
    case none
    case sizeLimit
    case fileNotAvailable
    case packageNotAvailable
    case zipFail
    case packageNeedsUpgrade
    case invalidInput
    case temporaryByPass
    case passwordEnabled
}

extension FTCloudBackupIgnoreList {
    static let changeList = Notification.Name(rawValue: "FTCloudBackupDidChangeIgnoreList");
}
@objcMembers class FTBackupIgnoreEntry : NSObject
{
    var title : String?;
    var uuid : String!;
    var ignoreType = FTBackupIgnoreType.none;
    var ignoreReason : String = "";
    var hideFromUser = false;
}

@objcMembers class FTCloudBackupIgnoreList : NSObject
{
    fileprivate var ignoreItemsList = [FTBackupIgnoreEntry]();
    
    func addToIgnoreList(_ ignoreEntry : FTBackupIgnoreEntry)
    {
        self.ignoreItemsList.append(ignoreEntry);
        NotificationCenter.default.post(name: FTCloudBackupIgnoreList.changeList, object: nil);
    }
    
    func remove(fromIgnoreList shelfItemUUID : String)
    {
        let filteredItems = self.ignoreItemsList.filter({ (ignoreEntry) -> Bool in
            if let uuid = ignoreEntry.uuid, uuid == shelfItemUUID {
                return true;
            }
            return false;
        });
        
        if filteredItems.count > 0
            , let item = filteredItems.first
            ,let index = self.ignoreItemsList.firstIndex(of: item) {
            self.ignoreItemsList.remove(at: index);
            NotificationCenter.default.post(name: FTCloudBackupIgnoreList.changeList, object: nil);
        }
    }
    
    func ignoreItems() -> [FTBackupIgnoreEntry]
    {
        return self.ignoreItemsList;
    }
    func clearIgnoreList()
    {
        self.ignoreItemsList.removeAll();
        NotificationCenter.default.post(name: FTCloudBackupIgnoreList.changeList, object: nil);
    }
    
    func ignoreListIds() -> [String]
    {
        var lists = [String]();
        for eachItem in self.ignoreItemsList {
            let uuid = eachItem.uuid;
            if(nil != uuid) {
                lists.append(uuid!);
            }
        }
        return lists;
    }
    
    func isBackupIgnored(forShelfItemWithUUID uuid: String) -> Bool {
        return self.ignoreItemsList.contains{$0.uuid == uuid};
    }
    
    func ignoredItemsForUIDisplay() -> [FTBackupIgnoreEntry]
    {
        let items = self.ignoreItemsList.filter({ (eachEntry) -> Bool in
            return !eachEntry.hideFromUser;
        });
        
        return items;
    }
}
