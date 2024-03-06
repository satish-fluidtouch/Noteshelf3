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
        return self.resourceFolder?.childFileItem(withName: fileName);
    }
    
    private var annotationsFolder: FTFileItem? {
        return self.rootFileItem.childFileItem(withName: ANNOTATIONS_FOLDER_NAME);
    }

    private var resourceFolder: FTFileItem? {
        return self.rootFileItem.childFileItem(withName: RESOURCES_FOLDER_NAME);
    }

    private var nonStrokeAnnotationsFolder: FTFileItem? {
        return self.rootFileItem.childFileItem(withName: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE);
    }

    
    func nonStrokeFileItem(_ pageID: String) -> FTNonStrokeAnnotationFileItem? {
        var _nonStrokeItem: FTNonStrokeAnnotationFileItem?;
        var nonStrokeFolder = self.nonStrokeAnnotationsFolder
        if nil == nonStrokeFolder
            , let itme = FTFileItem(fileName: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE, isDirectory: true) {
            self.rootFileItem.addChildItem(itme)
            nonStrokeFolder = itme;
        }

        if let annotationFile = self.annotationsFolder?.childFileItem(withName: pageID) as? FTNSqliteAnnotationFileItem {
            annotationFile.cacheNonStrokeAnnotations(annotationFile.fileItemURL);
            guard let cachePath = nonStrokeFolder?.fileItemURL.appending(path: pageID) else {
                return _nonStrokeItem;
            }
            if let fileItem = nonStrokeFolder?.childFileItem(withName: pageID) as? FTNonStrokeAnnotationFileItem {
                _nonStrokeItem = fileItem
            }
            else if FileManager().fileExists(atPath: cachePath.path(percentEncoded: false))
                        , let fileItem = self.fileItemFactory().fileItem(with: cachePath, canLoadSubdirectory: false) as? FTNonStrokeAnnotationFileItem {
                _nonStrokeItem = fileItem
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
