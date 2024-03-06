//
//  FTNSqliteAnnotationFileItem_FTCacheableFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 01/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTNSqliteAnnotationFileItem {
    static let NON_STROKE_ANNOTATION_CACHE = "non_stroke_annotation";
    override func saveItemToCache(_ destination: URL) -> Bool {
        guard super.saveItemToCache(destination) else {
            return false;
        }
        guard FileManager().fileExists(atPath: destination.path(percentEncoded: false)) else {
            let nontStrokePlist = self.cacheLocation(destination);
            try? FileManager().removeItem(at: nontStrokePlist)
            return true;
        }
        return self.cacheNonStrokeAnnotations(destination)
    }

    func cacheNonStrokeAnnotations(_ destination: URL) -> Bool {
        do {
            var nontStrokePlist = self.cacheLocation(destination);
            let modifiedDate = destination.fileModificationDate;
            let itemsToStroe = self.cacheSqliteAnnotations(destination);
            if itemsToStroe.isEmpty {
                try? FileManager().removeItem(at: nontStrokePlist)
            }
            else {
                let data = try PropertyListSerialization.data(fromPropertyList: itemsToStroe, format: .xml, options: 0);
                try data.write(to: nontStrokePlist, options: Data.WritingOptions.atomic);

                var val = URLResourceValues.init()
                val.contentModificationDate = modifiedDate;
                try? nontStrokePlist.setResourceValues(val);
            }
        }
        catch {
            debugPrint("error: \(error)");
            return false
        }
        return true
    }
    
    private func cacheSqliteAnnotations(_ sqlitePath: URL) -> [FTAnnotationDictInfo] {
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
        return itemsToStroe;
    }

    private func cacheLocation(_ destination: URL) -> URL {
        let docURL = destination.deletingLastPathComponent().deletingLastPathComponent()
        var nonStrokePath = docURL.appending(path: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE);
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
        let fileName = destination.deletingPathExtension().lastPathComponent
        nonStrokePath = nonStrokePath.appending(path: fileName);
        return nonStrokePath;
    }
}
