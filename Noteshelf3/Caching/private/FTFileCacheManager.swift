//
//  FTFileCacheManager.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 16/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTRenderKit
import FTDocumentFramework

class FTFileCacheManager: NSObject {
    static func cacheDocumentAt(_ source: URL,destination: URL) throws {
        let defaultManager = FileManager();
        let fileCoorinator = NSFileCoordinator.init(filePresenter: nil)
        var copyError: NSError?
        var catchError: Error?
        FTCLSLog("NFC - Cache Doc: \(source.title)");
        fileCoorinator.coordinate(readingItemAt: source,
                                  options: NSFileCoordinator.ReadingOptions.withoutChanges,
                                  writingItemAt: destination,
                                  options: NSFileCoordinator.WritingOptions.forReplacing,
                                  error: &copyError,
                                  byAccessor:{ (readingURL, writingURL) in
            do {
                if !defaultManager.fileExists(atPath: writingURL.path(percentEncoded: false)) {
                    debugLog(">>>> copying package: \(readingURL.lastPathComponent) \(writingURL.lastPathComponent)");
                    try defaultManager.copyItem(at: readingURL, to: writingURL);
                }
                else {
                    let contents = try defaultManager.subpathsOfDirectory(atPath: readingURL.path(percentEncoded: false));
                    for relativePath in contents {
                        let fileURl = readingURL.appending(path: relativePath);
                        let destinationFilePath = writingURL.appending(path: relativePath);
                        
                        var shouldCacheAnnotation = false
                        
                        if defaultManager.fileExists(atPath: destinationFilePath.path(percentEncoded: false)) {
                            let resourceValues = try fileURl.resourceValues(forKeys: [.isDirectoryKey,.contentModificationDateKey]);
                            if !(resourceValues.isDirectory ?? true),
                               let sourceDate = resourceValues.contentModificationDate {
                                let destDate = destinationFilePath.fileModificationDate;
                                if destDate.compare(sourceDate) == .orderedAscending {
                                    debugLog(">>>> replacing item: \(relativePath) \(sourceDate) \(destDate)");
                                    try defaultManager.removeItem(at: destinationFilePath)
                                    try defaultManager.copyItem(at: fileURl, to: destinationFilePath);

                                    shouldCacheAnnotation = relativePath.hasPrefix(ANNOTATIONS_FOLDER_NAME);
                                }
                            }
                        }
                        else {
                            shouldCacheAnnotation = relativePath.hasPrefix(ANNOTATIONS_FOLDER_NAME);
                            debugLog(">>>> creating item: \(relativePath)");
                            try defaultManager.copyItem(at: fileURl, to: destinationFilePath);
                        }
                        if shouldCacheAnnotation {
                            let cache = FTNonStrokeAnnotationCache();
                            cache.cacheAnnotations(writingURL, pageID: destinationFilePath.lastPathComponent);
                        }
                    }
                    let sourceDate = readingURL.fileModificationDate;
                    try defaultManager.setAttributes([.modificationDate:sourceDate], ofItemAtPath: writingURL.path(percentEncoded: false));

                    //Remove unused Annotation files if any exists, we identified this issue, as the photos conent is showing the photos although the page is deleted.
                    let cacheDocAnnotations = writingURL.appendingPathComponent("Annotations")
                    let mainDocAnnotations = readingURL.appendingPathComponent("Annotations")
                    let mainDocContents = try defaultManager.subpathsOfDirectory(atPath: mainDocAnnotations.path(percentEncoded: false));
                    let cacheContents = try defaultManager.subpathsOfDirectory(atPath: cacheDocAnnotations.path(percentEncoded: false));

                    let diff = Set(cacheContents).subtracting(mainDocContents)
                    diff.forEach { relativePath in
                        let fileURl = cacheDocAnnotations.appending(path: relativePath);
                        try? defaultManager.removeItem(at: fileURl)
                    }
                }
            } catch {
                catchError = error
            }
        })
        if let error = copyError {
            throw error
        }
        if let catchError = catchError {
            FTCLSLog("NFC - Cache doc: \(source.title)");
            try defaultManager.coordinatedCopy(fromURL: source, toURL: destination, force: true)
        }
    }
}

private class FTDBCacheManager: NSObject
{
    func stripDownDB(_ sourceURL: URL)
    {
        let typesNotToCache = [
            FTAnnotationType.stroke.rawValue
            ,FTAnnotationType.shape.rawValue
        ]
        let keywordSelQuery = "SELECT * from annotation WHERE annotationType NOT IN (?)";
        let dbQueue = FMDatabaseQueue(url: sourceURL);
        var itemsToStroe = [[String:Any]]();
        dbQueue?.inDatabase({ database in
            database.open();
            let set = database.executeQuery(keywordSelQuery, withArgumentsIn: typesNotToCache);
            if let _set = set , _set.columnCount > 0 {
                while(_set.next()) {
                    let count = _set.columnCount;
                    var info = [String:Any]();
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
        debugLog("items: \(itemsToStroe)");
    }
}
