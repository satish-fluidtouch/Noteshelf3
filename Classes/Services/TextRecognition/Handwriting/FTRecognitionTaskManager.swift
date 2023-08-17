//
//  FTRecognitionTaskManager.swift
//  Noteshelf
//
//  Created by Naidu on 03/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRecognitionTaskManager: FTBackgroundTaskManager {
    static let shared:FTRecognitionTaskManager = FTRecognitionTaskManager()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(FTRecognitionTaskManager.handleLanguageChange(_:)), name: NSNotification.Name(rawValue: FTRecognitionLanguageDidChange), object: nil)
    }
    @objc fileprivate func handleLanguageChange(_ sender: Any){
        objc_sync_enter(self);
        self.taskList.removeAll()
        objc_sync_exit(self);
    }
    
    override internal func getTaskProcessor() -> FTBackgroundTaskProcessor{
        return FTRecognitionTaskProcessor.init(with: FTLanguageResourceManager.shared.currentLanguageCode ?? "en_US")
    }
    internal override func canExecuteTask(_ task: FTBackgroundTask) -> Bool{
        if let newTask = task as? FTRecognitionTask {
            return (newTask.currentDocument != nil)
        }
        return false
    }
    internal override func dispatchQueueID() -> String{
        return "com.fluidtouch.handWritingRecognition"
    }

}
