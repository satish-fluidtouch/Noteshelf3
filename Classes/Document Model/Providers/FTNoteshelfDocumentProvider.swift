//
//  FTNoteshelfDocumentProvider.swift
//  Noteshelf
//
//  Created by Amar on 17/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

let migratedShelfName = "Noteshelf 1 Data.shelf";
let FTSuccessfullyMigratedNS1Notification = "FTSuccessfullyMigratedNS1Notification";
let uncategorizedShefItemCollectionTitle = "Uncategorized"
let allNotesShefItemCollectionName = "AllNotes.shelf"
let favoritesTitle = "Starred"

enum FTShelfProviderMode: Int {
    case cloud
    case local
}

private var systemShelfCollection: FTShelfCollection!;

class FTNoteshelfDocumentProvider: NSObject {
    static let shared = FTNoteshelfDocumentProvider()

    private var cloudObserver : NSKeyValueObservation?
    fileprivate var providerMode: FTShelfProviderMode?
    fileprivate var categorizedShelfs: [FTShelfCategoryCollection] = [FTShelfCategoryCollection]()
    fileprivate var newcategorizedShelfs: [FTShelfCategoryCollection] = [FTShelfCategoryCollection]()
    //Shelf Related
    fileprivate var cloudShelfCollectionRoot: FTShelfCollectioniCloudRoot?;
    fileprivate var localShelfCollectionRoot: FTShelfCollectionLocalRoot?;

    fileprivate var recentShelfCollection: FTShelfCollection?;

    ///iCloud Metadata Listener
    fileprivate var cloudDocumentListener: FTCloudDocumentListener?;

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    fileprivate var cloudWatchRecordingCollection: FTWatchRecordingCollection?
    fileprivate var localWatchRecordingCollection: FTWatchRecordingCollection?
    lazy var allNotesShelfItemCollection = {
       return FTShelfItemCollectionAll.init(fileURL: URL.init(string: allNotesShefItemCollectionName)!)
    }()
    #endif
    var isProviderReady: Bool {
        return providerMode != nil
    }

    fileprivate var isContentMoving: Bool = false // set this to true when content is being moved from iCloud to local and vice versa.
    /// This needs to be called only on initialization and whenever the iCloud Settings are modified.
    func updateProviderIfRequired(_ onCompletion :((_ isUpdated: Bool) -> Void)?) {
        FTNoteshelfDocumentProvider.documentProvider { provider in
            if(self.providerMode == nil || self.providerMode != provider.providerMode) {
                if(nil != self.providerMode) {
                    self.resetProviderCache();
                }
                self.providerMode = provider.providerMode

                self.localShelfCollectionRoot = provider.localShelfCollectionRoot
                self.recentShelfCollection = provider.recentShelfCollection
                self.cloudShelfCollectionRoot = provider.cloudShelfCollectionRoot
                self.cloudDocumentListener = provider.cloudDocumentListener


                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                self.localWatchRecordingCollection = provider.localWatchRecordingCollection
                self.cloudWatchRecordingCollection = provider.cloudWatchRecordingCollection

                FTCloudBackUpManager.shared.rootDocumentsURL = provider.rootDocumentsURL()
                FTENPublishManager.shared.rootDocumentsURL = provider.rootDocumentsURL()
                FTTagsProvider.shared.rootDocumentsURL = provider.rootDocumentsURL();
                #endif
                onCompletion?(true);
            } else {
                onCompletion?(false);
            }
        }
    }
    override init() {
        super.init();
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        cloudObserver = FTUserDefaults.defaults().observe(\.iCloudOn,
                                                          options: [.new])
        { [weak self] (userdefaults, context) in
            self?.categorizedShelfs.removeAll();
        }
        #endif
    }
    
    func updateProviderForNoteShelfAction(_ onCompletion :((_ isUpdated: Bool) -> Void)?) {
        FTNSiCloudManager.shared().defaultUserDefaults = FTUserDefaults.defaults()
        if(FTUserDefaults.defaults().iCloudOn) {
            updateProviderIfRequired(onCompletion)
        } else {
            let documentProvider = FTNoteshelfDocumentProvider();
            documentProvider.prepareSystemDefaultCollections {
                self.localShelfCollectionRoot = FTShelfCollectionLocalRoot()
                self.providerMode = .local
                onCompletion?(true)
            }
        }
    }

    func resetProviderCache() {
        self.categorizedShelfs.removeAll();
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        FTRecentEntries.resetRecentEntries();
        #endif
    }
    
    func refreshCurrentShelfCollection(onCompletion : @escaping () -> Void) {
        self.currentCollection().refreshShelfCollection(onCompletion: onCompletion);
    }
    
    func generateDocumentsDirectoryLog() -> [String] {
        var url =  FTUtils.noteshelfDocumentsDirectory().appendingPathComponent("User Documents")
        if FTUserDefaults.defaults().iCloudOn, let iCloudUrl = FTNSiCloudManager.shared().iCloudRootURL() {
            url = iCloudUrl
        }
        let contents = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants, .producesRelativePathURLs])
        var relativePaths = [String]();
        contents?.enumerated().forEach({ eachItem in
            let item = eachItem.element;
            if let pathURL = (item as? URL)?.relativePath {
                relativePaths.append(pathURL);
            }
        })
        return relativePaths
    }

    fileprivate static func documentProvider(_ onCompletion : @escaping ((FTNoteshelfDocumentProvider) -> Void)) {
        FTCLSLog("Provider - Preparing Default Collections");
        let documentProvider = FTNoteshelfDocumentProvider();
        documentProvider.prepareSystemDefaultCollections {
                documentProvider.localShelfCollectionRoot = FTShelfCollectionLocalRoot()
                documentProvider.providerMode = .local;

                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                documentProvider.localWatchRecordingCollection = FTWatchRecordingCollection_Local()
                #endif
            FTCLSLog("Provider - Checking iCloud status");
                FTNSiCloudManager.shared().updateiCloudStatus(FTNSiCloudManager.iCloudContainerID.ns3, withCompletionHandler: { available in
                    FTCLSLog("Provider - Verified iCloud status \(available)");
                    // Early exit from the provider creation, when the cloud drive is off inside device settings and iCloud is still on inside the application.
                    if(FTNSiCloudManager.shared().iCloudOn() && FTNSiCloudManager.shared().iCloudRootURL() == nil) {
                        FTCLSLog("Provider - Cloud on but url nil");
                        onCompletion(documentProvider);
                        return
                    }

                    if available {
                        let rootCloudShelfCollection = FTShelfCollectioniCloudRoot()
                        let queryListener = FTCloudDocumentListener(rootURLs: FTNSiCloudManager.shared().cloudURLSToListen)
                        documentProvider.cloudDocumentListener = queryListener
                        if FTNSiCloudManager.shared().iCloudOn() {
                            documentProvider.providerMode = .cloud;
                        }

                        documentProvider.cloudShelfCollectionRoot = rootCloudShelfCollection
                        queryListener.addListener(rootCloudShelfCollection)

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                        if let cloudURL = FTNSiCloudManager.shared().iCloudRootURL() {
                            let cloudWatchCollection = FTWatchRecordingCollection_Cloud(cloudURL: cloudURL)
                            documentProvider.cloudWatchRecordingCollection = cloudWatchCollection

                            //Add Audio recordings Listener
                            if let audioListener = documentProvider.cloudWatchRecordingCollection as? FTMetadataCachingProtocol {
                                queryListener.addListener(audioListener)
                            }
                        }
#endif
                        onCompletion(documentProvider);
                    }
                    else {
                        onCompletion(documentProvider);
                    }
                })
        }
    }

    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
        self.cloudObserver?.invalidate();
        self.cloudObserver = nil;
    }

    func shelfs(_ completion : @escaping (([FTShelfCategoryCollection]) -> Void))
    {
        if categorizedShelfs.isEmpty {
            var categoryCollection = [FTShelfCategoryCollection]();
            self.userShelfCollections { (shelfs) in
                let providerSpecificCategoryCollection = FTShelfCategoryCollection(type: .user, categories: shelfs);
                categoryCollection.append(providerSpecificCategoryCollection);
                
                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                if let recentShelfCat = self.recentShelfCollection as? FTShelfCollectionRecent {
                    let favoritesShelfCollection = recentShelfCat.favoritesShelfItemCollection
                    let starredCategory = FTShelfCategoryCollectionRecent.init(name: NSLocalizedString("sidebar.topSection.starred", comment: "Starred"), type: .starred, categories: [favoritesShelfCollection]);
                    categoryCollection.append(starredCategory);
                }
                #endif
                self.categorizedShelfs = categoryCollection
                completion(categoryCollection);
                
            }
        }
        else {
            completion(categorizedShelfs)
        }
    }
    
    func categoryShelfs(_ completion : @escaping (([FTShelfCategoryCollection]) -> Void)) {
        var categoryCollection = [FTShelfCategoryCollection]();
        self.shelfs { (shelfs) in
            //First section: allnotes, favorites, unfiled
            var shelfItemCollection = [FTShelfItemCollection]();
            #if !NS2_SIRI_APP && !NOTESHELF_ACTION
            let allNotes = self.allNotesShelfItemCollection
            shelfItemCollection.append(allNotes)
            if let recentShelfCat = self.recentShelfCollection as? FTShelfCollectionRecent {
                    shelfItemCollection.append(recentShelfCat.favoritesShelfItemCollection)
            }
            #endif
            let userCollections = shelfs.filter {$0.type == .user}
            if !userCollections.isEmpty, let categoriesCollection = userCollections.first {
                if let uncategorizedCollection =  categoriesCollection.items.filter({($0 as? FTShelfItemCollection)?.isUnfiledNotesShelfItemCollection ?? false
                }).first as? FTShelfItemCollection {
                    shelfItemCollection.append(uncategorizedCollection)
                }
            }
            
            let systemDefaultCollection = FTShelfCategoryCollection(name: NSLocalizedString("Noteshelf", comment: "My Noteshelf"),type: .systemDefault, categories: shelfItemCollection);
            categoryCollection.append(systemDefaultCollection)
            
            //Second section: user created categories
            if !userCollections.isEmpty, let categoriesCollection = userCollections.first {
                if let items =  categoriesCollection.items.filter({self.isUserCreatedCollection(collection: $0 as? FTShelfItemCollection)}) as? [FTShelfItemCollection] {
                    let categoriesCollection = FTShelfCategoryCollection(type: .user,categories: items)
                    categoryCollection.append(categoriesCollection)
                }
            }
            self.newcategorizedShelfs = categoryCollection
            completion(categoryCollection)
        }
    }
    
    private func isUserCreatedCollection(collection: FTShelfItemCollection?) ->Bool {
        if let collection = collection, (collection.isMigratedCollection || collection.isDefaultCollection) && !collection.isUnfiledNotesShelfItemCollection {
            return true
        }
        return false
    }
    
    fileprivate func fetchCloudCollections(_ completion : @escaping (([FTShelfItemCollection]) -> Void)) {
        guard let listener = cloudDocumentListener, let cloudcollection = cloudShelfCollectionRoot?.ns3Collection else {
            completion([FTShelfItemCollection]());
            return
        }

        listener.startQuery {
            cloudcollection.shelfs(completion);
        }
    }

    func createShelf(_ name: String, onCompletion : @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        self.currentCollection().createShelf(name, onCompletion: onCompletion);
    }

    func renameShelf(_ collection: FTShelfItemCollection, title: String, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        if(collection.collectionType == .system || collection.collectionType == .allNotes) {
            systemShelfCollection.renameShelf(collection, title: title, onCompletion: onCompletion);
        } else {
            self.currentCollection().renameShelf(collection, title: title, onCompletion: onCompletion);
        }
    }

    fileprivate func rootDocumentsURL() -> URL {
        return self.currentCollection().documentsDirectory();
    }

    fileprivate func currentCollection() -> FTShelfCollection {
        var collection: FTShelfCollection!;
        if let mode = self.providerMode {
            switch mode {
            case .local:
                collection = self.localShelfCollectionRoot?.ns3Collection;
            case .cloud:
                collection = self.cloudShelfCollectionRoot?.ns3Collection;
            }
        }
        guard let validcollection = collection else { fatalError("Collection should not be nil") }
        return validcollection;
    }

    fileprivate func sortedCollections(_ items: [FTShelfItemCollection]) -> [FTShelfItemCollection] {
        let sortedItems = items.sorted(by: { object1, objec2 -> Bool in
            var title1 = object1.displayTitle.lowercased();
            var title2 = objec2.displayTitle.lowercased();
            //********To make this category always on top
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if object1.displayTitle == uncategorizedShefItemCollectionTitle {
                title1 = ""
            }
            if objec2.displayTitle == uncategorizedShefItemCollectionTitle {
                title2 = ""
            }
            #endif
            //********
            
            let returnVal = (title1.caseInsensitiveCompare(title2) == ComparisonResult.orderedAscending) ? true : false;
            return returnVal;
        });
        return sortedItems;
    }
}

extension FTNoteshelfDocumentProvider {
    func userShelfCollections(_ completion : @escaping (([FTShelfItemCollection]) -> Void)) {
        var shelfCollections = [FTShelfItemCollection]();
        
        let shelfsCompletionBlock: (([FTShelfItemCollection]) -> Void)  = { items in
            shelfCollections.append(contentsOf: self.sortedCollections(items))
#if !NOTESHELF_ACTION
            systemShelfCollection.shelfs({ systemsShelfs in
                shelfCollections.append(contentsOf: self.sortedCollections(systemsShelfs))
                shelfCollections.insert(self.allNotesShelfItemCollection, at: 0)
                completion(shelfCollections);
            });
#else
            completion(shelfCollections);
#endif
        }
        if providerMode == .cloud {
            self.fetchCloudCollections(shelfsCompletionBlock);
        } else {
            self.currentCollection().shelfs(shelfsCompletionBlock);
        }
    }

    func uncategorizedNotesCollection(_ onCompletion : @escaping ((FTShelfItemCollection?) -> Void)){
        if let uncategorizedShelf = self.currentCollection().collection(withTitle: uncategorizedShefItemCollectionTitle) {
            onCompletion(uncategorizedShelf)
            return
        }
        //************************* One time category creation
        FTNoteshelfDocumentProvider.shared.createShelf(uncategorizedShefItemCollectionTitle, onCompletion: { (error, collection) in
            if(nil != error) {
                onCompletion(nil)
            }
            else {
                onCompletion(collection)
            }
        })
        //*************************
    }
    
#if !NS2_SIRI_APP && !NOTESHELF_ACTION
    func starredShelfItemCollection() -> FTShelfItemCollection? {
        var starredCollection: FTShelfItemCollection?
        if let recentShelfCat = self.recentShelfCollection as? FTShelfCollectionRecent {
            starredCollection = recentShelfCat.favoritesShelfItemCollection
        }
        return starredCollection
    }
    func trashShelfItemCollection(onCompletion : ((FTShelfItemCollection) -> Void)) {
        var trashCollection: FTShelfItemCollection?
        (systemShelfCollection as? FTShelfCollectionSystem)?.trashCollection(onCompletion)
    }
    #endif
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
// MARK: - Recent related -
extension FTNoteshelfDocumentProvider {

    @discardableResult func addShelfItemToList(_ shelfItem: FTShelfItemProtocol, mode: FTRecentItemType) -> NSError? {
        if mode == .recent {
            return (self.recentShelfCollection as? FTShelfCollectionRecent)?.recentShelfItemCollection.addShelfItemToList(shelfItem.URL);
        } else {
            let error = (self.recentShelfCollection as? FTShelfCollectionRecent)?.favoritesShelfItemCollection.addShelfItemToList(shelfItem.URL);
            return error;
        }
    }
    
    //This is used while migrating NS2 to NS3
    func addUrlToFavorites(_ url : URL) {
        (self.recentShelfCollection as? FTShelfCollectionRecent)?.favoritesShelfItemCollection.addShelfItemToList(url);
    }

    func removeShelfItemFromList(_ shelfItems: [FTShelfItemProtocol], mode: FTRecentItemType) {
        var urls = [URL]();
        for eachitem in shelfItems {
            urls.append(eachitem.URL);
        }
        if(!urls.isEmpty) {
            if mode == .recent {
                (self.recentShelfCollection as? FTShelfCollectionRecent)?.recentShelfItemCollection.removeShelfItemFromList(urls);
            } else {
                (self.recentShelfCollection as? FTShelfCollectionRecent)?.favoritesShelfItemCollection.removeShelfItemFromList(urls);
            }
        }
    }

    func recentShelfItems(_ sortOrder: FTShelfSortOrder,
                          parent: FTGroupItemProtocol?,
                          searchKey: String?,
                          onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void)) {
        self.recentShelfCollection?.shelfs({ itemCollection in
            let recentCollection = itemCollection.first(where: { $0.collectionType == .recent })
            if let shelfcollection = recentCollection {
                shelfcollection.shelfItems(sortOrder, parent: parent, searchKey: searchKey, onCompletion: completionBlock);
            } else {
                DispatchQueue.main.async {
                    completionBlock([FTShelfItemProtocol]());
                }
            }
        });
    }
    
    func favoritesShelfItems(_ sortOrder: FTShelfSortOrder,
                          parent: FTGroupItemProtocol?,
                          searchKey: String?,
                          onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void)) {
        self.recentShelfCollection?.shelfs({ itemCollection in
            let favoritesCollection = itemCollection.first(where: { $0.collectionType == .starred })
            if let shelfcollection = favoritesCollection {
                shelfcollection.shelfItems(sortOrder, parent: parent, searchKey: searchKey, onCompletion: completionBlock);
            } else {
                DispatchQueue.main.async {
                    completionBlock([FTShelfItemProtocol]());
                }
            }
        });
    }

    func favoritesShelfItems(_ sortOrder: FTShelfSortOrder,
                          parent: FTGroupItemProtocol?,
                          searchKey: String?) -> [FTShelfItemProtocol] {
        if let favoritesCollection = self.categorizedShelfs.first(where: { $0.type == .starred }) {
            if let items = favoritesCollection.items as? [FTShelfItemProtocol] {
                return items
            }
        }
        return [FTShelfItemProtocol]()
    }

    func addDocumentAtURLToTrash(_ url: URL,
                                 title: String,
                                 onCompletion : @escaping (NSError?,FTShelfItemProtocol?)->()) {
        (systemShelfCollection as? FTShelfCollectionSystem)?.trashCollection { trashCollection in
            trashCollection.addShelfItemForDocument(url,
                                                    toTitle: title,
                                                    toGroup: nil,
                                                    onCompletion: onCompletion);
        };
    }
}
#endif
// MARK: - Trash related -
extension FTNoteshelfDocumentProvider
{
    func moveShelfToTrash(_ collection: FTShelfItemCollection, onCompletion: @escaping ((NSError?, FTShelfItemCollection?) -> Void)) {
        collection.shelfItems(.byName, parent: nil, searchKey: nil) { items in
            self.moveItemstoTrash(items, onCompletion: { (error, _) in
                if(nil == error) {
                    var currentCollection = self.currentCollection();
                    if(collection.collectionType == .system) {
                        currentCollection = systemShelfCollection;
                    }
                    currentCollection.deleteShelf(collection, onCompletion: onCompletion);
                } else {
                    onCompletion(error, collection);
                }
            });
        };
    }

    private func moveItemToTrash(_ shelfItem: FTShelfItemProtocol,
                         onCompletion block :@escaping (NSError?, FTShelfItemProtocol?) -> Void) {
        if(shelfItem is FTGroupItemProtocol) {
            NSException(name: NSExceptionName(rawValue: "Move to trash failed"), reason: "Group can not be moved to trash", userInfo: nil).raise();
        }

        (systemShelfCollection as? FTShelfCollectionSystem)?.trashCollection { trashCollection in
            if(nil == shelfItem.shelfCollection) {
                FTLogError("MoveToTrash: shelfCollection is nil");
            }
            if(nil == shelfItem as? FTDocumentItemProtocol) {
                FTLogError("MoveToTrash: shelf item: \(shelfItem)");
            }
            if let documentItem = shelfItem as? FTDocumentItemProtocol, !documentItem.isDownloaded {
                shelfItem.shelfCollection.removeShelfItem(shelfItem, onCompletion: block);
            } else {
                shelfItem.shelfCollection.moveShelfItems([shelfItem],
                                                        toGroup: nil,
                                                        toCollection: trashCollection,
                                                        onCompletion: {(error, movedItems) in
                                                            block(error, movedItems.first)
                });
            }
        };
    }

    func moveItemstoTrash(_ shelfItems: [FTShelfItemProtocol], onCompletion block :@escaping (NSError?, [FTShelfItemProtocol]) -> Void){
        if shelfItems.isEmpty {//When deleting a shelf with no books in it.
            block(nil, [])
            return
        }
        let fromCollection = shelfItems.first?.shelfCollection
        (systemShelfCollection as? FTShelfCollectionSystem)?.trashCollection { trashCollection in
            fromCollection?.moveShelfItems(shelfItems,
                                                    toGroup: nil,
                                                    toCollection: trashCollection,
                                                    onCompletion: block);
        }
    }
    
    func moveGroupToTrash(_ groupItem: FTGroupItemProtocol, onCompletion block :@escaping (NSError?, [FTShelfItemProtocol]) -> Void){
        let shelfItems = groupItem.childrens
        var itemsToDelete = shelfItems;
        var movedItems = [FTShelfItemProtocol]()
        
        func moveItem()
        {
            if(!itemsToDelete.isEmpty) {
                if let shelfItem = itemsToDelete.first as? FTDocumentItemProtocol {
                    self.moveItemToTrash(shelfItem, onCompletion: { error, movedItem in
                        if(nil == error) {
                            movedItems.append(movedItem!)
                        }
                        itemsToDelete.removeFirst();
                        moveItem()
                    })
                } else if let groupItem = itemsToDelete.first as? FTGroupItemProtocol {
                    if !groupItem.childrens.isEmpty {
                        self.moveGroupToTrash(groupItem) { error, _movedItems in
                            if(nil == error) {
                                movedItems.append(contentsOf: _movedItems)
                            }
                            itemsToDelete.removeFirst();
                            moveItem()
                        }
                    } else {
                        if let collection = groupItem.shelfCollection {
                            collection.removeGroupItem(groupItem) { error, deletedGroup in
                                NotificationCenter.default.post(name: Notification.Name.groupItemRemoved, object: collection, userInfo: [:])
                                if(nil == error) {
                                    movedItems.append(deletedGroup!)
                                }
                                itemsToDelete.removeFirst();
                                moveItem()
                            }
                        }
                    }
                } else {
                    block(nil, movedItems)
                }
            }
            else {
                //Explicit group deletion, since we are supporting empty groups.
                if let collection = groupItem.shelfCollection {
                        collection.removeGroupItem(groupItem) { error, deletedGroup in
                            NotificationCenter.default.post(name: Notification.Name.groupItemRemoved, object: collection, userInfo: [:])
                            block(nil, movedItems)
                        }
                } else {
                    block(nil, movedItems)
                }
            }
        };
        moveItem();
    }
}

// MARK: - System Default Providers -
extension FTNoteshelfDocumentProvider {
    fileprivate func prepareSystemDefaultCollections(_ onCompletion  : @escaping () -> Void) {
        if(nil == systemShelfCollection) {
            systemShelfCollection = FTShelfCollectionSystem()
        }
#if !NOTESHELF_ACTION
        if(nil == self.recentShelfCollection) {
            self.recentShelfCollection = FTShelfCollectionRecent();
        }
#endif
        onCompletion();
    }
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
// MARK: - Move from Local to Cloud -
extension FTNoteshelfDocumentProvider {
    func moveContentsFromLocalToiCloud(onCompletion completion :@escaping ((Bool, Error?) -> Void)) {
        self.resetProviderCache();
        guard let icloudShelfCollection = cloudShelfCollectionRoot?.ns3Collection  as? FTShelfCollectioniCloud else { completion(false, nil); return }
        isContentMoving = true
        func enableUpdatesAndEndBGTask(_ bgTask: UIBackgroundTaskIdentifier) {
            isContentMoving = false
            self.cloudDocumentListener?.enableUpdates();
            endBackgroundTask(bgTask)
        }
        self.shelfs({ [weak self] (_) in
            self?.cloudDocumentListener?.disableUpdates();
            self?.localShelfCollectionRoot?.ns3Collection.shelfs({ (collections) in
                let bgTask = startBackgroundTask()
                self?.moveCollectionToCloud(collections: collections,
                                            toCloud: icloudShelfCollection,
                                            onCompletion: { error in
                                                if(nil != error) {
                                                    enableUpdatesAndEndBGTask(bgTask)
                                                    completion(false, error);
                                                } else {
                                                    self?.moveAudioContentsFromLocalToiCloud(onCompletion: { error in
                                                        enableUpdatesAndEndBGTask(bgTask)
                                                        if(nil != error) {
                                                            completion(false, error);
                                                        } else {
                                                            completion(true, nil);
                                                        }
                                                    });
                                                }
                });
            });
        });
    }
}

// MARK: - Move from Cloud to Local -
extension FTNoteshelfDocumentProvider {
    func moveContentsFromCloudToLocal(onCompletion completion :@escaping ((Bool) -> Void)) {
        guard let cloudURL = FTNSiCloudManager.shared().iCloudRootURL() else {
            return;
        }
        self.isContentMoving = true
        self.resetProviderCache();
        if let cloudDocumentListener {
            cloudDocumentListener.disableUpdates();
        }

        let _cloudDocumentListner = FTCloudDocumentListener(rootURLs: [cloudURL]);

        let ns3Collection = FTShelfCollectioniCloud(rootURL: cloudURL);
        _cloudDocumentListner.addListener(ns3Collection)

        let cloudWatchCollection = FTWatchRecordingCollection_Cloud(cloudURL: FTNSiCloudManager.shared().iCloudRootURL()!)
        _cloudDocumentListner.addListener(cloudWatchCollection)

        func stopQueryAndEnableCloudUpdates(){
            self.isContentMoving = false
            _cloudDocumentListner.stopQuery();
            self.cloudDocumentListener?.enableUpdates();
        }
        _cloudDocumentListner.startQuery {
            ns3Collection.shelfs({ (cloudCollections) in
                self.localShelfCollectionRoot?.ns3Collection.shelfs({ (_) in
                    let bgTask = startBackgroundTask()
                    self.moveCollectionToLocal(collections: cloudCollections,
                                               toLocal: self.localShelfCollectionRoot!.ns3Collection,
                                               onCompletion: { error in
                        if(nil != error) {
                            endBackgroundTask(bgTask)
                            (error! as NSError).showAlert(from: Application.visibleViewController)
                            stopQueryAndEnableCloudUpdates()
                            completion(false);
                        } else {
                            self.moveAudioContentsFromiCloudToLocal(cloudWatchCollection: cloudWatchCollection, onCompletion: { error in
                                endBackgroundTask(bgTask)
                                if(nil != error) {
                                    (error! as NSError).showAlert(from: Application.visibleViewController)
                                    stopQueryAndEnableCloudUpdates()
                                    completion(false);
                                } else {
                                    stopQueryAndEnableCloudUpdates()
                                    completion(true);
                                }
                            });
                        }
                    });
                });
            })
        }
    }
}

// MARK: - Watch
extension FTNoteshelfDocumentProvider {

    fileprivate func currentWatchCollection() -> FTWatchRecordingCollection? {
        var collection: FTWatchRecordingCollection?;
        if let mode = self.providerMode {
            switch mode {
            case .local:
                collection = self.localWatchRecordingCollection;
            case .cloud:
                collection = self.cloudWatchRecordingCollection;
            }
        }
        return collection;
    }

    func allRecordings(_ completion : @escaping (([FTWatchRecording]) -> Void)) {
        if let collection = currentWatchCollection() {
            collection.allRecordings(completion)
        } else {
            completion([FTWatchRecording]());
        }
    }

    func addRecording(tempRecord: FTWatchRecording,
                      onCompletion completion:@escaping ((FTWatchRecording?, Error?) -> Void)) {
        if let collection = currentWatchCollection() {
            collection.addRecording(tempRecord: tempRecord, onCompletion: completion)
        } else {
            completion(tempRecord, NSError.providerNotReadyError());
        }
    }

    func deleteRecording(item: FTWatchRecording,
                         onCompletion completion:@escaping ((Error?) -> Void)) {
        if let collection = currentWatchCollection() {
            collection.deleteRecording(item: item, onCompletion: completion)
        } else {
            completion(NSError.providerNotReadyError());
        }
    }

    func updateRecording(item: FTWatchRecording,
                         onCompletion completion:@escaping ((Error?) -> Void)) {
        if let collection = currentWatchCollection() {
            collection.updateRecording(item: item, onCompletion: completion)
        } else {
            completion(NSError.providerNotReadyError());
        }
    }

    func startDownloading(item: FTWatchRecording) {
        currentWatchCollection()?.startDownloading(item: item)
    }

    func rootAudioRecordingsURL() -> URL {
        return rootDocumentsURL().appendingPathComponent("Audio Recordings");
    }

    fileprivate func moveAudioContentsFromLocalToiCloud(onCompletion : @escaping ((Error?) -> Void)) {
        DispatchQueue.global().sync {
            let localCollection = FTWatchRecordingCollection_Local();
            localCollection.allRecordings { items in
                guard let watchCloudCollection = self.cloudWatchRecordingCollection else { onCompletion(nil);return }
                watchCloudCollection.allRecordings({ _ in
                    let cloudURL = watchCloudCollection.rootURL();
                    if(cloudURL.isUbiquitousFileExists()) {
                        self.moveAudioItems(items: items,
                                            fromLocalURL: localCollection.rootURL(),
                                            toCloud: cloudURL,
                                            onCompletion: onCompletion);
                    } else {
                        do {
                            try FileManager().setUbiquitous(true, itemAt: localCollection.rootURL(), destinationURL: cloudURL);
                            onCompletion(nil);
                        } catch {
                            DispatchQueue.main.async {
                                onCompletion(error);
                            }
                        }
                    }
                });
            }
        }    }

    fileprivate func moveAudioContentsFromiCloudToLocal(cloudWatchCollection: FTWatchRecordingCollection_Cloud, onCompletion: @escaping ((Error?) -> Void)) {

        DispatchQueue.global().async {
            let localCollection = FTWatchRecordingCollection_Local();
            localCollection.allRecordings { items in
                localCollection.createRootIfNeeded();

                cloudWatchCollection.allRecordings({ cloudItems in
                    let cloudRootURL = cloudWatchCollection.rootURL();
                    let localRootURL = localCollection.rootURL();
                    self.copyAudioItems(items: cloudItems,
                                        fromCloud: cloudRootURL,
                                        toLocalURL: localRootURL,
                                        onCompletion: onCompletion);
                });
            }
        }
    }
}
extension FTNoteshelfDocumentProvider {
    class func emptyTrashCollection(_ collection: FTShelfItemCollection,
                                    onController: UIViewController,
                                    onCompletion: @escaping () -> Void) {
        collection.shelfItems(.byName,
                              parent: nil,
                              searchKey: nil,
                              onCompletion:
            { (items) in
                var selectedItems = items;
                let totalItemsSelected = selectedItems.count;

                let progress = Progress();
                progress.isCancellable = false;
                progress.totalUnitCount = Int64(totalItemsSelected);
                progress.localizedDescription = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), 1, totalItemsSelected);

                let smartProgress = FTSmartProgressView.init(progress: progress);
                smartProgress.showProgressIndicator(progress.localizedDescription,
                                                    onViewController: onController);

                func clearCache(documentUUID : String?) {
                    if let docID = documentUUID {
                        let thumbnailPath = URL.thumbnailFolderURL().appendingPathComponent(docID);
                        try? FileManager.default.removeItem(at: thumbnailPath);
                    }
                }

                func emptyItemFromTrash() {
                    if let item = selectedItems.first {

                        let currentProcessingIndex = totalItemsSelected - selectedItems.count + 1;
                        let statusMsg = String(format: NSLocalizedString("DeletingPagesNofN", comment: "Deleting..."), currentProcessingIndex, totalItemsSelected);
                        progress.localizedDescription = statusMsg;

                        runInMainThread {
                            if(item is FTGroupItemProtocol) {
                                collection.shelfItems(FTShelfSortOrder.byName,
                                                      parent: item as? FTGroupItemProtocol,
                                                      searchKey: nil,
                                                      onCompletion:
                                    { (items) in
                                        collection.removeShelfItem(item,
                                                                   onCompletion:
                                            { (error, _) in
                                                if(nil == error) {
                                                    for eachItem in items {
                                                        clearCache(documentUUID: (eachItem as? FTDocumentItemProtocol)?.documentUUID);
                                                    }
                                                }
                                                progress.completedUnitCount += 1;

                                                selectedItems.removeFirst();
                                                emptyItemFromTrash();
                                        });
                                });
                            }
                            else {
                                let documentUUID = (item as? FTDocumentItemProtocol)?.documentUUID;
                                collection.removeShelfItem(item,
                                                           onCompletion:
                                    { (_, _) in
                                        clearCache(documentUUID: documentUUID);

                                        progress.completedUnitCount += 1;

                                        selectedItems.removeFirst();
                                        emptyItemFromTrash();
                                });
                            }
                        }
                    }
                    else {
                        smartProgress.hideProgressIndicator();
                        onCompletion()
                    }
                }
                emptyItemFromTrash();
        });
    }
}
extension FTNoteshelfDocumentProvider {
    func enableCloudUpdates() {
        self.cloudDocumentListener?.enableUpdates()
    }
    
    func disableCloudUpdates() {
        self.cloudDocumentListener?.disableUpdates()
    }
}

// MARK: Migration to NS3
extension FTNoteshelfDocumentProvider {

    func migrateNS2BookToNS3(url: URL, relativePath: String, isFavorite: Bool) throws -> URL? {
        var destinationURL = self.currentCollection().documentsDirectory().appending(path: relativePath)

        // Change Destination Path extesion to `ns3`
        destinationURL = destinationURL.pathExtesnionChangedToNS3()

        do {
            // Path until final location
            let parentURL = destinationURL.deletingLastPathComponent()
            if providerMode == .cloud {
                if (FileManager().fileExists(atPath: destinationURL.path(percentEncoded: false))), checkIfDatesAreEqual(for: url, destUrl: destinationURL) {
                    FileManager.replaceCoordinatedItem(atURL: destinationURL, fromLocalURL: url) { error in
                    }
                } else {
                    if !FileManager.default.fileExists(atPath: parentURL.path(percentEncoded: false)) {
                        try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
                    }
                    if(FileManager().fileExists(atPath: destinationURL.path(percentEncoded: false))) {
                        let uniqueName = FileManager.uniqueFileName(destinationURL.lastPathComponent, inFolder: parentURL)
                        destinationURL = parentURL.appendingPathComponent(uniqueName);
                    }
                    //TODO: (Discuss with Akshay) We should set Ubiquitous on background thread. Might need to move this to background, if we are on main thread.
                    try FileManager().setUbiquitous(true,
                                                    itemAt: url,
                                                    destinationURL: destinationURL);
                }
            } else {
                // TODO: Take control if required
                // Create the parent directory if required
                guard let collectionTitle = destinationURL.path.collectionName()?.deletingPathExtension else {
                    throw FTMigrationError.moveToNS3Error
                }
                let localProvider = self.localShelfCollectionRoot?.ns3Collection
                //If book is not modified in ns3 and same book is being migrated from ns2, just replace the book.
                if FileManager().fileExists(atPath: destinationURL.path(percentEncoded: false)), checkIfDatesAreEqual(for: url, destUrl: destinationURL) {
                    FileManager.replaceCoordinatedItem(atURL: destinationURL, fromLocalURL: url) { error in
                    }
                } else {
                    if(FileManager().fileExists(atPath: destinationURL.path(percentEncoded: false))) {
                        let uniqueName = FileManager.uniqueFileName(destinationURL.lastPathComponent, inFolder: parentURL)
                        destinationURL = parentURL.appendingPathComponent(uniqueName);
                    }
                    if let collection = localProvider?.collection(withTitle: collectionTitle) as? FTShelfItemCollectionLocal {
                        if !FileManager.default.fileExists(atPath: parentURL.path(percentEncoded: false)) {
                            try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
                        }
                        FTCLSLog("NFC - NS2 Migration Provider1");
                        try FileManager.default.coordinatedMove(fromURL: url, toURL: destinationURL)
                        collection.addItemsToCache([destinationURL])
                    } else {
                        localProvider?.createShelf(collectionTitle, onCompletion: { error, collection in
                            if !FileManager.default.fileExists(atPath: parentURL.path(percentEncoded: false)) {
                                try? FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
                            }
                            FTCLSLog("NFC - NS2 Migration Provider2");
                            try? FileManager.default.coordinatedMove(fromURL: url, toURL: destinationURL)
                            _ = (collection as? FTShelfItemCollectionLocal)?.addItemsToCache([destinationURL])
                        })
                    }
                }
            }
            if isFavorite {
                FTNoteshelfDocumentProvider.shared.addUrlToFavorites(destinationURL)
            }
            return destinationURL
        } catch {
            debugLog(">>>>> Migration Failure \(error)")
            throw FTMigrationError.moveToNS3Error
        }
    }
    
    private func checkIfDatesAreEqual(for url: URL, destUrl: URL) -> Bool {
        let migratedItems = FTDocumentMigration.fetchMigratedPlist()
        let displayPath = url.displayRelativePathWRTCollection()
        //Modification date is being rounded when we open and close the NS3 book, Hence checking the difference between both dates
        //2023-11-14  10:53:01 +0000 - timeIntervalSinceReferenceDate : 721651981.9387126(Saved Date)
        //2023-11-14  10:53:01 +0000 - timeIntervalSinceReferenceDate : 721651981.938713(NS3 book date)
        if let itemsDict = migratedItems[displayPath] as? [String: Any] , let data = itemsDict["modifiedDate"] as? Data, let unarchivedDate = data.date, abs(unarchivedDate.timeIntervalSinceReferenceDate - destUrl.fileModificationDate.timeIntervalSinceReferenceDate) < 1  {
            return true
        }
        return false
    }
}

extension URL {
    func pathExtesnionChangedToNS3() -> URL {
        return self.deletingPathExtension().appendingPathExtension(FTFileExtension.ns3)
    }
}
#endif

extension FTNoteshelfDocumentProvider {
    func isContentMovingInProgress() -> Bool {
        self.isContentMoving
    }
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func findDocumentItem(byDocumentId documentId: String, completion: @escaping (FTDocumentItemProtocol?) -> Void) {
        allNotesShelfItemCollection.shelfItems(FTShelfSortOrder.none, parent: nil, searchKey: nil) { allItems in
            let foundItem = allItems.first { item in
                (item as? FTDocumentItemProtocol)?.documentUUID == documentId
            } as? FTDocumentItemProtocol
            completion(foundItem)
        }
    }

    func checkIfDocumentExistsInTrash(byDocumentId docId: String, completion: @escaping (Bool) -> Void) {
        self.trashShelfItemCollection { trashCollection in
            trashCollection.shelfItems(.none, parent: nil, searchKey: nil) { items in
                if let foundItem = items.first { item in
                    (item as? FTDocumentItemProtocol)?.documentUUID == docId
                } as? FTDocumentItemProtocol {
                    completion(true)
                    return
                }
                completion(false)
            }
        }
    }
#endif
}
