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
    
    func pdfContentFor(_ pageProtocol: FTPageProtocol) -> FTPDFPageCacheContent? {
        return FTPDFPageCacheFactory.cachedPageContent(self.documentUUID, pageProtocol: pageProtocol);
    }
    
    func cachePDFContent(_ pdfPage: PDFPage, pageProtocol: FTPageProtocol) -> FTPDFPageCacheContent {
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
        
        let pdfContent = FTPDFPageCacheFactory.pdfPageContent(self.documentUUID, pageProtocol: pageProtocol);
        pdfContent.update(pdfContent: string, charRects: charRects)
        self.pdfContentSearchDidComplete(pageProtocol.uuid);
        self.operationQuque.addOperation {
            pdfContent.save();
        }
        return pdfContent
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

private var _cacheFolder: URL?;

extension URL {
    static var appPDFCacheURL: URL {
        if nil == _cacheFolder {
            guard let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                        .userDomainMask,
                                                                        true).last else {
                fatalError("library folder not found")
            }
            _cacheFolder = URL(fileURLWithPath: cacheFolder).appendingPathComponent("ContentCache");
        }
        return _cacheFolder!;
    }
    
    func delete() {
        try? FileManager().removeItem(at: self);
    }
}
