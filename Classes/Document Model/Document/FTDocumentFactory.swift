//
//  FTDocumentFactory.swift
//  Noteshelf
//
//  Created by Amar on 31/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

class FTDocumentFactory : NSObject
{
    static func tempDocumentPath(_ name : String) -> URL
    {
        let fileName = name;
        let tempPath = NSTemporaryDirectory() + "\(fileName).\(FTFileExtension.ns3)";
        return URL(fileURLWithPath: tempPath);
    }

    static func documentForItemAtURL(_ url : URL) -> FTDocumentProtocol
    {
        let document = FTNoteshelfDocument.init(fileURL : url);
        return document;
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    static func duplicateDocumentAtURL(_ url : URL,onCompletion : @escaping (NSError?,FTDocumentProtocol?) -> Void)
    {
        let path = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
        FileManager.copyCoordinatedItemAtURL(url, toNonCoordinatedURL: path) { (_, error) in
            if(nil != error) {
                onCompletion(error,nil);
            }
            else {
                if let document = FTDocumentFactory.documentForItemAtURL(path) as? FTPrepareForImporting{
                    document.prepareForImporting({ (_, error) in
                        onCompletion(error, document as? FTDocumentProtocol);
                    });
                }
            }
        }
    }
    
    static func prepareForImportingAtURL(_ url : URL,onCompletion : @escaping (NSError?,FTDocumentProtocol?) -> Void)
    {
        if let document = FTDocumentFactory.documentForItemAtURL(url) as? FTPrepareForImporting {
            document.prepareForImporting({ (_, error) in
                onCompletion(error, document as? FTDocumentProtocol);
            });
        }
    }
    #endif
}
