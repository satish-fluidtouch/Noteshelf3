//
//  FTNSDocumentFileItemFactory.swift
//  Noteshelf
//
//  Created by Amar on 30/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

class FTNSDocumentFileItemFactory : FTFileItemFactory
{
    override var usePDFKitForPDFFileItems: Bool {
        return true;
    }
    
    override func fileItem(with url: URL!, canLoadSubdirectory: Bool) -> FTFileItem! {
        if(url.pathExtension == nsPDFExtension) {
            return super.pdfFileItem(with: url);
        }
        else {
           return super.fileItem(with: url, canLoadSubdirectory: canLoadSubdirectory);
        }
    }
    
    override func plistFileItem(with url: URL!) -> FTFileItem! {
        
        if(url.lastPathComponent == DOCUMENT_INFO_FILE_NAME)
        {
            let fileItem = FTNSDocumentInfoPlistItem.init(url:url,isDirectory: false)
            return fileItem;
        }
        else if(url.lastPathComponent == NOTEBOOK_RECOVERY_PLIST)
        {
            let fileItem = FTNotebookRecoverPlist.init(url:url,isDirectory: false)
            return fileItem;
        }
        else
        {
            return super.plistFileItem(with: url)
        }
        
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    override func sqliteFileItem(with url: URL!) -> FTFileItem! {
        let fileItem = FTNSqliteAnnotationFileItem.init(url:url,isDirectory: false)
        return fileItem;
    }
    #endif
}
