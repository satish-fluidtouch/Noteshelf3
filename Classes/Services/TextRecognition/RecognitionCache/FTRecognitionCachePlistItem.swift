//
//  FTRecognitionCachePlistItem.swift
//  Noteshelf
//
//  Created by Naidu on 24/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTRecognitionCachePlistItem: FTFileItemPlist {
    private let currentVersion: String = "1.0"
    private var recognitionResult = [String : FTRecognitionResult]();

    override init(fileName: String!) {
        super.init(fileName: fileName);
    }

    override init(fileName: String!, isDirectory isDir: Bool) {
        super.init(fileName: fileName, isDirectory: isDir);
    }
    
    override init!(url: URL!, isDirectory isDir: Bool) {
        super.init(url: url, isDirectory: isDir);
    }

    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    override func loadContentsOfFileItem() -> Any! {
        let item = super.loadContentsOfFileItem() as? NSMutableDictionary;
        if(nil == item?["version"]) {
            item?["version"] = currentVersion;
        }
        return item;
    }
    
    override func unloadContentsOfFileItem() {
        objc_sync_enter(self);
        super.unloadContentsOfFileItem();
        self.recognitionResult = [String : FTRecognitionResult]();
        objc_sync_exit(self);
    }
        
    func getRecognitionInfo(forPage page: FTPageProtocol) -> FTRecognitionResult? {
        objc_sync_enter(self);
        var recogInfo : FTRecognitionResult? = self.recognitionResult[page.uuid];
        if(nil == recogInfo) {
            if let recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any],
               let pageDict = recogInfoDict[page.uuid] as? [String : Any] {
                recogInfo = FTRecognitionResult.init(withDictionary: pageDict)
                self.recognitionResult[page.uuid] = recogInfo;
            }
        }
        objc_sync_exit(self);
        return recogInfo;
    }
    
    func setRecognitionInfo(forPageID pageID: String, recognitionInfo: FTRecognitionResult?) {
        objc_sync_enter(self);
        if let recInfo = recognitionInfo {
            self.recognitionResult[pageID] = recInfo;
            var recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any];
            if recogInfoDict == nil{
                recogInfoDict = [String : Any]()
            }
            recogInfoDict![pageID] = recInfo.dictionaryRepresentation()
            self.setObject(recogInfoDict, forKey: "pageRecognitionInfo");
        }
        else {
            self.deleteRecognitionInfo(pageID);
        }
        objc_sync_exit(self);
    }
    
    func deleteRecognitionInfo(_ pageID:String)
    {
        self.recognitionResult.removeValue(forKey: pageID)
        var recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any]
        if recogInfoDict != nil {
            recogInfoDict?.removeValue(forKey: pageID)
            self.setObject(recogInfoDict, forKey: "pageRecognitionInfo");
        }
    }
}

