//
//  FTGroupItem.swift
//  Noteshelf
//
//  Created by Amar on 14/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTGroupItemTopBooks: NSObject {
    var sortOrder: FTShelfSortOrder = .byModifiedDate
    var topAtMost3Notebooks: [FTShelfItemProtocol] = []
}

class FTGroupItem : NSObject,FTGroupItemProtocol, FTShelfItemSorting
{
    @objc var isUpdated: Bool = false {
        didSet {
            if isUpdated == true {
                self.postGroupUpdatedNotification()
            }
        }
    }

    private(set) lazy var indexPlistContent: FTSortingIndexPlistContent? = {
        return FTSortingIndexPlistContent.init(parent: self)
    }()
    lazy var indexCache: FTCustomSortingCache? = {
        return FTCustomSortingCache(withContainer: self)
    }()
    
    var uuid : String = FTUtils.getUUID();
    var URL : Foundation.URL {
        didSet {
            if(oldValue != self.URL) {
                NotificationCenter.default.post(name: .didChangeURL, object: self, userInfo: nil)
            }
        }
    };

    //download progress info
    var isDownloaded : Bool = true;
    var downloadProgress = Float(0);
    var isDownloading  : Bool = false;
    
    //upload progress info
    var isUploaded : Bool = true;
    var uploadProgress = Float(0);
    var isUploading  : Bool = false;
    
    weak var parent : FTGroupItemProtocol?;
    weak var shelfCollection: FTShelfItemCollection!
    
    var childrens = [FTShelfItemProtocol]();
    
    var type : RKShelfItemType {
        get {
            return RKShelfItemType.group;
        }
    };

    required init(fileURL : Foundation.URL)
    {
        URL = fileURL;
        super.init()
    }

    override var hash: Int {
        return self.uuid.hashValue;
    }
    private var topBooks = FTGroupItemTopBooks()
    
    private func allNotebooks() -> [FTShelfItemProtocol] {
        var notebooks = self.notebooksInGroup()
        for eachChild in childrens {
            if let groupItem = eachChild as? FTGroupItem {
                notebooks.append(contentsOf: groupItem.allNotebooks())
            }
        }
        return notebooks
    }
    
    private func notebooksInGroup() -> [FTShelfItemProtocol] {
        return self.childrens.compactMap { eachChild in
            return eachChild as? FTDocumentItem
        }
    }
    
    public func isGroupEmpty() -> Bool {
        return self.allNotebooks().count == 0
    }

    var fileCreationDate: Date {
        get {
            let sortedGroup = self.sortItems(self.childrens, sortOrder: FTShelfSortOrder.byCreatedDate);
            if let firstChild = sortedGroup.first {
                return firstChild.fileCreationDate;
            }
            return self.URL.fileCreationDate;
        }
    }
    
    private var _fileLastOpenedDate: Date?;
    var fileLastOpenedDate: Date {
        get {
            if let date = _fileLastOpenedDate {
                return date;
            }
            let sortedGroupItems = self.sortItems(self.childrens, sortOrder: FTShelfSortOrder.byLastOpenedDate)
            if !sortedGroupItems.isEmpty {
                var lastModifyDate: Date = Date.init(timeIntervalSinceReferenceDate: 0)
                for eachItem in sortedGroupItems {
                    let modificationDate = eachItem.fileLastOpenedDate
                    if modificationDate.compare(lastModifyDate) == .orderedDescending {
                        lastModifyDate = modificationDate;
                    }
                }
                _fileLastOpenedDate = lastModifyDate
            }
            return _fileLastOpenedDate ?? self.fileModificationDate
        }
        set {
            _fileLastOpenedDate = newValue;
        }
    }
    
    private var _modifiedDate: Date?
    var fileModificationDate: Date {
        get {
            if _modifiedDate != nil {
                return self._modifiedDate!
            }
            let sortedGroupItems = self.sortItems(self.childrens, sortOrder: FTShelfSortOrder.byModifiedDate)
            if !sortedGroupItems.isEmpty {
                var lastModifyDate: Date = Date.init(timeIntervalSinceReferenceDate: 0)
                for eachItem in sortedGroupItems {
                    var modificationDate = eachItem.fileModificationDate
                    if let group = eachItem as? FTGroupItemProtocol {
                        modificationDate = group.fileModificationDate
                    }
                    if modificationDate.compare(lastModifyDate) == ComparisonResult.orderedDescending {
                        lastModifyDate = modificationDate
                    }
                }
                _modifiedDate = lastModifyDate
            }
            return _modifiedDate ?? self.URL.fileModificationDate;
        }
        set {
            _modifiedDate = newValue
        }
    }
    
    func resetCachedDates(modified: Bool = true,lastOpened: Bool = true) {
        if(modified) {
            self._modifiedDate = nil;
        }
        if(lastOpened) {
            self._fileLastOpenedDate = nil;
        }
        if(nil == self.parent) {
            return;
        } else {
            if let groupItem = self.parent as? FTGroupItem {
                groupItem.resetCachedDates(modified: modified,lastOpened: lastOpened);
            }
        }
    }
    
    func addGroupItemForURL(_ fileURL : Foundation.URL,addToCache hashTable: FTHashTable?) -> FTGroupItemProtocol? {
        var itemToReturn: FTGroupItemProtocol?;
        
        if let first = fileURL.pathRelativeTo(self.URL).components(separatedBy: "/").first,
           first.hasSuffix(FTFileExtension.group) { // Ensuring url's first component has a group extension
            if let item = self.groupItemWithName(title: first) {
                itemToReturn = item
            }
            else {
                let url = self.URL.appendingPathComponent(first);
                let item = FTGroupItem(fileURL: url);
                self.addChild(item);
                hashTable?.addItemToHashTable(item, forKey: url);
                itemToReturn = item;
            }
            if let item = itemToReturn {
                if item.URL.urlByDeleteingPrivate() == fileURL.urlByDeleteingPrivate() {
                    return item;
                }
                return (item as? FTGroupItem)?.addGroupItemForURL(fileURL,addToCache: hashTable);
            }
        }
        return nil;
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
    
    private func groupItemWithName(title: String) -> FTGroupItemProtocol? {
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
       
    func fetchTopNotebooks(sortOrder: FTShelfSortOrder,noOfBooksTofetch: Int = 3, onCompletion completionBlock: @escaping (([FTShelfItemProtocol]) -> Void)) {
        if self.topBooks.sortOrder == sortOrder {
            if self.topBooks.topAtMost3Notebooks.isEmpty {
                self.shelfCollection.shelfItems(sortOrder, parent: self, searchKey: "") { (childrens) in
                    let items = [FTShelfItemProtocol]();
                    self.fetchItems(noOfItems: noOfBooksTofetch,
                                     fromItems: childrens,
                                     sortOrder: sortOrder,
                                     returnItems: items) { topitems in
                        self.topBooks.topAtMost3Notebooks = topitems
                        completionBlock(self.topBooks.topAtMost3Notebooks)
                    }
                }
            }
            else {
                completionBlock(self.topBooks.topAtMost3Notebooks)
            }
        } else {
            self.topBooks.sortOrder = sortOrder
            self.clearTopMost3NoteBooks();
            self.fetchTopNotebooks(sortOrder: sortOrder,noOfBooksTofetch: noOfBooksTofetch, onCompletion: completionBlock);
        }
    }
    
    func clearTopMost3NoteBooks() {
        topBooks.topAtMost3Notebooks = []
    }
    private func postGroupUpdatedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "GroupUpdatedNotification"),
                                        object: self,
                                        userInfo: nil)
    }
    
    deinit {
        #if DEBUG
        debugPrint("deinit :\(self.URL.path.removingPercentEncoding ?? "")");
        #endif
    }
}

//MARK:- Manual Sorting
extension FTGroupItem: FTSortIndexContainerProtocol {
    //If supporting multiple levels of folder structure, this has to be changed accordingly
    func handleSortIndexFileUpdates(_ infoItem: Any?) {
        if let metadata = infoItem as? NSMetadataItem {
            self.indexPlistContent?.handleSortIndexFileUpdates(metadata)
        }
        else {
            self.indexPlistContent?.handleSortIndexFileUpdates(nil)
        }
    }
}

private extension FTGroupItem {
    func fetchItems(noOfItems: Int,fromItems items: [FTShelfItemProtocol],
                     sortOrder: FTShelfSortOrder,
                     index: Int = 0,
                     returnItems: [FTShelfItemProtocol], completionBlock: @escaping (([FTShelfItemProtocol]) -> Void)) {
        var inTems = items
        if !inTems.isEmpty,index < noOfItems {
            let firstItem = inTems.removeFirst()
            if let gorupItem = firstItem as? FTGroupItem {
                gorupItem.fetchTopNotebooks(sortOrder: sortOrder) { inItems in
                    let ind = index + 1;
                    var _returnItems = returnItems;
                    if let item = inItems.first {
                        _returnItems.append(item);
                    }
                    self.fetchItems(noOfItems: noOfItems,
                                    fromItems: inTems,
                                     sortOrder: sortOrder,
                                     index: ind,
                                     returnItems: _returnItems,
                                     completionBlock: completionBlock);
                }
            }
            else {
                let ind = index + 1;
                var _returnItems = returnItems;
                _returnItems.append(firstItem);
                self.fetchItems(noOfItems: noOfItems,
                                fromItems: inTems,
                                 sortOrder: sortOrder,
                                 index: ind,
                                 returnItems: _returnItems,
                                 completionBlock: completionBlock);
            }
        }
        else {
            completionBlock(returnItems);
        }
    }
}
