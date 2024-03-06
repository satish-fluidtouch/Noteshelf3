//
//  FTCacheableFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTCacheableFileItem: NSObjectProtocol {
    func saveCache(_ documentCacheURL: URL) -> Bool;
    func readCache(_ documentCacheURL: URL) -> Any?;
}

@objc protocol FTCacheableFileItemInternal: FTCacheableFileItem {
    func saveItemToCache(_ destination: URL) -> Bool;
    func shouldCache(_ cachedFileURL: URL) -> Bool;
}

extension FTFileItem: FTCacheableFileItemInternal {
    //MAR:- FTCacheableFileItem -
    func saveCache(_ documentCacheURL: URL) -> Bool {
        var success = true;
        let destinationPath = self.cacheFileItemURL(documentCacheURL);
        if shouldCache(destinationPath) || self.isDirectory {
            success = saveItemToCache(destinationPath);
            if self.isDirectory {
                self.children.forEach { eachItem in
                    if let fileItem = eachItem as? FTFileItem {
                        success = fileItem.saveCache(documentCacheURL);
                    }
                }
                self.cleanUpCachedDirectory(destinationPath)
            }
        }
        return success;
    }
    
    func readCache(_ documentCacheURL: URL) -> Any? {
        return nil;
    }

    //MAR:- FTCacheableFileItemInternal -
    func saveItemToCache(_ destination: URL) -> Bool {
        do {
            let fileManger = FileManager();
            if isDirectory {
                var isDir = ObjCBool(false)
                if !fileManger.fileExists(atPath: destination.path(percentEncoded: false), isDirectory: &isDir)
                    || !isDir.boolValue {
                    try fileManger.createDirectory(at: destination, withIntermediateDirectories: true);
                }
            }
            else {
                try? fileManger.removeItem(at: destination);
                try fileManger.copyItem(at: self.fileItemURL, to: destination);
            }
        }
        catch {
            return false
        }
        return true
    }
    
    func cacheFileItemURL(_ documentCacheURL: URL) -> URL {
        let relPath = self.relativePathFromParent();
        guard !relPath.isEmpty else {
            return documentCacheURL;
        }
        let destinationPath = documentCacheURL.appending(path: relPath);
        return destinationPath;
    }

    func shouldCache(_ cachedFileURL: URL) -> Bool {
        if !FileManager().fileExists(atPath: cachedFileURL.path(percentEncoded: false)) {
            return true;
        }
        let newDate = self.fileItemURL.fileModificationDate;
        let cacheData = cachedFileURL.fileModificationDate;
        return cacheData.compare(newDate) == .orderedAscending
    }
    
    private func cleanUpCachedDirectory(_ cacheLocation: URL) {
        do {
            if self.isDirectory {
                let defaultManager = FileManager();
                
                let mainDocContents = try defaultManager.contentsOfDirectory(atPath: self.fileItemURL.path(percentEncoded: false));
                let cacheContents = try defaultManager.contentsOfDirectory(atPath: cacheLocation.path(percentEncoded: false));

                let diff = Set(cacheContents).subtracting(mainDocContents)
                diff.forEach { eachRelativePath in
                    let fileURl = cacheLocation.appending(path: eachRelativePath);
                    try? defaultManager.removeItem(at: fileURl)
                    if self.fileName == ANNOTATIONS_FOLDER_NAME {
                        let parentURL = cacheLocation.deletingLastPathComponent();
                        let fileName = eachRelativePath.lastPathComponent;
                        let path = parentURL.appending(path: FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE).appending(path: fileName);
                        try? defaultManager.removeItem(at: path)
                    }
                }
            }
        }
        catch  {
            
        }
    }
}

extension FTFileItem {
    func relativePathFromParent() -> String {
        var paths = [String]();
        var item: FTFileItem? = self;
        while nil != item?.parent {
            if let _item = item {
                paths.insert(_item.fileName, at: 0)
            }
            item = item?.parent;
        }
        return paths.joined(separator: "/");
    }
}
