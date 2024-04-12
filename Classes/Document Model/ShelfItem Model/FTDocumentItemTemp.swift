//
//  FTDocumentItemTemp.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentItemTemp: NSObject, FTDocumentItemProtocol {
    var isDownloaded: Bool = true;
    
    var downloadProgress: Float = 0;
    
    var isDownloading: Bool = false;
    
    var isUploaded: Bool = true;
    
    var uploadProgress: Float = 0;
    
    var isUploading: Bool = false;
    
    var documentUUID: String?
    
    func updateShelfItemInfo(_ metaData: NSMetadataItem) {
        
    }
    
    func updateLastOpenedDate() {
        fileLastOpenedDate = Date();
    }
    
    var parent: FTGroupItemProtocol?
    
    var shelfCollection: FTShelfItemCollection!
    
    var URL: URL
    
    var uuid: String = UUID().uuidString;
    
    var displayTitle: String {
        guard let displayTitle = tempDisplayTitle?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !displayTitle.isEmpty else {
            return NSLocalizedString("quickNotesSave.quickNote", comment: "Quick Note");
        }
        return displayTitle;
    }

    required init(fileURL: URL) {
        self.URL = fileURL
    }

    var tempDisplayTitle: String?;
    
    private(set) var fileLastOpenedDate: Date = Date();
    
    func relativePathWRTCollection() -> String {
        let fileName = self.displayTitle+".\(self.URL.pathExtension)";
        let parentURL: URL = self.parent?.URL ?? self.shelfCollection.URL;
        return parentURL.appending(path: fileName).relativePathWRTCollection()
    }
}
