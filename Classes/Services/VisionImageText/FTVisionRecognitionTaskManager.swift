//
//  FTVisionRecognitionTaskManager.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 25/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTVisionRecognitionTaskManager: FTBackgroundTaskManager {
    static let shared:FTVisionRecognitionTaskManager = FTVisionRecognitionTaskManager()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    override init() {
        super.init()
    }
    override internal func getTaskProcessor() -> FTBackgroundTaskProcessor{
        return FTVisionRecognitionTaskProcessor.init(with: FTVisionLanguageMapper.currentISOLanguageCode())
    }
    internal override func canExecuteTask(_ task: FTBackgroundTask) -> Bool{
        if let newTask = task as? FTVisionRecognitionTask {
            return (newTask.currentDocument != nil)
        }
        return false
    }
    internal override func dispatchQueueID() -> String{
        return "com.fluidtouch.visionTextRecognition"
    }
}

class FTVisionLanguageMapper: NSObject {
    static func currentISOLanguageCode() -> String {
        var deviceISOCode = "en"
        let supportedLangCodes = ["en", "zh", "ja", "it", "fr", "es", "de"]
        if let currentLangCode = Locale.current.language.languageCode?.identifier {
            if supportedLangCodes.contains(currentLangCode) {
                deviceISOCode = currentLangCode
            }
        }
        return deviceISOCode
    }
}
