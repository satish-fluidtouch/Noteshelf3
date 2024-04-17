//
//  FTRecentEntries.swift
//  Noteshelf
//
//  Created by Amar on 14/06/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

let FTRecentItemAlias = "alias"
let FTUUIDIdentifier = "uuid"

enum FTRecentItemType: String {
    case recent = "RecentsDocuments"
    case favorites = "FavoritesDocuments"
    
    fileprivate var fileName: String {
        switch self {
        case .recent:
            return "recents.plist";
        case .favorites:
            return "favorites.plist";
        }
    }
}

typealias FTRecentItem = [String:String]

class FTDiskRecentItem: NSObject {
    var _fileURL: URL?;
    var fileURL: URL? {
        get {
            guard let returnURL = _fileURL else {
                debugLog("\(self.mode.rawValue): fileUrl not yet set")
                FTLogError("ALIAS_NIL", attributes: ["mode": self.mode.rawValue])
                return nil
            }
            return returnURL;
        }
        set {
            _fileURL = newValue;
        }
    }
    
//    var filePath : String? {
//        return fileURL?.path(percentEncoded: false);
//    }
    
    private(set) var mode: FTRecentItemType = .recent;
    var aliasData: Data = Data();
    private var uuid = UUID().uuidString;
    
    init( _ inData: Data,url: URL,mode inmode: FTRecentItemType) {
        aliasData = inData
        _fileURL = url;
        mode = inmode;
    }

    init?( _ info: [String:String],mode inmode: FTRecentItemType) {
        if let aliasString = info[FTRecentItemAlias],let data = Data.init(base64Encoded: aliasString) {
            aliasData =  data;
        }
        else {
            return nil;
        }
        if let _uuid = info[FTUUIDIdentifier] {
            uuid = _uuid;
        }
    }
    
    func dictionaryRepresentation() -> FTRecentItem {
        var info = FTRecentItem();
        info[FTRecentItemAlias] = aliasData.base64EncodedString();
        info[FTUUIDIdentifier] = uuid;
        return info;
    }
}


class FTRecentEntries: NSObject {
    fileprivate static let recentDataProvider = FTRecentDataProvider(.recent);
    fileprivate static let favDataProvider = FTRecentDataProvider(.favorites);
    
    static func defaults() -> UserDefaults {
        return UserDefaults.init(suiteName: FTSharedGroupID.getAppGroupID())!
    }
        
    static func isRecentEntriesUpdated() -> Bool
    {
        return self.defaults().bool(forKey: "isUpdated");
    }
    
    static func markIsRecentEntriesUpdated()
    {
        let defaults = self.defaults();
        defaults.setValue(false, forKey: "isUpdated");
        defaults.synchronize();
    }
    
    static func allRecentEntries() -> [FTDiskRecentItem] {
        return recentDataProvider.recentItems();
    }
    
    static func allFavoriteEntries() -> [FTDiskRecentItem] {
        return favDataProvider.recentItems();
    }
        
    private static func dataProvider(_ mode: FTRecentItemType) -> FTRecentDataProvider {
        switch mode {
        case .recent:
            return recentDataProvider;
        case .favorites:
            return favDataProvider;
        }
    }
    
    @discardableResult static func saveEntry(_ url : URL,mode: FTRecentItemType) -> Bool {
        let dataProvider = dataProvider(mode);
        let success = dataProvider.addEntry(url);
        return success;
    }
            
    @discardableResult static func deleteEntry(_ url : URL,mode : FTRecentItemType) -> Bool {
        let dataProvider = dataProvider(mode);
        let success = dataProvider.removeEntry(url);
        return success;
    }

    static func updateEntry(_ from : URL, with newURL : URL,mode: FTRecentItemType) -> Bool {
        let dataProvider = dataProvider(mode);
        return dataProvider.movedEntry(from: from, to: newURL);
    }
        
    @objc static func updateImageInGroupContainerForUrl(_ url : URL) {
        if let _ = self.recentDataProvider.itemFor(url) {
            _ = self.recentDataProvider.addEntry(url);
        } else if let _ = self.favDataProvider.itemFor(url) {
            _ = self.favDataProvider.addEntry(url);
        }
    }
    
    static func isFavorited(_ url: URL) -> Bool {
        if nil != self.favDataProvider.itemFor(url) {
            return true;
        }
        return false;
    }
    
    static func resetRecentEntries() {
        recentDataProvider.reset();
        let defaults = self.defaults();
        defaults.setValue(false, forKey: "isUpdated");
        defaults.synchronize();
    }
    
    #if DEBUG || BETA
    static func clearRecentList() {
        recentDataProvider.reset();
    }
    
    static func clearStarredList() {
        favDataProvider.reset();
    }
    #endif
}

private class FTRecentDataProvider {
    private var lock = NSRecursiveLock();
    
    private func defaults() -> UserDefaults {
        return UserDefaults.init(suiteName: FTSharedGroupID.getAppGroupID())!
    }
    private var mode: FTRecentItemType = .recent;
    
    init(_ inMode: FTRecentItemType) {
        mode = inMode;
    }
    
    func movedEntry(from: URL, to: URL) -> Bool {
        lock.lock()
        debugLog("\(self.mode.rawValue): movedEntry - START");
        var success = false;
        if let item = self.itemFor(from)
            , let aliasData = URL.aliasData(to) {
            item.aliasData = aliasData;
            item.fileURL = to;
            saveContents();
            success = true;
        }
        debugLog("\(self.mode.rawValue): movedEntry - END");
        lock.unlock()
        return success;
    }
    
    private var items = [FTDiskRecentItem]();
    func recentItems() -> [FTDiskRecentItem] {
        lock.lock()
        debugLog("\(self.mode.rawValue): loading - START");
        if(items.isEmpty) {
            self.items.append(contentsOf: self.loadContents());
        }
        removeStaledItems();
        debugLog("\(self.mode.rawValue): loading - END");
        lock.unlock()
        return items;
    }
    
    private func loadContents() -> [FTDiskRecentItem] {
        var itemsToReturn = [FTDiskRecentItem]()
        do {
            let data = try Data(contentsOf: self.filePath);
            let dictInfo = try PropertyListDecoder().decode([FTRecentItem].self, from: data)

            dictInfo.forEach { eachItem in
                if let diskItem = FTDiskRecentItem(eachItem,mode: mode) {
                    itemsToReturn.append(diskItem);
                }
            }
        }
        catch {
            
        }
        return itemsToReturn;
    }
    
    private func saveContents() {
        var itemsToSave = [FTDiskRecentItem]();
        itemsToSave.append(contentsOf: self.items);
        
        DispatchQueue.global().async {
            var infoToStore = [FTRecentItem]();
            itemsToSave.forEach { eachItem in
                infoToStore.append(eachItem.dictionaryRepresentation());
            }
            do {
                let data = try PropertyListEncoder().encode(infoToStore);
                try data.write(to: self.filePath)
                let defaults = self.defaults()
                defaults.setValue(true, forKey: "isUpdated")
            }
            catch {
                
            }
        }
    }
    
    func addEntry(_ url: URL) -> Bool {
        lock.lock()
        debugLog("\(self.mode.rawValue): addEntry - START");
        var success = false;
        if let item = self.itemFor(url), let index = self.items.firstIndex(of: item) {
            self.items.remove(at: index);
            self.items.insert(item, at: 0);
            success = true;
        }
        else if let aliasData = URL.aliasData(url) {
            let item = FTDiskRecentItem(aliasData,url: url,mode: mode);
            removeOldEntriesIfNeeded();
            items.insert(item, at: 0);
            success = true;
        }
        if(success) {
            saveContents();
        }
        debugLog("\(self.mode.rawValue): addEntry - END");
        lock.unlock()
        return success;
    }
    
    func removeEntry(_ url: URL,shouldSave: Bool = true) -> Bool {
        lock.lock()
        debugLog("\(self.mode.rawValue): removeEntry - START");
        var success = false;
        if let item = self.itemFor(url),let index = self.items.firstIndex(of: item) {
            self.items.remove(at: index);
            if(shouldSave) {
                saveContents();
            }
            success = true;
        }
        debugLog("\(self.mode.rawValue): removeEntry - END");
        lock.unlock()
        return success;
    }
    
    func itemFor(_ url: URL) -> FTDiskRecentItem? {
        lock.lock()
        let item = self.items.first(where: { (info) -> Bool in
            guard let resolvedURL = info.fileURL else {
                return false;
            }
            if url.urlByDeleteingPrivate() == resolvedURL.urlByDeleteingPrivate() {
                return true;
            }
            return false;
        });
        lock.unlock()
        return item;
    }
    
    private var filePath: URL {
        if let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTUtils.getGroupId()) {
            let directoryURL = url.appending(path: "AliasStore");
            try? FileManager().createDirectory(at: directoryURL, withIntermediateDirectories: true);
            return directoryURL.appending(path: mode.fileName);
        }
        fatalError("Failed to get path: Mode: \(mode.fileName)");
    }
    
    func reset() {
        lock.lock()
        self.items.removeAll();
        saveContents();
        lock.unlock()
    }
    
    private func removeOldEntriesIfNeeded() {
//        if(self.mode == .recent && self.items.count > maxRecentNotebook) {
//            while(self.items.count > maxRecentNotebook) {
//                self.items.removeLast();
//            }
//        }
    }
    
    var maxRecentNotebook: Int {
        if(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            if(UIScreen.main.bounds.width < 400) {
                return 8;
            }
            return 11;
        }
        return 14
    }
    
    func removeStaledItems() {
        var recentEntries = [FTDiskRecentItem]()
        var requiresSave = false;
        self.items.forEach({ eachItem in
            var isStale = false;
            if let fileURl = URL.resolvingAliasData(eachItem.aliasData, isStale: &isStale) {
                if isStale, let aliasData = URL.aliasData(fileURl) {
                    eachItem.aliasData = aliasData;
                    requiresSave = true;
                }
                eachItem.fileURL = fileURl;
                recentEntries.append(eachItem);
            }
        });
        if(recentEntries.count != self.items.count || requiresSave) {
            self.items.removeAll();
            self.items.append(contentsOf: recentEntries);
            saveContents();
        }
    }
}

// NS2 pinned items migration
final class FTPinnedItemsMigration {
    class func getNS2PinnedEntries() -> [FTRecentItem] {
        let defaults = UserDefaults.init(suiteName: FTSharedGroupID.getNS2AppGroupID())!
        guard let items = defaults.array(forKey: "FTPinnedEntries") as? [FTRecentItem] else {
            return [FTRecentItem]()
        }
        return items
    }
}

