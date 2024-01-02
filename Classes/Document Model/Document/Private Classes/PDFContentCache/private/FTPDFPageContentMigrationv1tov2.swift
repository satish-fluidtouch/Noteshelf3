//
//  FTPDFPageContentMigrationv1tov2.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 18/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPDFPageContentMigrationv1tov2: NSObject {
    private var documentID: String;
    private var pageProtocol: FTPageProtocol;
    
    required init(docId: String,pageProtocol page: FTPageProtocol) {
        documentID = docId;
        pageProtocol = page
    }
        
    func migrate() -> FTPDFPageCacheContent? {
        let pageContent = FTPDFPageCacheFactory.pdfPageContent(self.documentID, pageProtocol: self.pageProtocol)
        if let v1Cache = FTPDFPageContent.cachedPdfPageContent(self.documentID, pageProtocol: pageProtocol) {
            pageContent.update(pdfContent: v1Cache.pdfContent, charRects: v1Cache.characterRects);
            pageContent.save();
            v1Cache.delete();
            return pageContent;
        }
        if pageContent.contentExists() {
            return pageContent;
        }
        return nil;
    }
}
