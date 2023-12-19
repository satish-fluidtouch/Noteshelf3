//
//  FTNoteshelfDocument_FileItems.swift
//  Noteshelf
//
//  Created by Amar on 1/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

extension FTNoteshelfDocument : FTDocumentFileItems
{
    func createDefaultFileItems()
    {
        self.rootFileItem = FTFileItem.init(url: self.URL, isDirectory: true);
        self.rootFileItem.securityDelegate  = self;
        
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        self.recognitionCache = FTRecognitionCache.init(withDocument: self, language: FTLanguageResourceManager.shared.currentLanguageCode);
        #endif

        let resourceFolderItem = FTFileItem.init(fileName: RESOURCES_FOLDER_NAME, isDirectory: true)
        resourceFolderItem?.securityDelegate  = self;
        self.rootFileItem.addChildItem(resourceFolderItem);

        let metadataFolderItem = FTFileItem.init(fileName: METADATA_FOLDER_NAME, isDirectory: true)
        metadataFolderItem?.securityDelegate  = self;
        self.rootFileItem.addChildItem(metadataFolderItem);
        
        let templateFolderItem = FTFileItem.init(fileName: TEMPLATES_FOLDER_NAME, isDirectory: true)
        templateFolderItem?.securityDelegate  = self;
        self.rootFileItem.addChildItem(templateFolderItem);
        
        let annotationFolderItem = FTFileItem.init(fileName: ANNOTATIONS_FOLDER_NAME, isDirectory: true)
        annotationFolderItem?.securityDelegate  = self;
        self.rootFileItem.addChildItem(annotationFolderItem);
        
        let documentInfoPlist = FTNSDocumentInfoPlistItem.init(fileName: DOCUMENT_INFO_FILE_NAME)
        documentInfoPlist.securityDelegate  = self;
        self.rootFileItem.addChildItem(documentInfoPlist);
        
        let propertyPlist = FTFileItemPlist.init(fileName: PROPERTIES_PLIST)
        propertyPlist?.securityDelegate  = self;
        metadataFolderItem?.addChildItem(propertyPlist);
    }
    
    
    func resourceFolderItem() -> FTFileItem?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        let folderItem = self.rootFileItem.childFileItem(withName: RESOURCES_FOLDER_NAME);
        return folderItem;
    }
    
    func metadataFolderItem() -> FTFileItem?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        let folderItem = self.rootFileItem.childFileItem(withName: METADATA_FOLDER_NAME);
        return folderItem;
    }
    
    func templateFolderItem() -> FTFileItem?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        let folderItem = self.rootFileItem.childFileItem(withName: TEMPLATES_FOLDER_NAME);
        return folderItem;
    }
    
    func annotationFolderItem() -> FTFileItem?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        let folderItem = self.rootFileItem.childFileItem(withName: ANNOTATIONS_FOLDER_NAME);
        return folderItem;
    }
    
    
    func documentInfoPlist() -> FTNSDocumentInfoPlistItem?
    {
        if(nil == self.documentPlistItem) {
            if(nil == self.rootFileItem) {
                return nil;
            }
            let documentInfoPlist = self.rootFileItem.childFileItem(withName: DOCUMENT_INFO_FILE_NAME) as? FTNSDocumentInfoPlistItem;
            documentInfoPlist?.parentDocument = self;
            self.documentPlistItem = documentInfoPlist;
        }
        return self.documentPlistItem;
    }
    
    func recoveryInfoPlist() -> FTNotebookRecoverPlist? {
        if(nil == self.rootFileItem) {
            return nil;
        }
        
        let recoveryPlist = self.rootFileItem.childFileItem(withName: NOTEBOOK_RECOVERY_PLIST) as? FTNotebookRecoverPlist
        return recoveryPlist
    }
    
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func recognitionInfoPlist() -> FTFileItemPlist?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        var folderItem = self.rootFileItem.childFileItem(withName: RECOGNITION_FILES_FOLDER_NAME);
        if(folderItem == nil){
            folderItem = FTFileItem.init(fileName: RECOGNITION_FILES_FOLDER_NAME, isDirectory: true)
            self.rootFileItem.addChildItem(folderItem);
        }
        let plistFileName = String.init(format: "%@_%@.plist", RECOGNITION_INFO_FILE_NAME, FTLanguageResourceManager.shared.currentLanguageCode ?? "en_US")
        var recognitionInfoPlist = folderItem!.childFileItem(withName: plistFileName) as? FTFileItemPlist;
        if(nil == recognitionInfoPlist) {
            recognitionInfoPlist = FTFileItemPlist.init(fileName: plistFileName)
            folderItem!.addChildItem(recognitionInfoPlist);
        }
        //recognitionInfoPlist?.parentDocument = self;
        return recognitionInfoPlist;
    }
    func visionRecognitionInfoPlist() -> FTFileItemPlist?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        var folderItem = self.rootFileItem.childFileItem(withName: RECOGNITION_FILES_FOLDER_NAME);
        if(folderItem == nil){
            folderItem = FTFileItem.init(fileName: RECOGNITION_FILES_FOLDER_NAME, isDirectory: true)
            self.rootFileItem.addChildItem(folderItem);
        }
        let plistFileName = String.init(format: "%@_%@.plist", VISION_RECOGNITION_INFO_FILE_NAME, FTVisionLanguageMapper.currentISOLanguageCode())
        var visionRecognitionInfoPlist = folderItem!.childFileItem(withName: plistFileName) as? FTFileItemPlist;
        if(nil == visionRecognitionInfoPlist) {
            visionRecognitionInfoPlist = FTFileItemPlist.init(fileName: plistFileName)
            folderItem!.addChildItem(visionRecognitionInfoPlist);
        }
        //recognitionInfoPlist?.parentDocument = self;
        return visionRecognitionInfoPlist;
    }

    #endif
    func propertyInfoPlist() -> FTFileItemPlist?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        let propertyInfoPlist = self.metadataFolderItem()?.childFileItem(withName: PROPERTIES_PLIST) as? FTFileItemPlist;
        return propertyInfoPlist;
    }

    func updateDocumentTags(tags: [String]) {
        self.propertyInfoPlist()?.setObject(tags, forKey: DOCUMENT_TAGS_KEY);
        if !self.pages().isEmpty, let firstPage = self.pages().first {
          firstPage.isDirty = true
        }
      }

    func assignmentInfoPlist(createIfNeeded : Bool) -> FTFileItemPlist?
    {
        if(nil == self.rootFileItem) {
            return nil;
        }
        var propertyInfoPlist = self.metadataFolderItem()?.childFileItem(withName: ASSIGNMENTS_PLIST) as? FTFileItemPlist;
        if(nil == propertyInfoPlist && createIfNeeded) {
            propertyInfoPlist = FTFileItemPlist.init(fileName: ASSIGNMENTS_PLIST)
            propertyInfoPlist?.securityDelegate  = self;
            self.metadataFolderItem()?.addChildItem(propertyInfoPlist);
        }
        return propertyInfoPlist;
    }
    
    func validateFileItemsForDocumentConsistancy() -> Bool
    {
        if(nil == self.rootFileItem) {
            let params = ["Reason" : "Root folder Missing"]
            logDocumentCorrupt(params);
            return false;
        }
        let templateFolderItem = self.rootFileItem.childFileItem(withName: TEMPLATES_FOLDER_NAME);
        if(nil == templateFolderItem) {
            let params = ["Reason" : "Template folder Missing"]
            logDocumentCorrupt(params);
            return false;
        }
        
        if(self.templateFolderItem()?.children.count == 0) {
            let params = ["Reason" : "Template folder has no files"]
            logDocumentCorrupt(params);
            return false;
        }
        
        let metaDataFolderItem = self.rootFileItem.childFileItem(withName: METADATA_FOLDER_NAME);
        if(nil == metaDataFolderItem) {
            let params = ["Reason" : "Metadata folder Missing"]
            logDocumentCorrupt(params);
            return false;
        }

        let propertyInfoPlist = self.metadataFolderItem()?.childFileItem(withName: PROPERTIES_PLIST) as? FTFileItemPlist;
        if(nil == propertyInfoPlist) {
            let params = ["Reason" : "Property plist Missing"]
            logDocumentCorrupt(params);
            return false;
        }
        
        let documentVersion = self.propertyInfoPlist()?.object(forKey: DOCUMENT_VERSION_KEY) as? String;
        if(nil == documentVersion) {
            let params = ["Reason" : "document version is nil"]
            logDocumentCorrupt(params);
            return false;
        }
        
        let value = (documentVersion! as NSString).floatValue;
        if(value > APP_SUPPORTED_MAX_DOC_VERSION) {
            self.logDocumentVersionNotSupported(documentVersion)
            return false;
        }

        var annotateFolderItem = self.rootFileItem.childFileItem(withName: ANNOTATIONS_FOLDER_NAME);
        if(nil == annotateFolderItem) {
            annotateFolderItem = FTFileItem.init(fileName: ANNOTATIONS_FOLDER_NAME, isDirectory: true)
            annotateFolderItem?.securityDelegate = self;
            self.rootFileItem.addChildItem(annotateFolderItem);
        }
        
        var resourceFolderItem = self.rootFileItem.childFileItem(withName: RESOURCES_FOLDER_NAME);
        if(nil == resourceFolderItem) {
            resourceFolderItem = FTFileItem.init(fileName: RESOURCES_FOLDER_NAME, isDirectory: true)
            resourceFolderItem?.securityDelegate = self;
            self.rootFileItem.addChildItem(resourceFolderItem);
        }

        return true;
    }    
}
