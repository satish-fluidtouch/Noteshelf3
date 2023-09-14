//
//  FTCustomSortingCache.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 21/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTCustomSortingCache: NSObject {

    private weak var indexContainer: FTSortIndexContainerProtocol?
    private var cachePath: String = ""
    private var hashIndexInfo: [String: Int] = [String: Int]()
    private var itemsList: [String] = [String]()

    private var isCloudItem: Bool {
        var collection: FTShelfItemCollection? = indexContainer as? FTShelfItemCollection
        if let groupItem = indexContainer as? FTGroupItemProtocol {
            collection = groupItem.shelfCollection
        }
        return (collection is FTShelfItemCollectionICloud)
    }
    
    var lastUpdatedTimestamp: TimeInterval = 0 //0 - For local
    
    private var plistPath: String {
#if DEBUG || ADHOC
        if !isCloudItem {
            //fatalError("should not be called for local data");
        }
#endif
        return self.cachePath.appending("/indexCache.plist")
    }
    
    private func customSortingCacheDirectory() -> URL
    {
        let sharedGroupLocation = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID());
        let libraryURL = sharedGroupLocation!.appendingPathComponent("Library", isDirectory: true);
        let cacheDirectory = libraryURL.appendingPathComponent("CustomSortingCache", isDirectory: true);
        return cacheDirectory;
    }

    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }

    required init(withContainer container: FTSortIndexContainerProtocol) {
        super.init();
        self.indexContainer = container
        if self.isCloudItem {
            self.cachePath = self.customSortingCacheDirectory().appendingPathComponent(container.relativePath).path
            self.createDirectoryIfNeeded()
            
            self.buildExistingCache()
        } else {
            if let path = container.indexPlistContent?.URL {
                self.buildExistingCacheForLocal(path)
            }
            else {
                #if DEBUG || ADHOC
                fatalError("Indexplist missing for local data");
                #endif
            }
        }
    }

    private func buildExistingCacheForLocal(_ url: URL) {
        do {
            let data = try Data(contentsOf: url);
            if let sortedList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
                objc_sync_enter(self)
                self.itemsList = sortedList
                objc_sync_exit(self)
                self.lastUpdatedTimestamp = url.fileModificationDate.timeIntervalSinceReferenceDate;
                self.updateHashIndexInfo()
            }
        }
        catch {

        }
    }

    private func buildExistingCache() {
        if let indexCacheDict = NSMutableDictionary.init(contentsOfFile: self.plistPath) as? [String : Any], let list = indexCacheDict["items"] as? [String] {
            objc_sync_enter(self)
            self.itemsList = list
            objc_sync_exit(self)

            if let timestamp = indexCacheDict["lastUpdated"] as? NSNumber {
                self.lastUpdatedTimestamp = timestamp.doubleValue
            }
            self.updateHashIndexInfo()
        }
    }
    
    func handleRenameUpdate() {
        if let container = self.indexContainer {
            let newCachePath = self.customSortingCacheDirectory().appendingPathComponent(container.relativePath).path
            if newCachePath != self.cachePath {
                try? FileManager.default.moveItem(atPath: self.cachePath, toPath: newCachePath)
                self.cachePath = newCachePath
            }
        }
    }
    
    func handleDeletionUpdate() {
        if let container = self.indexContainer {
            let cachePath = self.customSortingCacheDirectory().appendingPathComponent(container.relativePath).path
            try? FileManager.default.removeItem(atPath: cachePath)
        }
    }
    
    private func createDirectoryIfNeeded() {
        let fileManager = FileManager()
        if(!fileManager.fileExists(atPath: self.cachePath)) {
            try? fileManager.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func updateNotebooksList(_ list: [String],
                             isUpdateFromCloud: Bool,
                             latestUpdated: TimeInterval) {
        objc_sync_enter(self)
        self.itemsList = list
        objc_sync_exit(self)

        if isUpdateFromCloud {
            if self.lastUpdatedTimestamp < latestUpdated {
                self.lastUpdatedTimestamp = latestUpdated
                self.saveSortedListToCloudAndCache(isFromCloud: isUpdateFromCloud)
            }
        }
        else {
            self.saveSortedListToCloudAndCache(isFromCloud: isUpdateFromCloud)
        }
    }
    
    private func updateHashIndexInfo() {
        var dictIndexInfo = [String: Int]()
        var index: Int = 0
        self.itemsList.forEach { (eachString) in
            dictIndexInfo[eachString] = index
            index += 1
        }
        self.hashIndexInfo = dictIndexInfo
    }

    func getIndex(for item: String) -> Int? {
        if self.hashIndexInfo.isEmpty {//For local mode, need to initialize
            _ = self.indexContainer?.indexPlistContent
        }
        return self.hashIndexInfo[item]
    }
}

extension FTCustomSortingCache {
    func addNewNotebookTitle(_ title: String, atIndex index: Int) {
        objc_sync_enter(self)
        if !self.itemsList.isEmpty {//Only if already user manually reordered
            self.itemsList.insert(title, at: 0)
        }
        objc_sync_exit(self)
        
        self.saveSortedListToCloudAndCache(isFromCloud: false)
    }
    
    func updateNotebookTitle(from title: String, to newTitle: String) {
        objc_sync_enter(self)
        if let index = self.itemsList.index(of: title) {
            self.itemsList[index] = newTitle
        }
        objc_sync_exit(self)
        
        self.saveSortedListToCloudAndCache(isFromCloud: false)
    }
        
    func createNotebookListIfNeeded() {
        if self.itemsList.isEmpty, let childItems = self.indexContainer?.childrens {
            var booksList = [String]()
            childItems.forEach { (shelfItem) in
                booksList.append(shelfItem.sortIndexHash)
            }
            objc_sync_enter(self)
            self.itemsList = booksList
            objc_sync_exit(self)
        }
        //No need to write updates to disk as immediately next update will take care of it. Generally it happens when creating a group in which not yet attempted reorder
    }
    
    func deleteNotebookTitle(_ title: String) {
        objc_sync_enter(self)
        if let index = self.itemsList.index(of: title) {
            self.itemsList.remove(at: index)
        }
        objc_sync_exit(self)
        
        self.saveSortedListToCloudAndCache(isFromCloud: false)
    }
    
    private func saveSortedListToCloudAndCache(isFromCloud isCloudUpdate: Bool) {
        if !isCloudUpdate {
            self.lastUpdatedTimestamp = Date().timeIntervalSinceReferenceDate
            self.indexContainer?.indexPlistContent?.updateNotebooksList(self.itemsList)
        }
        self.updateHashIndexInfo()
        
        if self.isCloudItem {
            DispatchQueue.main.async {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.saveSortingOrderToDisk), object: nil)
                self.perform(#selector(self.saveSortingOrderToDisk), with: nil, afterDelay: 3.0)
            }
        }
    }

    @objc func saveSortingOrderToDisk() {
        DispatchQueue.global(qos: .background).async {
            self.createDirectoryIfNeeded()
            let updatedData = try? PropertyListSerialization.data(fromPropertyList: ["lastUpdated": self.lastUpdatedTimestamp, "items": self.itemsList] as AnyObject, format: PropertyListSerialization.PropertyListFormat.xml, options: 0);
            guard let contentsData = updatedData else { return }
            try? contentsData.write(to: URL.init(fileURLWithPath: self.plistPath), options: NSData.WritingOptions.atomic);
        }
    }
}
