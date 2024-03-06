//
//  FTCacheableDocument.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

@objc protocol FTCacheableDocument: NSObjectProtocol {
    func generateCache(documentID: String,cacheLocation: URL);
}

extension FTDocument: FTCacheableDocument {
    func generateCache(documentID: String,cacheLocation: URL) {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        let cacheDocumentURL = cacheLocation.appending(path: documentID).appendingPathExtension(FTFileExtension.ns3);
        coordinator.coordinate(readingItemAt: self.fileURL
                               , options: .withoutChanges
                               , writingItemAt: cacheDocumentURL
                               , options: .forReplacing
                               , error: &error) { readingURL, writingURL in
            let filemanager = FileManager();
            
            var shouldCache = false;
            if !filemanager.fileExists(atPath: writingURL.path(percentEncoded: false)) {
                try? filemanager.createDirectory(at: writingURL, withIntermediateDirectories: true);
                shouldCache = true;
            }
            else {
                let existingmodified = writingURL.fileModificationDate
                let newModified = self.fileURL.fileModificationDate

                // Can be improved by checking for .orderedAscending/orderedDescending, for now we're just replacing the existing cache if the modification dates mismatches.
                shouldCache = existingmodified.compare(newModified) == .orderedAscending
                cacheLog(.info, " \(shouldCache) existing: \(existingmodified) new: \(newModified)", self.fileURL)
            }
            
            if let rootFileItem = self.fileItemFactory()?.fileItem(with: readingURL, canLoadSubdirectory: true) {
                if shouldCache , rootFileItem.saveCache(writingURL) {
                    let sourceDate = readingURL.fileModificationDate;
                    try? filemanager.setAttributes([.modificationDate:sourceDate], ofItemAtPath: writingURL.path(percentEncoded: false));
                }
                else if let properttyFileItem = rootFileItem.childFileItem(withName: METADATA_FOLDER_NAME).childFileItem(withName: PROPERTIES_PLIST), properttyFileItem.saveCache(writingURL) {
                    let sourceDate = readingURL.fileModificationDate;
                    try? filemanager.setAttributes([.modificationDate:sourceDate], ofItemAtPath: writingURL.path(percentEncoded: false));
                }
            }
        }
    }
}
