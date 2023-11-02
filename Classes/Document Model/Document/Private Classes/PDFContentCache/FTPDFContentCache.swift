//
//  FTPDFContentCache.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 24/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTPDFContentCacheProtocol {
    var pdfContentCache: FTPDFContentCache? {get};
}

class FTPDFContentCache: NSObject {
    private var documentUUID : String;
    private var operationQuque = OperationQueue();

    private var contentCache: FTCache;

    required init(documentUUID : String) {
        self.documentUUID = documentUUID;
        self.contentCache = FTCache(identifier: documentUUID);
        super.init();
    }
            
    func canContinuePDFContentSearch(for page: FTPageProtocol) ->  Bool {
        return self.canContinuePDFContentSearch(page.uuid);
    }
    
    func pdfContentFor(_ pageProtocol: FTPageProtocol) -> FTPDFPageContent? {
        let key = pageProtocol.associatedPDFFileName.appending("_\(pageProtocol.associatedPDFKitPageIndex)");
        let pdfContent = self.readCache(key);
        return pdfContent;
    }
    
    func cachePDFContent(_ pdfPage: PDFPage, pageProtocol: FTPageProtocol) -> FTPDFPageContent {
        let key = pageProtocol.associatedPDFFileName.appending("_\(pageProtocol.associatedPDFKitPageIndex)");
        
        self.pdfContentSearchDidStart(pageProtocol.uuid);

        let string: String;
        if let sel = pdfPage.selection(for: pdfPage.bounds(for: .cropBox))  {
            string = sel.string ?? "";
        }
        else {
            string = pdfPage.string ?? "";
        }

        var charRects = [CGRect]();
        for index in 0..<string.count {
            if let selection = pdfPage.selection(for: NSRange(location: index, length: 1)) {
                let charNewRect = selection.bounds(for: pdfPage);
                charRects.append(charNewRect);
            }
            else {
                let charRect = pdfPage.characterBounds(at: index);
                charRects.append(charRect);
            }
        }
        let pdfContent = FTPDFPageContent(pdfContent: string, charRects: charRects);
        self.pdfContentSearchDidComplete(pageProtocol.uuid);
        self.operationQuque.addOperation {
            self.saveCache(pdfContent, key: key);
        }
        return pdfContent
    }
}


private extension FTPDFContentCache {
    var cachePath: URL {
        let cacheURL = URL.appPDFCacheURL;
        let localMetadataFolder = cacheURL.appendingPathComponent(self.documentUUID);
        if(!FileManager.default.fileExists(atPath: localMetadataFolder.path(percentEncoded: false))) {
            _ = try? FileManager.default.createDirectory(at: localMetadataFolder, withIntermediateDirectories: true, attributes: nil);
        }
        return localMetadataFolder;
    }

    func cachePath(for key: String) -> URL
    {
        let localMetadataFolder = self.cachePath;
        let fileName = key.appending("-index.plist");
        return localMetadataFolder.appendingPathComponent(fileName);
    }

    func readCache(_ key: String) -> FTPDFPageContent? {
        let path = self.cachePath(for: key);
        do {
            if FileManager().fileExists(atPath: path.path(percentEncoded: false)) {
                let data = try Data(contentsOf: path)
                if let value = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [FTPDFPageContent.self
                                                                                  ,NSString.self
                                                                                  ,NSArray.self
                                                                                  ,NSValue.self
                                                                                 ], from: data) as? FTPDFPageContent {
                    return value;
                }
            }
        }
        catch {
            debugLog("Loading failed: \(error.localizedDescription)")
        }
        return nil;
    }

    func saveCache(_ object: FTPDFPageContent, key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false);
            try data.write(to: self.cachePath(for: key), options: .atomic);
        }
        catch {
            debugLog("Writing failed: \(error.localizedDescription)")
        }
    }
}

private extension FTPDFContentCache {
    var timeStampKey: String {
        return "timeStamp";
    }
    
    var minDuration: TimeInterval {
        return 12 * 60 * 60;
    }
    
    func canContinuePDFContentSearch(_ pageUUID: String) -> Bool {
        if FTUserDefaults.isInSafeMode() {
            return false
        }
        var canContinue = false;
        let val = self.contentCache.object(forKey: pageUUID) as? [String:Any] ?? [String:Any]();
        let timeStamp = (val[timeStampKey] as? TimeInterval) ?? 0;
        let curTimeStamp = Date().timeIntervalSinceReferenceDate;
        if(curTimeStamp - timeStamp > minDuration) {
            canContinue = true;
        }
        return canContinue;
    }
        
    func pdfContentSearchDidStart(_ pageUUID: String) {
        var val = self.contentCache.object(forKey: pageUUID) as? [String:Any] ?? [String:Any]();
        val[timeStampKey] = Date().timeIntervalSinceReferenceDate;
        self.contentCache.setObject(val, forKey: pageUUID);
    }
    
    func pdfContentSearchDidComplete(_ pageUUID: String) {
        self.contentCache.removeObject(forKey: pageUUID);
    }
}

extension URL {
    static var appPDFCacheURL: URL {
        guard let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                    .userDomainMask,
                                                                    true).last else {
            fatalError("library folder not found")
        }
        let cacheFolderURL = URL(fileURLWithPath: cacheFolder);
        let localMetadataFolder = cacheFolderURL.appendingPathComponent("ContentCache");
        return localMetadataFolder;
    }
    
    func delete() {
        try? FileManager().removeItem(at: self);
    }
}
