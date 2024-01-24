//
//  FTNSPDFFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 24/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTNSPDFFileItem: FTPDFKitFileItemPDF {
    private var pdfDocument: PDFDocument?;
    private let use_cached_Location = false;
    
    override func loadContents(of url: URL!) -> NSObjectProtocol! {
        guard use_cached_Location else {
            return super.loadContents(of: url);
        }
        guard let document = PDFDocument(url: url) else {
            return nil;
        }
        if document.isEncrypted {
            if let password = self.documentPassword, !password.isEmpty {
                document.unlock(withPassword: password)
            }
            else {
                document.unlock(withPassword: "")
            }
        }
        return document;
    }

    override func pdfDocumentRef() -> PDFDocument! {
        guard use_cached_Location else {
            return super.pdfDocumentRef();
        }
        objc_sync_enter(self);
        if nil == pdfDocument {
            pdfDocument = self.loadPDFDocumentFromCache() as? PDFDocument;
        }
        objc_sync_exit(self);
        return pdfDocument;
    }
    
    override func unloadContentsOfFileItem() {
        objc_sync_enter(self);
        super.unloadContentsOfFileItem()
        self.pdfDocument = nil;
        objc_sync_exit(self);
    }
}

private extension FTNSPDFFileItem {
    func loadPDFDocumentFromCache() -> NSObjectProtocol {
        var itemToreturn: NSObjectProtocol? = nil;
        if let docID = (self.parentDocument as? FTNoteshelfDocument)?.documentUUID {
            let location = FTDocumentCache.shared.cachedLocation(for: docID);
            let fileManager = FileManager();
            let templatesFolder = location.appending(path: TEMPLATES_FOLDER_NAME);
            let pdfFile = templatesFolder.appending(path: self.fileItemURL.lastPathComponent);
            if fileManager.fileExists(atPath: pdfFile.path(percentEncoded: false)) {
                itemToreturn = loadContents(of: pdfFile)
            }
            else {
                let tempFolderPath = templatesFolder.path(percentEncoded: false);
                var isDir = ObjCBool(false)
                if !fileManager.fileExists(atPath: tempFolderPath, isDirectory: &isDir)
                    || !isDir.boolValue {
                    try? fileManager.createDirectory(atPath: tempFolderPath, withIntermediateDirectories: true);
                }
                let coordinator = NSFileCoordinator(filePresenter: self.parentDocument)
                coordinator.coordinate(readingItemAt: self.fileItemURL, options: .withoutChanges, error: nil) { readingURL in
                    do {
                        try fileManager.copyItem(at: readingURL, to: pdfFile);
                        itemToreturn = loadContents(of: pdfFile);
                    }
                    catch {
                        debugLog("Copy to cache failed:");
                    }
                }
            }
        }
        if(nil == itemToreturn) {
            itemToreturn = self.performCoordinatedRead();
        }
        return itemToreturn!;
    }
}
