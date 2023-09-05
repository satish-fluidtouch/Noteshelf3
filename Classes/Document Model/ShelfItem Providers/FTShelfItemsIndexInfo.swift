//
//  FTSortingIndexPlistContent.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 22/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTSortIndexContainerProtocol: NSObjectProtocol {
    var indexPlistContent: FTSortingIndexPlistContent? {get}
    func handleSortIndexFileUpdates(_ infoItem: Any?)
    var childrens: [FTShelfItemProtocol] {get set}
    
    var indexCache: FTCustomSortingCache? {get set}
    var relativePath: String {get}
}

extension FTSortIndexContainerProtocol {
    var relativePath: String {
        if let shelf = self as? FTShelfItemCollection {
            return shelf.URL.relativePathWithOutExtension()
        }
        else if let group = self as? FTGroupItemProtocol {
            return group.URL.relativePathWithOutExtension()
        }
        return ""
    }
}

private let plistName = "shelfItemsIndex." + FTFileExtension.sortIndex
class FTSortingIndexPlistContent: NSObject {
    
    private(set) weak var parent: FTSortIndexContainerProtocol?
    private var itemsList: [String] = [String]()
    private var indexDocument: FTIndexDocument?
    private var lastUpdatedTime: TimeInterval = 0.0
    
    var URL: Foundation.URL? {
        if let parentFolder = self.parent as? FTDiskItemProtocol {
            return parentFolder.URL.appendingPathComponent(plistName)
        }
        return nil
    }
    weak var metadataItem: NSMetadataItem?;
    var fileCreationDate: Date {
        if let metadata = self.metadataItem {
            return metadata.creationDate
        }
        if let fileURL = self.URL, FileManager().fileExists(atPath: fileURL.path) {
            return fileURL.fileCreationDate;
        }
        return Date();
    }
    
    var fileModificationDate: Date {
        if let metadata = self.metadataItem {
            return metadata.modificationDate
        }
        if let fileURL = self.URL {
            return fileURL.fileModificationDate;
        }
        return Date();
    }

    convenience required init(parent: FTSortIndexContainerProtocol?)
    {
        self.init()
        self.parent = parent;

        if let fileURL = self.URL {
            self.indexDocument = FTIndexDocument.init(fileURL: fileURL)
        }
    }
            
    //MARK:- Cloud Upadtes
    func handleSortIndexFileUpdates(_ metadata: NSMetadataItem?) {
        self.metadataItem = metadata

        let modificationTime = self.fileModificationDate.timeIntervalSinceReferenceDate
        if self.lastUpdatedTime < modificationTime {
            self.lastUpdatedTime = modificationTime
            self.indexDocument?.getSortingOrderList({ (items, success) in
                if success {
                    self.itemsList = items
                    if self.indexDocument?.documentState != .inConflict {
                        self.parent?.indexCache?.updateNotebooksList(self.itemsList,
                                    isUpdateFromCloud: true,
                                    latestUpdated: self.indexDocument?.fileModificationDate?.timeIntervalSinceReferenceDate ?? 0)
                    }

                    if let parentIndexFolder = self.parent {
                        runInMainThread({
                            NotificationCenter.default.post(name: Notification.Name.sortIndexPlistUpdated, object: parentIndexFolder, userInfo: nil);
                        });
                    }
                }
            })
        }
    }
    
    func updateNotebooksList(_ items: [String]) {
        self.itemsList = items
        self.saveUpdatedItemsToDisk()
    }
        
    private func saveUpdatedItemsToDisk() {
        runInMainThread({
            if let parentIndexFolder = self.parent {
                NotificationCenter.default.post(name: Notification.Name.sortIndexPlistUpdated, object: parentIndexFolder, userInfo: nil);
            }
            self.indexDocument?.updateItemsList(self.itemsList, onCompletion: { (success) in
                if success {
                    self.lastUpdatedTime = Date().timeIntervalSinceReferenceDate
                }
            })
        });
    }
}
//MARK:- Local To iCloud
extension FTSortingIndexPlistContent {
    var unKnownError: NSError {
        return NSError.init(domain: "FTSortIndexError", code: 1001, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Error", comment:"Error")])
    }
    func moveIndexInfoItemFromLocal(_ toCloudIndexFolder: FTSortIndexContainerProtocol?,
                                    onCompletion : @escaping ((NSError?) -> Void)) {
        guard let sourceURL = self.URL, let destinationURL = toCloudIndexFolder?.indexPlistContent?.URL,
            FileManager.default.fileExists(atPath: sourceURL.path) else {
                onCompletion(self.unKnownError)
                return
        }
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                if destinationURL.fileModificationDate.compare(sourceURL.fileModificationDate) == .orderedAscending {
                    FileManager.replaceCoordinatedItem(atURL: destinationURL, fromLocalURL: sourceURL) { (error) in
                        if let nsError = error as NSError? {
                            onCompletion(nsError)
                        }
                        else {
                            onCompletion(self.unKnownError)
                        }
                    }
                }
                else {
                    try FileManager.default.removeItem(at: sourceURL)
                    onCompletion(nil);
                }
            }
            else {
                try FileManager.default.setUbiquitous(true, itemAt: sourceURL, destinationURL: destinationURL)
                onCompletion(nil);
            }
        }
        catch let fileError as NSError {
            onCompletion(fileError);
        }
    }
}

//MARK:- iCloud To Local
extension FTSortingIndexPlistContent {
    func copyIndexInfoItemFromCloud(_ toLocalIndexFolder: FTSortIndexContainerProtocol?,
                                      onCompletion : @escaping ((NSError?) -> Void)) {
        guard let sourceURL = self.URL, let destinationURL = toLocalIndexFolder?.indexPlistContent?.URL,
            FileManager.default.fileExists(atPath: sourceURL.path) else {
                onCompletion(self.unKnownError)
            return
        }
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            if destinationURL.fileModificationDate.compare(sourceURL.fileModificationDate) == .orderedAscending {
                try? FileManager().removeItem(at: destinationURL)
                FileManager.copyCoordinatedItemAtURL(sourceURL, toNonCoordinatedURL: destinationURL) { (_, nsError) in
                    onCompletion(nsError)
                }
            }
        }
        else {
            FileManager.copyCoordinatedItemAtURL(sourceURL, toNonCoordinatedURL: destinationURL) { (_, nsError) in
                onCompletion(nsError)
            }
        }
    }
}

//MARK:- FTIndexDocument
private class FTIndexDocument: UIDocument {
    private var sortOrderList: [String] = [String]()
    private var isOpened: Bool = false

    override init(fileURL url: URL) {
        super.init(fileURL: url)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeDocumentState(_:)), name: UIDocument.stateChangedNotification, object: self)
    }
    @objc func didChangeDocumentState(_ notification: Notification) {
        if self.documentState == .inConflict {
            self.resolveConflictsIfNeeded {
                
            }
        }
    }
    
    override func contents(forType typeName: String) throws -> Any {
        let updatedData = try? PropertyListSerialization.data(fromPropertyList: self.sortOrderList as AnyObject, format: PropertyListSerialization.PropertyListFormat.xml, options: 0);
        return updatedData as Any
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
      guard let contentsData = contents as? Data else { return }
        if let sortedList = try PropertyListSerialization.propertyList(from: contentsData, options: [], format: nil) as? [String] {
            self.sortOrderList = sortedList
        }
    }
    
    func getSortingOrderList(_ onCompletion: @escaping (([String], Bool) -> Void)) {
        if !self.isOpened {
            self.isOpened = true
            self.resolveConflictsIfNeeded {
                self.open { (success) in
                    var itemsList: [String] = [String]()
                    if !self.sortOrderList.isEmpty {
                        itemsList.append(contentsOf: self.sortOrderList)
                    }
                    onCompletion(itemsList, success)
                    self.close { (_) in
                        self.isOpened = false
                    }
                }
            }
        }
        else {
            onCompletion(self.sortOrderList, true)
        }
    }
    
    func updateItemsList(_ itemsList: [String],
                         onCompletion: @escaping ((Bool) -> Void)) {
        var savePurpose = UIDocument.SaveOperation.forCreating
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            savePurpose = UIDocument.SaveOperation.forOverwriting
        }
        self.sortOrderList = itemsList
        self.save(to: self.fileURL, for: savePurpose) { (success) in
            onCompletion(success)
        }
    }
    
    //MARK:- Resolve Conflict
    private func resolveConflictsIfNeeded(_ onCompletion: @escaping () -> Void) {
        if self.documentState == .inConflict {
            var documentVersions = [NSFileVersion]();
            if let currentVersion = NSFileVersion.currentVersionOfItem(at: self.fileURL),
                let otherVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.fileURL), !otherVersions.isEmpty {
                documentVersions.append(currentVersion)
                documentVersions.append(contentsOf: otherVersions)
                
                //Resolve Conflict
                if let latestVersion = self.latestVersion(documentVersions) {
                    if latestVersion != currentVersion {
                        _ = try? latestVersion.replaceItem(at: self.fileURL, options: NSFileVersion.ReplacingOptions.byMoving)
                    }
                    try? NSFileVersion.removeOtherVersionsOfItem(at: self.fileURL)
                    otherVersions.forEach { (eachVersion) in
                        eachVersion.isResolved = true
                    }
                }
            }
            debugLog("documentState :: Conflicts: \(documentVersions)")
        }
        onCompletion()
    }

    private func latestVersion(_ allVersions: [NSFileVersion]) -> NSFileVersion? {
        if allVersions.count >= 2 {
            var latestVersion = allVersions[0]
            for i in 1...allVersions.count-1 {
                let otherVersion = allVersions[i]
                if let currentVersionDate = latestVersion.modificationDate,
                    let otherVersionDate = otherVersion.modificationDate {
                    if currentVersionDate.compare(otherVersionDate) == .orderedAscending {
                        latestVersion = otherVersion
                    }
                }
            }
            return latestVersion
        }
        return nil
    }
}

extension FTShelfItemProtocol {
    var sortIndexHash: String {
        var titleString = self.displayTitle + "_" + "\(self.fileCreationDate.timeIntervalSinceReferenceDate)"
        //Workaround: In Simulator timestamp: 764788466.2378799  in iPad Device: 764788466.0 which is failing to maintain the manual sort order
        if let timeStamp = titleString.components(separatedBy: ".").first {
            titleString = String(timeStamp)
        }
        return titleString
    }
}
