//
//  FTNSDocumentInfoPlistItem.swift
//  Noteshelf
//
//  Created by Amar on 30/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

class FTNSDocumentInfoPlistItem : FTFileItemPlist {
    fileprivate var _pages : [FTPageProtocol]? {
        didSet{
            self.updatePageIndices();
        }
    };

    fileprivate var _tags : [String] = [String]()

    fileprivate var _defaultPageRect : CGRect = CGRect.null;

//    var tags : [String] {
//        get {
//            objc_sync_enter(self)
//            if(_tags.count == 0) {
//                let docTags = self.contentDictionary["tags"] as? [String]
//                self._tags = docTags ?? []
//            }
//            objc_sync_exit(self)
//            return self._tags
//        }
//        set{
//            objc_sync_enter(self)
//            self._tags = newValue;
//            self.setObject(self._tags, forKey: "tags");
//            objc_sync_exit(self);
//        }
//    }

    var pages : [FTPageProtocol] {
        get {
            objc_sync_enter(self)
            if(nil == _pages) {
                let pageObjects = self.contentDictionary["pages"] as? [AnyObject];
                var localPages = [FTPageProtocol]();
                if(nil != pageObjects) {
                    var isFirstPage:Bool = true
                    for eachObject in pageObjects! {
                        let page: FTNoteshelfPage
                        if let parentDoc = self.parentDocument {
                            page = FTNoteshelfPage(parentDocument: parentDoc);
                        }
                        else {
                            page = FTNoteshelfPage();
                        }
                        page.isFirstPage = isFirstPage
                        page.updatePageAttributesWithDictionary(eachObject as! Dictionary);
                        localPages.append(page);
                        isFirstPage = false
                    }
                }
                self._pages = localPages;
            }
            objc_sync_exit(self);
            return self._pages!;
        }
        set{
            objc_sync_enter(self)
            self._pages = newValue;
            self.setObject(self._pages, forKey: "pages");
            objc_sync_exit(self);
        }
    };
    
    private func updatePageIndices() {
        guard let pagesArray = self.pages as? [FTNoteshelfPage] else {
            return;
        }
        var index = 0;
        pagesArray.forEach({ (eachPage) in
            eachPage.pageCurrentIndex = index;
            index += 1;
        });
    }

    var defaultPageRect : CGRect {
        get {
            objc_sync_enter(self)
            if(_defaultPageRect.equalTo(CGRect.null) || _defaultPageRect.equalTo(CGRect.zero)) {
                var stringValue = self.contentDictionary["defaultPageRect"] as? String;
                if(nil == stringValue) {
                    stringValue = NSCoder.string(for: CGRect(x: 0, y: 0, width: 768, height: 1024));
                }
                _defaultPageRect = NSCoder.cgRect(for: stringValue!);
            }
            objc_sync_exit(self);
            return _defaultPageRect;
        }
        set {
            objc_sync_enter(self)
            _defaultPageRect = newValue;
            self.setObject(NSCoder.string(for: _defaultPageRect), forKey: "defaultPageRect");
            objc_sync_exit(self);
        }
    };
    
    weak var parentDocument : FTNoteshelfDocument?;
    
    override init(fileName: String!) {
        super.init(fileName: fileName);
        _defaultPageRect = CGRect.null;
    }

    override init(fileName: String!, isDirectory isDir: Bool) {
        super.init(fileName: fileName, isDirectory: isDir);
    }
    
    override init!(url: URL!, isDirectory isDir: Bool) {
        super.init(url: url, isDirectory: isDir);
    }
    
    func insertPage(_ page : FTNoteshelfPage, atIndex : Int)
    {
        var pageIndices = [Int]();
        objc_sync_enter(self)
        var pagesArray = self.pages;
        let canAddPage = pagesArray[safe: atIndex]
        if canAddPage != nil {
            pagesArray.insert(page, at: atIndex)
        } else {
            pagesArray.insert(page, at: pagesArray.count);
        }
        if atIndex == 0 {
            page.isPageModified = true
            page.isFirstPage = true
        }
        self.pages = pagesArray;
        pageIndices.append(atIndex);
        objc_sync_exit(self);
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FTDocumentDidAddedPageIndices"), object: page.parentDocument!, userInfo: ["pageIndices" : pageIndices]);
        }
    }
    
    func movePages(_ fromPagesArray : [FTNoteshelfPage], toIndex : Int) {
        guard var pagesArray = self.pages as? [FTNoteshelfPage] else {
            return;
        }
        objc_sync_enter(self)
        var indexes = [Int]()
        fromPagesArray.forEach { eachPage in
            if let index = pagesArray.firstIndex(of: eachPage) {
                indexes.append(index)
            }
        }
        pagesArray.move(fromOffsets: IndexSet(indexes), toOffset: toIndex)
        self.pages = pagesArray
        objc_sync_exit(self);
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FTDocumentDidMovedPageIndices"), object: pagesArray.first!.parentDocument!, userInfo: ["fromIndices" : indexes, "toIndex": toIndex]);
        }
    }
    
    func deletePages(_ pages : [FTNoteshelfPage]) {
        guard var pagesArray = self.pages as? [FTNoteshelfPage] else {
            return;
        }
        var pageIndices = [Int]();
        objc_sync_enter(self)
        let parentDocument = pages.first?.parentDocument;
        pages.forEach { (eachPage) in
            if let index = pagesArray.index(of: eachPage) {
                (eachPage as! FTDeleting).willDelete();
                pagesArray.remove(at: index);
                pageIndices.append(index);
            }
        }
        self.pages = pagesArray;
        objc_sync_exit(self);
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FTDocumentDidRemovePageIndices"),
                                            object: parentDocument,
                                            userInfo: ["pageIndices" : pageIndices]);
        }
    }

    override func saveContentsOfFileItem() -> Bool {
        objc_sync_enter(self)
        var localPages = [[String : Any]]();
        let pagesArray = self.pages as? [FTNoteshelfPage];
        pagesArray?.forEach({ (eachPage) in
            let value = eachPage.dictionaryRepresentation();
            localPages.append(value);
        });
        self.setObject(localPages, forKey: "pages");
        self.setObject(NSCoder.string(for: self.defaultPageRect), forKey: "defaultPageRect");
        self.setObject(self._tags, forKey: "tags")
        objc_sync_exit(self);
        return super.saveContentsOfFileItem();
    }
}

extension Collection where Indices.Iterator.Element == Index {
   public subscript(safe index: Index) -> Iterator.Element? {
     return (startIndex <= index && index < endIndex) ? self[index] : nil
   }
}
