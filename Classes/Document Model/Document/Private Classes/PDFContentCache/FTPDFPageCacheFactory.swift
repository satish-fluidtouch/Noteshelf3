//
//  FTPDFPageCacheFactory.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 18/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTPDFPageCacheContent: NSObjectProtocol {
    var pdfContent: String {get}
    var characterRects: [CGRect] {get}
    
    init(documentID: String,pageProtocol: FTPageProtocol);
    func update(pdfContent: String, charRects: [CGRect]);
    func save();
    func ranges(for searchKey: String) -> [CGRect];
    func contentExists() -> Bool;
}

class FTPDFPageCacheFactory: NSObject {
    static func fileName(_ pdfName:String, pageIndex: UInt) -> String {
        let key = pdfName.appending("_\(pageIndex)-index.plist");
        return key;
    }

    static func cachedPageContent(_ docId: String,pageProtocol: FTPageProtocol) -> FTPDFPageCacheContent? {
        let migration = FTPDFPageContentMigrationv1tov2(docId: docId, pageProtocol: pageProtocol);
        return migration.migrate();
    }
    
    static func pdfPageContent(_ docId: String,pageProtocol: FTPageProtocol) -> FTPDFPageCacheContent {
        let page = FTPDFPageContentV2(documentID: docId, pageProtocol: pageProtocol);
        return page;
    }
}

extension FTPDFPageCacheContent {
    func contentExists() -> Bool {
        return false;
    }

    func save() {
        
    }
    
    func ranges(for searchKey: String) -> [CGRect] {
        return [CGRect]();
    }
    
    func update(pdfContent: String, charRects: [CGRect]) {
        
    }
}
