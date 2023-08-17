//
//  FTVisionRecogCachePlistItem.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 25/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTVisionRecogCachePlistItem: FTFileItemPlist {
    private let currentVersion: String = "1.0"
    private var recognitionResult = [String : FTVisionRecognitionResult]();

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
    private func uniqueKeyForPage(_ page: FTPageProtocol) -> String{
        if let pdfName = page.associatedPDFFileName {
            return "\(pdfName)_\(page.associatedPDFKitPageIndex)"
        }
        return ""
    }
    override func unloadContentsOfFileItem() {
        objc_sync_enter(self);
        super.unloadContentsOfFileItem();
        self.recognitionResult = [String : FTVisionRecognitionResult]();
        objc_sync_exit(self);
    }
        
    func getRecognitionInfo(forPage page: FTPageProtocol) -> FTVisionRecognitionResult? {
        objc_sync_enter(self);
        let uniquePageID = self.uniqueKeyForPage(page)
        var recogInfo : FTVisionRecognitionResult? = self.recognitionResult[uniquePageID];
        
        if(nil == recogInfo) {
            let recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any]
            if (recogInfoDict != nil){
                let pageDict: [String : Any]? = recogInfoDict![uniquePageID] as? [String : Any]
                if pageDict != nil{
                    recogInfo = FTVisionRecognitionResult.init(withDictionary: pageDict!)
                    self.recognitionResult[uniquePageID] = recogInfo;
                }
            }
        }
        objc_sync_exit(self);
        return recogInfo;
    }
    
    func setRecognitionInfo(forPage page: FTPageProtocol, recognitionInfo: FTVisionRecognitionResult?) {
        objc_sync_enter(self);
        let uniquePageID = self.uniqueKeyForPage(page)
        if let recInfo = recognitionInfo {
            self.recognitionResult[uniquePageID] = recInfo;
            var recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any];
            if recogInfoDict == nil{
                recogInfoDict = [String : Any]()
            }
            recogInfoDict![uniquePageID] = recInfo.dictionaryRepresentation()
            self.setObject(recogInfoDict, forKey: "pageRecognitionInfo");
        }
        else {
            self.deleteRecognitionInfo(uniquePageID);
        }
        objc_sync_exit(self);
    }
    
    func deleteRecognitionInfo(_ uniquePageID:String)
    {
        self.recognitionResult.removeValue(forKey: uniquePageID)
        var recogInfoDict = self.object(forKey: "pageRecognitionInfo") as? [String : Any]
        if recogInfoDict != nil {
            recogInfoDict?.removeValue(forKey: uniquePageID)
            self.setObject(recogInfoDict, forKey: "pageRecognitionInfo");
        }
    }
}
