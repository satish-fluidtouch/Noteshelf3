//
//  FTImportOperation.swift
//  Whink
//
//  Created by Simhachalam on 01/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation

class FTImportOperation: Operation {
    private var currentAction : FTSharedAction
    var taskExecuting:Bool = true {
        willSet{
            self.willChangeValue(forKey: "isFinished");
        }
        didSet {
            self.didChangeValue(forKey: "isFinished");
        }
    }
    
    override var isFinished: Bool
    {
        return !self.taskExecuting;
    }
    
    required init(importAction : FTSharedAction)
    {
        currentAction=importAction
        super.init()
    }
    
    override func main() {
        self.createDocument(self.currentAction)
    }
    
    private func createDocument(_ newAction:FTSharedAction) {
        guard let importhandler = self.importIntentHandler() else {
            self.taskExecuting=false
            return;
        }
        
        let fileURl = URL(fileURLWithPath:newAction.fileURL);
        let item = FTImportItem(item: fileURl as AnyObject) {(shelfItem, success) in
            if success {
                if let item = shelfItem {
                    self.currentAction.importStatus = FTImportStatus.importSuccess
                    self.currentAction.fileName = item.displayTitle
                    self.currentAction.documentUrlHash = item.URL.path
                }
                else {
                    self.currentAction.importStatus = FTImportStatus.importFailed
                }
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: self.currentAction.fileURL))
            }
            else{
                self.currentAction.importStatus = FTImportStatus.importFailed
            }
            FTImportStorageManager.updateImportAction(self.currentAction)
            self.taskExecuting = false
            NotificationCenter.default.post(name: NSNotification.Name.actionImportStatusDidUpdate, object: self.currentAction)
            if(self.currentAction.importStatus == .importFailed) {
                NotificationCenter.default.post(name: NSNotification.Name.actionImportDidFail, object: self.currentAction)
            }
            else {
                NotificationCenter.default.post(name: NSNotification.Name.actionImportDidFinish, object: self.currentAction)
            }
        }
        item.imporItemInfo = FTImportItemInfo(collection: newAction.collectionName ?? "", group: newAction.groupName ?? "", notebook: newAction.notebook ?? "")
        item.openOnImport = false;
        importhandler.importItem(item);
    }

    private func importIntentHandler() -> FTIntentHandlingProtocol?
    {
        var rootController: FTIntentHandlingProtocol?;
        let dg = DispatchGroup();
        dg.enter()
        DispatchQueue.main.async{
            if #available(iOS 13.0, *) {
                if let windowSceneDelegate = UIApplication.shared.firstForegroundScene()?.delegate as? UIWindowSceneDelegate {
                    rootController = windowSceneDelegate.window??.rootViewController as? FTIntentHandlingProtocol;
                }
            } else {
                rootController = UIApplication.shared.delegate?.window??.rootViewController as? FTIntentHandlingProtocol;
            }
            dg.leave();
        }
        dg.wait();
        return rootController;
    }
}
