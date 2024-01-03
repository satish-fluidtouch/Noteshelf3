//
//  FTPDFPageContent.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 25/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPDFPageContent: NSObject,NSSecureCoding,FTPDFPageCacheContent {
    private(set) var pdfContent: String = "";
    private(set) var characterRects = [CGRect]();
    
    static var supportsSecureCoding: Bool = true;
    private var filePath: URL?;
    
    required init(documentID: String, pageProtocol: FTPageProtocol) {
        
    }
    
    required init?(coder: NSCoder) {
        super.init();
        if let stringValue = coder.decodeObject(forKey: "contnet") as? String {
            self.pdfContent = stringValue;
        }
        if let values = coder.decodeObject(forKey: "charRect") as? [CGRect] {
            self.characterRects = values;
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pdfContent, forKey: "contnet");
        coder.encode(self.characterRects, forKey: "charRect");
    }
    
    static func cachedPdfPageContent(_ docID: String,pageProtocol: FTPageProtocol) -> FTPDFPageContent? {
        let localMetadataFolder = URL.appPDFCacheURL.appendingPathComponent(docID);
        let fileName = FTPDFPageCacheFactory.fileName(pageProtocol.associatedPDFFileName, pageIndex: pageProtocol.associatedPDFKitPageIndex);
        let path = localMetadataFolder.appendingPathComponent(fileName);
        do {
            if FileManager().fileExists(atPath: path.path(percentEncoded: false)) {
                let data = try Data(contentsOf: path)
                if let value = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [FTPDFPageContent.self
                                                                                  ,NSString.self
                                                                                  ,NSArray.self
                                                                                  ,NSValue.self
                                                                                 ], from: data) as? FTPDFPageContent {
                    value.filePath = path;
                    return value;
                }
            }
        }
        catch {
            debugLog("Loading failed: \(error.localizedDescription)")
        }
        return nil;
    }
    
    func delete() {
        if let path = self.filePath {
            try? FileManager().removeItem(at: path)
        }
    }
}
