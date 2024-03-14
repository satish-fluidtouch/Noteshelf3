//
//  FTRecognitionCache.swift
//  Noteshelf
//
//  Created by Naidu on 28/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

let MIN_SAVE_DURATION: TimeInterval = 3.0
class FTRecognitionCache: NSObject {
    
    private var recursiveLock = NSRecursiveLock();
    
    private weak var currentDocument: FTNoteshelfDocument?
    
    private weak var cachePlistItem : FTRecognitionCachePlistItem?;
    private weak var visionCachePlistItem : FTVisionRecogCachePlistItem?;
    private var lastSavedTime : TimeInterval = 0;
    
    private var recognitionCacheRoot: FTFileItem = FTFileItem.init(url: FTRecognitionCache.recognitionCacheDirectory(), isDirectory: true)
    private var documentIDFolder: FTFileItem?
    private var languageCode: String = "en_US";
    
    private var scheduledSave = false;
    private var isDirty = false {
        didSet {
            DispatchQueue.main.async {[weak self] in
                guard let `self` = self else {
                    return
                }
                if(self.isDirty) {
                    if(!self.scheduledSave) {
                        self.perform(#selector(self.triggerSave), with: nil, afterDelay: MIN_SAVE_DURATION);
                        self.scheduledSave = true;
                    }
                }
                else {
                    self.scheduledSave = false;
                    NSObject.cancelPreviousPerformRequests(withTarget: self);
                }
            }
        }
    }
    
    private weak var recognitionCacheObserver: NSObjectProtocol?;
    required init(withDocument document:FTNoteshelfDocument, language: String?) {
        super.init();
        self.currentDocument = document
        self.languageCode = language ?? "en_US"
        self.addObserverForPlistReload(document.documentUUID);
    }
    
    deinit {
        if let observer = self.recognitionCacheObserver {
            NotificationCenter.default.removeObserver(observer);
        }
        
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self);
    }
    
    private func copyFileFromPackageToCache(forFileName fileName: String) {
        if(nil == self.currentDocument?.rootFileItem) {
            return
        }
        let folderItem = self.currentDocument?.rootFileItem.childFileItem(withName: RECOGNITION_FILES_FOLDER_NAME);
        if(folderItem != nil){
            let plistFileName = String.init(format: "%@_%@.plist", fileName, self.languageCode)
            let recognitionInfoURL = folderItem!.fileItemURL.appendingPathComponent(plistFileName)
            
            if(!FileManager.default.fileExists(atPath: recognitionInfoURL.path)) {
                return
            }
            if(self.documentIDFolder != nil){
                try? self.recognitionCacheRoot.writeUpdates(to: self.recognitionCacheRoot.fileItemURL)
                
                let cachePlistFileName = String.init(format: "%@_%@.plist", fileName, self.languageCode)
                let recognitionCacheURL = self.documentIDFolder!.fileItemURL.appendingPathComponent(cachePlistFileName)
                if FileManager.default.fileExists(atPath: recognitionCacheURL.path){
                    try? FileManager.default.removeItem(at: recognitionCacheURL)
                }
                try? FileManager.default.copyItem(at: recognitionInfoURL, to: recognitionCacheURL)
            }
        }
    }
    
    func recognitionCachePlist() -> FTRecognitionCachePlistItem?
    {
        var itemToReturn: FTRecognitionCachePlistItem?;
        self.recursiveLock.lock();
        let fileItem = self.getPlistFileItem(forFileName: RECOGNITION_INFO_FILE_NAME)
        if let cachedPlistItem = fileItem as? FTRecognitionCachePlistItem {
            self.cachePlistItem = cachedPlistItem
        }
        itemToReturn = self.cachePlistItem;
        self.recursiveLock.unlock();
        return itemToReturn;
    }
    
    private func getPlistFileItem(forFileName fileName: String) -> FTFileItemPlist? {
        guard let currentDoc = self.currentDocument, let rootFileItem = currentDoc.rootFileItem,
              (!self.languageCode.isEmpty && self.languageCode != languageCodeNone)  else {
            return nil;
        }
        if self.documentIDFolder == nil  {
            self.documentIDFolder = self.recognitionCacheRoot.childFileItem(withName: currentDoc.documentUUID);
            if(self.documentIDFolder == nil){
                self.documentIDFolder = FTFileItem.init(fileName: currentDoc.documentUUID, isDirectory: true)
                self.recognitionCacheRoot.addChildItem(self.documentIDFolder);
            }
        }
        //************************
        let plistFileName = String.init(format: "%@_%@.plist", fileName, self.languageCode)
        if fileName == RECOGNITION_INFO_FILE_NAME {
            if(cachePlistItem?.fileName == plistFileName) {
                return self.cachePlistItem;
            }
        }
        else {
            if(visionCachePlistItem?.fileName == plistFileName) {
                return self.visionCachePlistItem;
            }
        }
        //************************
        if let docUUIDFolder = self.documentIDFolder {
            var recognitionCachePlist = docUUIDFolder.childFileItem(withName: plistFileName) as? FTFileItemPlist;
            let cachePlistURL: URL = docUUIDFolder.fileItemURL.appendingPathComponent(plistFileName)
            
            if(!FileManager.default.fileExists(atPath: cachePlistURL.path)){
                self.copyFileFromPackageToCache(forFileName: fileName)
            }
            else{
                if let cachedFileAttributes = try? FileManager.default.attributesOfItem(atPath: cachePlistURL.path){
                    if let cachedFileModifiedDate = cachedFileAttributes[FileAttributeKey.modificationDate] as? Date {
                        let folderItem = rootFileItem.childFileItem(withName: RECOGNITION_FILES_FOLDER_NAME);
                        if(folderItem != nil){
                            let packagePlistURL = folderItem!.fileItemURL.appendingPathComponent(plistFileName)
                            if(FileManager.default.fileExists(atPath: packagePlistURL.path)){
                                if let packageFileAttributes = try? FileManager.default.attributesOfItem(atPath: packagePlistURL.path){
                                    //******Compare modified dates and swap plist********
                                    if let packageFileModifiedDate = packageFileAttributes[FileAttributeKey.modificationDate] as? Date {
                                        if(packageFileModifiedDate.compare(cachedFileModifiedDate) == .orderedDescending){
                                            self.copyFileFromPackageToCache(forFileName: fileName)
                                        }
                                    }
                                    //***********
                                }
                            }
                        }
                    }
                }
            }
            //************************
            if(nil == recognitionCachePlist) {
                if fileName == RECOGNITION_INFO_FILE_NAME {
                    recognitionCachePlist = FTRecognitionCachePlistItem.init(fileName: plistFileName)
                }
                else {
                    recognitionCachePlist = FTVisionRecogCachePlistItem.init(fileName: plistFileName)
                }
                docUUIDFolder.addChildItem(recognitionCachePlist);
            }
            return recognitionCachePlist;
            //************************
        }
        return nil
    }
    func updateLanguage(to langauge: String?) {
        if let lang = langauge {
            self.languageCode = lang;
        }
    }
    
    @objc private func triggerSave()
    {
        DispatchQueue.global().async {
            self.saveRecognitionInfoToDisk(forcibly: true);
        }
    }
    
    func saveRecognitionInfoToDisk(forcibly : Bool) {
        let currentTime = Date.timeIntervalSinceReferenceDate;
        let duration = currentTime - self.lastSavedTime;
        if(duration > MIN_SAVE_DURATION || forcibly) {
            self.isDirty = false;
            self.lastSavedTime = currentTime;
            do {
                try self.recognitionCacheRoot.writeUpdates(to: self.recognitionCacheRoot.fileItemURL!)
                if let docID = self.currentDocument?.documentUUID {
                    NotificationCenter.default.post(name: self.notificationName(docID),
                                                    object: self,
                                                    userInfo: nil);
                }
            }
            catch {
                
            }
        }
        else {
            self.isDirty = true;
        }
    }
    
    static func recognitionCacheDirectory() -> URL
    {
        let sharedGroupLocation = FileManager().containerURL(forSecurityApplicationGroupIdentifier: FTSharedGroupID.getAppGroupID());
        let libraryURL = sharedGroupLocation!.appendingPathComponent("Library", isDirectory: true);
        let cacheDirectory = libraryURL.appendingPathComponent("RecognitionCache", isDirectory: true);
        return cacheDirectory;
    }
    
    //
    private func addObserverForPlistReload(_ docID : String)
    {
        self.recognitionCacheObserver = NotificationCenter.default.addObserver(forName: self.notificationName(docID),
                                                                               object: nil,
                                                                               queue: nil) { [weak self] (not) in
            if let plistItem = not.object as? FTRecognitionCache,plistItem != self {
                self?.cachePlistItem?.unloadContentsOfFileItem();
            }
        }
    }
    
    private func notificationName(_ docID : String) -> NSNotification.Name
    {
        return NSNotification.Name(rawValue: "FTRecognitionCacheReload_\(docID)");
    }
}

extension FTRecognitionCache {
    func visionRecognitionCachePlist() -> FTVisionRecogCachePlistItem?
    {
        var itemToReturn: FTVisionRecogCachePlistItem?;
        self.recursiveLock.lock();
        let fileItem = self.getPlistFileItem(forFileName: VISION_RECOGNITION_INFO_FILE_NAME)
        if let cachedPlistItem = fileItem as? FTVisionRecogCachePlistItem {
            self.visionCachePlistItem = cachedPlistItem
        }
        itemToReturn = self.visionCachePlistItem;
        self.recursiveLock.unlock();
        return itemToReturn;
    }
}
