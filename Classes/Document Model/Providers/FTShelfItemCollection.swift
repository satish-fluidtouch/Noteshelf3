//
//  FTShelfItemCollection.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum FTShelfItemCollectionType: Int {
    case recent
    case `default`
    case system
    case migrated
    case starred
    case allNotes
}

protocol FTShelfItemDocumentStatusChangePublisher: NSObjectProtocol {
    var downloadStatusChangedItems: FTHashTable { get set };
    var timer: Timer? { get set };

    func documentItem(_ item: FTShelfItemProtocol, didChangeDownloadStatus status: Bool); //private method used to indicate the document uuid is read and can batch the post as updated
}
protocol FTDroppable: NSObjectProtocol {
    func canPerformDrop() -> Bool
}
protocol FTShelfItemCollection: FTDiskItemProtocol, FTDroppable {

    //shelf collection attributes
    var childrens: [FTShelfItemProtocol] { get set };
    var collectionType: FTShelfItemCollectionType { get };

    func addChild(_ childItem: FTShelfItemProtocol);
    func removeChild(_ childItem: FTShelfItemProtocol);

    func shelfItems(_ sortOrder: FTShelfSortOrder,
                    parent: FTGroupItemProtocol?,
                    searchKey: String?,
                    onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void));

    func addShelfItemForDocument(_ path: Foundation.URL,
                                 toTitle: String,
                                 toGroup: FTGroupItemProtocol?,
                                 onCompletion block: @escaping (NSError?, FTDocumentItemProtocol?) -> Void);

    /*
    @param  shelfItem       can be either group or document item
    @param  toGroup         should be nil if shelf item is group. otherwise can be nil or be of type groupitem
    @param  toCollection    collection to which it has to be moved
    @param  block           completion block called after the action is done
     */
    func moveShelfItems(_ shelfItems: [FTShelfItemProtocol],
                       toGroup: FTShelfItemProtocol?,
                       toCollection: FTShelfItemCollection!,
                       onCompletion block: @escaping (NSError?, [FTShelfItemProtocol]) -> Void);

    /*
     @param shelfItem   can be either group or document item
     @param toTitle     title to be set
     @param block       completion block called after the action is done
     */
    func renameShelfItem(_ shelfItem: FTShelfItemProtocol,
                         toTitle: String,
                         onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void);

    /*
     @param shelfItem   can be either group or document item. will be deleted permanently
     @param block       completion block called after the action is done
     */
    func removeShelfItem(_ shelfItem: FTShelfItemProtocol,
                         onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void);

    //group operations
    func createGroupItem(_ groupName: String,
                         inGroup: FTGroupItemProtocol?,
                         shelfItemsToGroup items: [FTShelfItemProtocol]?,
                         onCompletion block: @escaping (NSError?, FTGroupItemProtocol?) -> Void);
    func removeGroupItem(_ groupItem: FTGroupItemProtocol,
                                onCompletion block:@escaping (NSError?, FTGroupItemProtocol?) -> Void)

    // For NS3 Migration
    func isNS2Collection() -> Bool
}

extension FTShelfItemCollection {
    var collectionType: FTShelfItemCollectionType {
        return FTShelfItemCollectionType.default;
    }

    func addChild(_ childItem: FTShelfItemProtocol) {
        self.childrens.append(childItem);
        childItem.parent = nil;
        childItem.shelfCollection = self;
        if let groupitem = childItem as? FTGroupItemProtocol {
            for eachItem in groupitem.childrens {
                eachItem.parent = groupitem;
                eachItem.shelfCollection = self;
            }
        }
    }

    func removeChild(_ childItem: FTShelfItemProtocol) {
        let index = self.childrens.index { eachItem -> Bool in
            if(eachItem.URL == childItem.URL) {
                return true;
            }
            return false;
        }

        if let _index = index {
            if let groupitem = childItem as? FTGroupItemProtocol {
                for eachItem in groupitem.childrens {
                    eachItem.parent = nil;
                    eachItem.shelfCollection = nil;
                }
            }
            childItem.parent = nil;
            childItem.shelfCollection = nil;
            self.childrens.remove(at: _index);
        }
    }
}

extension FTShelfItemCollection //for searching
{
    func groupItemWithName(title: String) -> FTGroupItemProtocol? {
        var group: FTGroupItemProtocol?;
        let titleToSearch = title.deletingPathExtension;

        let items = self.childrens;
        for eachItem in items {
            if((eachItem.URL.pathExtension == FTFileExtension.group) && (eachItem.title == titleToSearch)) {
                group = eachItem as? FTGroupItemProtocol;
                break;
            }
        }
        return group;
    }

    func groupItemForURL(_ fileURL: Foundation.URL) -> FTGroupItemProtocol? {
        if let first = fileURL.pathRelativeTo(self.URL).components(separatedBy: "/").first,
           let item = self.groupItemWithName(title: first) {
            if item.URL.urlByDeleteingPrivate() == fileURL.urlByDeleteingPrivate() {
                return item;
            }
            return (item as? FTGroupItem)?.groupItemForURL(fileURL);
        }
        return nil;
    }
        
    func documentItemWithName(title: String, inGroup group: FTGroupItemProtocol?) -> FTShelfItemProtocol? {
        var itemToReturn: FTShelfItemProtocol?;
        let titleToSearch = title.deletingPathExtension;

        var items = self.childrens;
        if(nil != group) {
            items = group!.childrens;
        }

        for eachItem in items where eachItem.type != RKShelfItemType.group && eachItem.title == titleToSearch {
            itemToReturn = eachItem;
            break;
        }
        return itemToReturn;
    }

    var isTrash: Bool {
        return (self.collectionType == .system && (self.URL == FTShelfCollectionSystem.TrashCollectionURL()))
    }
    
    var isAllNotesShelfItemCollection: Bool {
        return self.collectionType == .allNotes
    }
    
    var isUnfiledNotesShelfItemCollection: Bool {
        return self.URL.deletingPathExtension().lastPathComponent == uncategorizedShefItemCollectionTitle
    }
    var isStarred: Bool {
        return self.collectionType == .starred
    }
    var isRecent: Bool {
        self.collectionType == .recent
    }
    var displayTitle: String {
        if self.isTrash {
            return NSLocalizedString(self.title, comment: self.title);
        } else if self.isStarred {
            return NSLocalizedString("sidebar.topSection.starred", comment: self.title);
        }
        else if self.title == uncategorizedShefItemCollectionTitle {
            let localisationKey = isNS2Collection() ? "Uncategorized" : "sidebar.topSection.unfiled"
            let comment = isNS2Collection() ? "Uncategorized" : "Unfiled"
            return NSLocalizedString(localisationKey, comment: comment);
        }
        return self.title;
    }

    var isMigratedCollection: Bool {
        return (self.collectionType == .migrated);
    }
    var isDefaultCollection: Bool {
        return (self.collectionType == .default);
    }
}

extension FTShelfItemCollection {
    func addShelfItemForDocument(_ path: Foundation.URL,
                                 toTitle: String,
                                 toGroup: FTGroupItemProtocol?,
                                 onCompletion block: @escaping (NSError?, FTDocumentItemProtocol?) -> Void) {
        assert(false, "addShelfItemForDocument:toTitle:toGroup:onCompletion: is not supported by default")
    }

    func moveShelfItems(_ shelfItems: [FTShelfItemProtocol],
                       toGroup: FTShelfItemProtocol?,
                       toCollection: FTShelfItemCollection!,
                       onCompletion block: @escaping (NSError?, [FTShelfItemProtocol]) -> Void) {
        assert(false, "moveShelfItem:toGroup:toCollection:onCompletion: is not supported by default")
    }

    func renameShelfItem(_ shelfItem: FTShelfItemProtocol,
                         toTitle: String,
                         onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        assert(false, "moveShelfItem:toTitle:onCompletion is not supported by default")
    }

    func removeShelfItem(_ shelfItem: FTShelfItemProtocol,
                         onCompletion block: @escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        assert(false, "removeShelfItem:onCompletion: is not supported by default")
    }

    //group operations
    func createGroupItem(_ groupName: String,
                         inGroup: FTGroupItemProtocol?,
                         shelfItemsToGroup items: [FTShelfItemProtocol]?,
                         onCompletion block: @escaping (NSError?, FTGroupItemProtocol?) -> Void) {
        assert(false, "createGroupItem:shelfItemsToGroup:onCompletion: is not supported by default")
    }
    
    internal func moveDocumentItems(items : [FTShelfItemProtocol],
                           toCollection: FTShelfItemCollection,
                           toGroup : FTGroupItemProtocol?,
                           onCompletion :  @escaping (NSError?)->())
    {
        var shelfItems = items;
        let eachitem = shelfItems.first;
        if(eachitem == nil) {
            onCompletion(nil);
        }
        else {
            shelfItems.removeFirst();
            eachitem!.shelfCollection.moveShelfItems([eachitem!],
                                                    toGroup: toGroup,
                                                    toCollection: toCollection,
                                                    onCompletion: { error, _ in
                                                        if(nil != error) {
                                                            onCompletion(error);
                                                        } else {
                                                            self.moveDocumentItems(items: shelfItems,
                                                                                  toCollection: toCollection,
                                                                                  toGroup: toGroup,
                                                                                  onCompletion: onCompletion);
                                                        }
            })
        }
    }
}

extension FTShelfItemDocumentStatusChangePublisher {
    func documentItem(_ item: FTShelfItemProtocol, didChangeDownloadStatus status: Bool) {
        runInMainThread {
            self.downloadStatusChangedItems.addItemToHashTable(item, forKey: item.URL);

            if(item.parent != nil) {
                self.downloadStatusChangedItems.addItemToHashTable(item.parent!, forKey: item.parent!.URL);
            }

            if(nil == self.timer) {
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [weak self] scheduled in
                    if let selfObject = self, let items = selfObject.downloadStatusChangedItems.allItems() as? [FTShelfItemProtocol] {
                        if !items.isEmpty {
                            NotificationCenter.default.post(name: Notification.Name.shelfItemUpdated, object: selfObject, userInfo: [FTShelfItemsKey: items]);
                        }
                    }
                    self?.downloadStatusChangedItems.removeAll();
                    self?.timer?.invalidate();
                    self?.timer = nil;
                });
            }
        }
    }
}

extension FTShelfItemCollection {
    func canPerformDrop() -> Bool {
        return true
    }
}
