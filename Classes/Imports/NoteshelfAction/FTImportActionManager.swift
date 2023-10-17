//
//  FTImportActionManager.swift
//  Whink
//
//  Created by Simhachalam on 01/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let actionImportStatusDidUpdate = Notification.Name(rawValue: "FTImportStatusDidUpdate")
    static let actionDownloadDidFinish = Notification.Name(rawValue: "FTDownloadDidFinish")
    static let actionDownloadDidFail = Notification.Name(rawValue: "FTDownloadDidFail")
    static let actionImportDidFinish = Notification.Name(rawValue: "FTImportDidFinish")
    static let actionImportDidFail = Notification.Name(rawValue: "FTImportDidFail")

}

@objc class FTImportActionManager: NSObject {
    private var downloadQueue = OperationQueue()
    private var importQueue = OperationQueue()
    private var userDefaultsObserver : NSKeyValueObservation?
    @objc static let sharedInstance: FTImportActionManager = FTImportActionManager()
    
    override private init() {
        super.init()
        downloadQueue.name = "com.ft.ns3.download"
        importQueue.name = "com.ft.ns3.import"

        let sharedDefaults = FTUserDefaults.defaults()
        userDefaultsObserver = sharedDefaults.observe(\.userImportCount,
                                                      options: [.old, .new]) { [weak self] (userdefaults, context) in
                                                        self?.startProcessingAllActions();
        }
        
        self.downloadQueue.maxConcurrentOperationCount = 1
        self.importQueue.maxConcurrentOperationCount = 1
        
        NotificationCenter.default.addObserver(self, selector: #selector(FTImportActionManager.handleDidUpdateImportStatus(_:)),
                                               name: Notification.Name.actionImportStatusDidUpdate,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTImportActionManager.handleDidFinishDownload(_:)),
                                               name: NSNotification.Name.actionDownloadDidFinish,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTImportActionManager.handleDidFailDownload(_:)),
                                               name: NSNotification.Name.actionDownloadDidFail,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTImportActionManager.handleDidFinishImport(_:)),
                                               name: NSNotification.Name.actionImportDidFinish,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(FTImportActionManager.handleDidFailImport(_:)),
                                               name: NSNotification.Name.actionImportDidFail,
                                               object: nil)
    }
    
    deinit
    {
        userDefaultsObserver?.invalidate();
        userDefaultsObserver = nil;
        NotificationCenter.default.removeObserver(self);
    }
    
    func startProcessingAllActions()
    {
        FTImportStorageManager.clearImportFilesIfNeeded();
        var arActions = FTImportStorageManager.getReadyToImportActions()
        if(self.importQueue.operationCount == 0) {
            if let action = arActions.first {
                self.enqueueImportActions(action)
            }
        }

        if(self.downloadQueue.operationCount==0) {
            arActions = FTImportStorageManager.getAllPendingActions()
            if let action = arActions.first {
                self.enqueueDownloadActions(action)
            }
        }
    }
}

private extension FTImportActionManager {
    func enqueueDownloadActions(_ newAction:FTSharedAction){
        let operation = FTDownloadOperation.init(importAction: newAction);
        downloadQueue.addOperation(operation)
    }
    
    func enqueueImportActions(_ newAction:FTSharedAction){
        let operation = FTImportOperation.init(importAction: newAction)
        importQueue.addOperation(operation)
    }
}

//MARK: Notification Handlers
extension FTImportActionManager {
    @objc func handleDidUpdateImportStatus(_ notification:Notification){
        
    }
    
    @objc func handleDidFinishDownload(_ notification:Notification) {
        if let updatedAction:FTSharedAction = notification.object as? FTSharedAction {
            self.enqueueImportActions(updatedAction)
            self.startProcessingAllActions()
        }
    }
    
    @objc func handleDidFailDownload(_ notification:Notification){
        self.startProcessingAllActions()
    }
    
    @objc func handleDidFinishImport(_ notification:Notification){
        self.startProcessingAllActions()
    }
    
    @objc func handleDidFailImport(_ notification:Notification){
        self.startProcessingAllActions()
    }
}
