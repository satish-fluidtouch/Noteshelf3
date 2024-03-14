//
//  FTRecognitionServicerProvider.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 06/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRecognitionServiceProvider: NSObject {
    static let shared = FTRecognitionServiceProvider()
    private var runningServices: [String: FTNotebookRecognitionHelper] = [:]
    private var visionRunningServices: [String: FTVisionNotebookRecognitionHelper] = [:]
    
    func getRecognitionService(forDocument document: FTNoteshelfDocument) -> FTNotebookRecognitionHelper? {
        NotificationCenter.default.post(name: UIApplication.releaseRecognitionHelperNotification, object: nil)
        if runningServices[document.documentUUID] != nil {
            #if DEBUG
                debugPrint("ALREADY EXIST: runningServices: \(runningServices)")
            #endif
            return nil
        }
        let helper = FTNotebookRecognitionHelper.init(withDocument: document)
        runningServices[helper.documentUUID] = helper

        #if DEBUG
           // debugPrint("runningServices: \(runningServices)")
        #endif

        return helper
    }
    
    func clearRecognitionHelper(_ helper: FTNotebookRecognitionHelper) {
        self.runningServices.removeValue(forKey: helper.documentUUID);
        #if DEBUG
           // debugPrint("runningServices: \(runningServices)")
        #endif
    }
}
extension FTRecognitionServiceProvider {
    func getVisionRecognitionService(forDocument document: FTNoteshelfDocument) -> FTVisionNotebookRecognitionHelper? {
        NotificationCenter.default.post(name: UIApplication.releaseVisionRecognitionHelperNotification, object: nil)
        if visionRunningServices[document.documentUUID] != nil {
            #if DEBUG
                debugPrint("ALREADY EXIST: visionRunningServices: \(runningServices)")
            #endif
            return nil
        }
        let helper = FTVisionNotebookRecognitionHelper.init(withDocument: document)
        visionRunningServices[helper.documentUUID] = helper

        #if DEBUG
            //debugPrint("visionRunningServices: \(visionRunningServices)")
        #endif

        return helper
    }
    
    func clearVisionRecognitionHelper(_ helper: FTVisionNotebookRecognitionHelper) {
        self.visionRunningServices.removeValue(forKey: helper.documentUUID);
        #if DEBUG
            //debugPrint("visionRunningServices: \(visionRunningServices)")
        #endif
    }
}
