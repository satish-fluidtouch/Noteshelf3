//
//  FTNoteshelfDocumentProvider_AllShelfItems.swift
//  Noteshelf
//
//  Created by Amar on 31/05/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

// TODO: (NS3) change this configurable struct
class FTFetchShelfItemOptions : NSObject
{
    var includeMigratedCategory : Bool = true;
    var sortOrder : FTShelfSortOrder = FTShelfSortOrder.none;
    var includesGroupItems : Bool = false
}

extension FTNoteshelfDocumentProvider : FTShelfItemSorting {
    func shelfBooksAndCategoryCount(option : FTFetchShelfItemOptions,
        onCompletion : @escaping ((CGFloat, CGFloat) -> (Void))) {
        self.fetchAllCollections { (shelfItemCollections) in
            let categories = shelfItemCollections.filter { !$0.isUnfiledNotesShelfItemCollection }
            self.fetchAllShelfItems(option: option) { shelfItems in
                onCompletion(CGFloat(shelfItems.count), CGFloat(categories.count))
            }
        }
    }
    
    @available(*, renamed: "fetchAllShelfItems(option:)")
    func fetchAllShelfItems(option : FTFetchShelfItemOptions,
                            onCompletion : @escaping (([FTShelfItemProtocol]) -> (Void))) {
        self.fetchAllCollections(includeUnCategorized: true) { (shelfItemCollections) in
            self.fetchShelfItems(forCollections: shelfItemCollections,
                                 option: option,
                                 parent : nil,
                                 onCompletion: onCompletion)
        };
    }

    func fetchAllShelfItems(option : FTFetchShelfItemOptions) async -> [FTShelfItemProtocol] {
        return await withCheckedContinuation { continuation in
            fetchAllShelfItems(option: option) { result in
                continuation.resume(returning: result)
            }
        }
    }

    
    @available(*, renamed: "fetchShelfItems(forCollections:option:fetchedShelfItems:)")
    func fetchShelfItems(forCollections shelfCollection: [FTShelfItemCollection],
                         option : FTFetchShelfItemOptions,
                         parent : FTGroupItemProtocol?,
                         fetchedShelfItems : [FTShelfItemProtocol]? = nil,
                         onCompletion : @escaping (([FTShelfItemProtocol]) -> (Void))) {
        var collections = shelfCollection;
        var localShelfItems = fetchedShelfItems ?? [FTShelfItemProtocol]();
        if let currentCollection = collections.first {
            collections.removeFirst();
            var fetchItems = false;
            switch currentCollection.collectionType {
            case .migrated:
                fetchItems = option.includeMigratedCategory;
            case .default,.system, .starred:
                fetchItems = true;
            default:
                break;
            }
            
            if(fetchItems) {
                currentCollection.shelfItems(FTShelfSortOrder.none,
                                             parent: parent,
                                             searchKey: nil,
                                             onCompletion: { (items) in
                    if option.includesGroupItems {
                        localShelfItems.append(contentsOf: items);
                    } else {
                        let _shelfItems = self.fetchOnlyNotebookItems(items: items);
                        localShelfItems.append(contentsOf: _shelfItems);
                    }
                    self.fetchShelfItems(forCollections: collections,
                                         option: option,
                                         parent:parent,
                                         fetchedShelfItems: localShelfItems,
                                         onCompletion: onCompletion);
                });
            }
            else {
                self.fetchShelfItems(forCollections: collections,
                                     option: option,
                                     parent:parent,
                                     fetchedShelfItems: localShelfItems,
                                     onCompletion: onCompletion);
            }
        }
        else {
            let items = self.sortItems(localShelfItems, sortOrder: option.sortOrder);
            onCompletion(items);
        }
    }

    private func fetchOnlyNotebookItems(items : [FTShelfItemProtocol]) -> [FTShelfItemProtocol]
    {
        var onlyNoteBookItems: [FTShelfItemProtocol] = [FTShelfItemProtocol]()
        
        let foundSingleItems = items.filter({ (shelfItem) -> Bool in
            return  !(shelfItem is FTGroupItemProtocol)
        });
        
        onlyNoteBookItems.append(contentsOf: foundSingleItems)
        
        let foundGroupItems = items.filter({ (shelfItem) -> Bool in
            return  (shelfItem is FTGroupItemProtocol)
        });
        
        foundGroupItems.forEach { (groupItem) in
            if let group = groupItem as? FTGroupItemProtocol {
                onlyNoteBookItems.append(contentsOf: self.fetchOnlyNotebookItems(items: group.childrens))
            }
        }
        return onlyNoteBookItems
    }
    
    @available(*, renamed: "fetchAllCollections()")
    func fetchAllCollections(includeUnCategorized: Bool = false,onCompeltion : @escaping ([FTShelfItemCollection]) -> Void)
    {
        self.shelfs { (categories) in
            var allShelfCollections = [FTShelfItemCollection]();
            categories.forEach({ (category) in
                let filteredCategories: [FTShelfItemCollection]
                if includeUnCategorized {
                    filteredCategories = category.categories.filter({$0.collectionType == .default || $0.collectionType == .migrated})
                }else {
                    filteredCategories = category.categories.filter({($0.collectionType == .default || $0.collectionType == .migrated) && !$0.isUnfiledNotesShelfItemCollection })
                }
                allShelfCollections.append(contentsOf: filteredCategories);
            });
            onCompeltion(allShelfCollections);
        };
    }
    
#if !NS2_SIRI_APP && !NOTESHELF_ACTION
    func fetchSystemCollections(onCompeltion : @escaping ([FTShelfItemCollection]) -> Void)
    {
        self.shelfs { (categories) in
            var allShelfCollections = [FTShelfItemCollection]();
            categories.forEach({ (category) in
                let systemCategories = category.categories.filter({$0.collectionType == .system || $0.collectionType == .allNotes})
                allShelfCollections.append(contentsOf: systemCategories);
                if let unCategorized  = category.categories.filter({$0.collectionType == .default && $0.displayTitle == uncategorizedShefItemCollectionTitle }).first {
                    allShelfCollections.append(unCategorized)
                }
                // Adding favorites collection explicitly as it may not contain categories using above logic
                if let favoritesCollection = self.starredShelfItemCollection() {
                    allShelfCollections.append(favoritesCollection)
                }
            });
            onCompeltion(allShelfCollections);
        };
    }
    #endif
}

protocol DocumentProviderAsync {
    func fetchAllCollections(includingUnCategorized: Bool) async -> [FTShelfItemCollection]
    func fetchShelfItems(forCollections shelfCollection: [FTShelfItemCollection],
                         option : FTFetchShelfItemOptions,
                         parent : FTGroupItemProtocol?,
                         fetchedShelfItems : [FTShelfItemProtocol]?) async -> [FTShelfItemProtocol]
}

// MARK: Async version
#if !NS2_SIRI_APP && !NOTESHELF_ACTION
extension FTNoteshelfDocumentProvider: DocumentProviderAsync {
    func fetchAllCollections(includingUnCategorized: Bool = false) async -> [FTShelfItemCollection] {
        return await withCheckedContinuation { continuation in
            fetchAllCollections(includeUnCategorized:includingUnCategorized) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func fetchSystemCollections() async -> [FTShelfItemCollection] {
        return await withCheckedContinuation { continuation in
            fetchSystemCollections() { result in
                continuation.resume(returning: result)
            }
        }
    }

    func fetchShelfItems(forCollections shelfCollection: [FTShelfItemCollection],
                         option : FTFetchShelfItemOptions,
                         parent : FTGroupItemProtocol?,
                         fetchedShelfItems : [FTShelfItemProtocol]? = nil) async -> [FTShelfItemProtocol] {
        return await withCheckedContinuation { continuation in
            fetchShelfItems(forCollections: shelfCollection, option: option, parent: parent, fetchedShelfItems: fetchedShelfItems) { result in
                continuation.resume(returning: result)
            }
        }
    }
    func fetchRecentShelfItems(sortOrder: FTShelfSortOrder) async -> [FTShelfItemProtocol] {
        return await withCheckedContinuation { continuation in
            recentShelfItems(sortOrder, parent: nil, searchKey: nil) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
#endif
