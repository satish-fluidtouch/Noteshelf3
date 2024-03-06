//
//  FTCachedDocument.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTCachedPage: NSObject {
    var pageUUID: String = UUID().uuidString;
    var pageIndex: Int = 0
    required init(_ info: [String: Any]) {
        if let uuid  = info["uuid"] as? String {
            self.pageUUID = uuid;
        }
    }
}

class FTCachedDocument: FTDocument {
    private var documentID: String = UUID().uuidString;
    
    override init(fileURL url: URL) {
        super.init(fileURL: url);
        self.rootFileItem = self.fileItemFactory().fileItem(with: self.fileURL, canLoadSubdirectory: true);
    }
    
    override func fileItemFactory() -> FTFileItemFactory! {
        return FTNSCacheDocumentFactory();
    }
    
    func pages() -> [FTCachedPage]
    {
        var pages = [FTCachedPage]();
        
        if let plist = self.rootFileItem.childFileItem(withName: DOCUMENT_INFO_FILE_NAME) as? FTFileItemPlist
            , let content = plist.contentDictionary, let pageInfo = plist.contentDictionary["pages"] as? [[String:Any]] {
            pageInfo.enumerated().forEach { eachPage in
                let page = FTCachedPage(eachPage.element)
                page.pageIndex = eachPage.offset + 1;
                pages.append(page);
            }
        }
        return pages;
    }

    func resourceFileItem(_ fileName: String) -> FTFileItem? {
        return self.rootFileItem.childFileItem(withName: RESOURCES_FOLDER_NAME)?.childFileItem(withName: fileName);
    }
    
    func nonStrokeFileItem(_ pageID: String) -> FTNonStrokeAnnotationFileItem? {
        var shouldCache: Bool = false;
        var _nonStrokeItem: FTNonStrokeAnnotationFileItem?;
        var nonStrokeFolder = self.rootFileItem.childFileItem(withName: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE)
        if nil == nonStrokeFolder , let itme = FTFileItem(fileName: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE, isDirectory: true) {
            self.rootFileItem.addChildItem(itme)
            nonStrokeFolder = itme;
        }
        
        
        if let annotationFile = self.rootFileItem.childFileItem(withName: ANNOTATIONS_FOLDER_NAME)?.childFileItem(withName: pageID) as? FTNSqliteAnnotationFileItem {
            shouldCache = true;
            if let nonStrokeItem = nonStrokeFolder?.childFileItem(withName: pageID) as? FTNonStrokeAnnotationFileItem {
                _nonStrokeItem = nonStrokeItem;
                if annotationFile.fileItemURL.fileModificationDate.compare(nonStrokeItem.fileItemURL.fileModificationDate) == .orderedAscending {
                    shouldCache = false;
                }
            }
            if shouldCache {
                _ = annotationFile.cacheNonStrokeAnnotations(annotationFile.fileItemURL);
                if nil == _nonStrokeItem {
                    let item = FTNonStrokeAnnotationFileItem(fileName: pageID);
                    nonStrokeFolder?.addChildItem(item)
                    _nonStrokeItem = item;
                }
            }
        }
        return _nonStrokeItem;
    }
}

class FTNSCacheDocumentFactory: FTFileItemFactory {
    override func imageFileItem(with url: URL!) -> FTFileItem! {
        return FTCachedImageFileItem(url: url, isDirectory: false);
    }
    
    override func fileItem(with url: URL!, canLoadSubdirectory: Bool) -> FTFileItem! {
        if url.pathExtension == "sqlite" || url.deletingLastPathComponent().lastPathComponent == ANNOTATIONS_FOLDER_NAME {
            return FTNSqliteAnnotationFileItem(url: url, isDirectory: false);
        }
        else if url.deletingLastPathComponent().lastPathComponent == FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE {
            return FTNonStrokeAnnotationFileItem(url: url, isDirectory: false);
        }
        return super.fileItem(with: url, canLoadSubdirectory: canLoadSubdirectory);
    }
}
