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
    static func pdfFileItem(_ fileName: String,document: FTNoteshelfDocument?) -> FTPDFKitFileItemPDF {
//#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//        return FTNSPDFFileItem(fileName: fileName, document: document);
//#else
        return FTPDFKitFileItemPDF(fileName: fileName, document: document);
//#endif
    }
    
    override var usePDFKitForPDFFileItems: Bool {
        return true;
    }
    
    override func fileItem(with url: URL!, canLoadSubdirectory: Bool) -> FTFileItem! {
        if(url.pathExtension == nsPDFExtension) {
            return self.pdfFileItem(with: url);
        }
        else {
            return super.fileItem(with: url, canLoadSubdirectory: canLoadSubdirectory);
        }
    }
    
    override func plistFileItem(with url: URL!) -> FTFileItem! {
        if(url.lastPathComponent == DOCUMENT_INFO_FILE_NAME) {
            let fileItem = FTNSDocumentInfoPlistItem(url:url
                                                     , isDirectory: false
                                                     , document: self.parentDocument)
            return fileItem;
        }
        else if(url.lastPathComponent == NOTEBOOK_RECOVERY_PLIST) {
            let fileItem = FTNotebookRecoverPlist(url:url
                                                  , isDirectory: false
                                                  , document: self.parentDocument)
            return fileItem;
        }
        else {
            return super.plistFileItem(with: url)
        }
    }
    
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//    override func pdfFileItem(with url: URL!) -> FTFileItem! {
//        return FTNSPDFFileItem(url: url
//                               , isDirectory: false
//                               , document: self.parentDocument);
//    }
    
    override func sqliteFileItem(with url: URL!) -> FTFileItem! {
        let fileItem = FTNSqliteAnnotationFileItem(url:url
                                                   ,isDirectory: false
                                                   , document: self.parentDocument)
        return fileItem;
    }
#endif
}
