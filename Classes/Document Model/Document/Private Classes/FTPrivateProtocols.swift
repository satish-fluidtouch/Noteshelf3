//
//  FTPrivateProtocols.swift
//  Noteshelf
//
//  Created by Amar on 3/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

@objc protocol FTCopying : NSObjectProtocol
{
    @objc optional func deepCopyPage(_ toDocument : FTDocumentProtocol,onCompletion : @escaping(FTPageProtocol) -> Void);
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @objc optional func deepCopyAnnotation(_ toPage : FTPageProtocol,onCompletion :@escaping (FTAnnotation?) -> Void);
    #endif
    @objc optional func deepCopy(_ onCompletion :@escaping (AnyObject) -> Void);
}

protocol FTPrepareForImporting {
    func prepareForImporting(_ onCompletion : @escaping (Bool,NSError?) -> Void);
}

@objc protocol FTDocumentFileItems
{
    var rootFileItem : FTFileItem? { get set};
    var URL : Foundation.URL { get };
    
    func createDefaultFileItems();
    func resourceFolderItem() -> FTFileItem?;
    func metadataFolderItem() -> FTFileItem?;
    func templateFolderItem() -> FTFileItem?;
    func annotationFolderItem() -> FTFileItem?;
    func documentInfoPlist() -> FTNSDocumentInfoPlistItem?;
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func recognitionInfoPlist() -> FTFileItemPlist?
    func visionRecognitionInfoPlist() -> FTFileItemPlist?
    #endif
    func propertyInfoPlist() -> FTMetadataPropertiesPlist?;
    
    func validateFileItemsForDocumentConsistancy() -> Bool;
}
