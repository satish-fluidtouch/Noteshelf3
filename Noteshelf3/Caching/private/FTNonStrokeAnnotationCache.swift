//
//  FTFileAnnotationCache.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 13/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let NON_STROKE_ANNOTATION_CACHE = "non_stroke_annotation";
class FTNonStrokeAnnotationCache: NSObject {
    private var documentID: String = UUID().uuidString;
    private var pageID: String = UUID().uuidString;
    
    convenience init(documentID docId: String,pageID pageUUID: String) {
        self.init();
        self.documentID = docId;
        self.pageID = pageUUID;
    }
            
    func annotations(types: [FTAnnotationType]) -> [FTAnnotation] {
        var annotations = [FTAnnotation]();
        let annotationsInfo = self.annotationsInfo();
        annotationsInfo.forEach { eachItem in
            if types.contains(eachItem.annotationType)
                ,let annotation = FTAnnotation.annotation(eachItem) {
                annotations.append(annotation);
            }
        }
        return annotations;
    }
    
    
    func cacheAnnotations(_ documentPath: URL,pageID: String) {
        let sqlitePath = documentPath.appending(path: ANNOTATIONS_FOLDER_NAME).appending(path: pageID);
        guard FileManager().fileExists(atPath: sqlitePath.path) else {
            return;
        }
        
        let modifiedDate = sqlitePath.fileModificationDate;
        let typesNotToCache = [
            FTAnnotationType.stroke.rawValue
            ,FTAnnotationType.shape.rawValue
        ]
        
        let keywordSelQuery = "SELECT * from annotation WHERE annotationType NOT IN (?)";
        let dbQueue = FMDatabaseQueue(url: sqlitePath);
        var itemsToStroe = [FTAnnotationDictInfo]();
        dbQueue?.inDatabase({ database in
            database.open();
            let set = database.executeQuery(keywordSelQuery, withArgumentsIn: typesNotToCache);
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    let count = _set.columnCount;
                    var info = FTAnnotationDictInfo();
                    for i in 0..<count {
                        if let columnValue = _set.columnName(for: i)
                            ,!_set.columnIsNull(columnValue)
                            ,let value = _set.object(forColumn: columnValue) {
                            info[columnValue] = value;
                        }
                    }
                    if !info.isEmpty {
                        itemsToStroe.append(info);
                    }
                }
            }
            set?.close();
            database.close();
        });
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: itemsToStroe, format: .xml, options: 0);
            var nontStrokePlist = self.cacheLocation(documentPath,pageID: pageID);
            try data.write(to: nontStrokePlist, options: .atomic)
            
            var val = URLResourceValues.init()
            val.contentModificationDate = modifiedDate;
            try? nontStrokePlist.setResourceValues(val);
        }
        catch {
            
        }
    }
}

extension FTNonStrokeAnnotationCache {
    func searchForTextAnnotation(contains key: String) -> [FTAnnotation] {
        var annotations = [FTAnnotation]();
        let lowercasedKey = key.lowercased();

        let annotationsInfo = self.annotationsInfo();
        annotationsInfo.forEach { eachItem in
            if eachItem.annotationType == .text
                ,eachItem.nonAttrText.lowercased().contains(lowercasedKey)
                ,let annotation = FTAnnotation.annotation(eachItem) {
                annotations.append(annotation);
            }
        }
        return annotations;
    }
}

private extension FTNonStrokeAnnotationCache {
    func cacheLocation(_ docURL: URL,pageID: String) -> URL {
        var nonStrokePath = docURL.appending(path: NON_STROKE_ANNOTATION_CACHE);
        var isDir = ObjCBool(false)
        if !FileManager().fileExists(atPath: nonStrokePath.path(percentEncoded: false), isDirectory: &isDir)
            || !isDir.boolValue {
            do {
                try FileManager().createDirectory(at: nonStrokePath, withIntermediateDirectories: true)
            }
            catch {
                fatalError(error.localizedDescription);
            }
        }
        nonStrokePath = nonStrokePath.appending(path: pageID);
        return nonStrokePath;
    }
    
    func shouldCache(_ sqlitePath: URL,cachePath: URL) -> Bool {
        let pathString = cachePath.path(percentEncoded: false)
        if !FileManager().fileExists(atPath: pathString) {
            return true;
        }
        guard FileManager().fileExists(atPath: sqlitePath.path) else {
            return false;
        }
        
        let cacheModifiedDate = cachePath.fileModificationDate;
        let annotationModifiedDate = sqlitePath.fileModificationDate;
        return annotationModifiedDate.compare(cacheModifiedDate) != .orderedAscending;
    }
    
    func annotationsInfo() -> [FTAnnotationDictInfo] {
        var info = [FTAnnotationDictInfo]();
        let documentURL = FTDocumentCache.shared.cachedLocation(for: documentID);
        
        let annotationsFilePath = self.cacheLocation(documentURL,pageID: self.pageID);
        let sqlitePath = documentURL.appending(path: ANNOTATIONS_FOLDER_NAME).appending(path: self.pageID);
        if shouldCache(sqlitePath, cachePath: annotationsFilePath) {
            self.cacheAnnotations(documentURL, pageID: self.pageID);
        }
        let pathString = annotationsFilePath.path(percentEncoded: false)
        if FileManager().fileExists(atPath: pathString) {
            do {
                let data = try Data(contentsOf: annotationsFilePath);
                let contents = try PropertyListSerialization.propertyList(from: data, format: nil)
                if let annotationsInfo = contents as? [FTAnnotationDictInfo] {
                    info = annotationsInfo;
                }
            }
            catch {
                
            }
        }
        return info;
    }
}

private extension FTAnnotationDictInfo {
    var nonAttrText: String {
        guard let nonAttrText = self["nonAttrText"] as? String else {
            return "";
        }
        return nonAttrText;
    }
}
