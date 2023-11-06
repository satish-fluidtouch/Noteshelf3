//
//  FTVisionNotebookRecognitionHelper.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 25/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTVisionNotebookRecognitionHelper: NSObject {
    var documentUUID = UUID().uuidString;
    weak var currentDocument: FTNoteshelfDocument?
    private var isRecognitionInProgress: Bool = false
    
    private let visionRecogQueue = DispatchQueue.init(label: "com.fluitouch.visionRecog",
                                                      qos: .background,
                                                      attributes: [],
                                                      autoreleaseFrequency: .inherit,
                                                      target: nil);
    deinit {
        NotificationCenter.default.removeObserver(self)
        #if DEBUG
        //debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    @objc static var shouldProceedRecognition : Bool {
        if FTUserDefaults.isInSafeMode() {
            return false
        }
        
        if let langCode = FTLanguageResourceManager.shared.currentLanguageCode,
           langCode != languageCodeNone,
           Self.supportsImageToTextRecognition() {
            return true
        }
        return false
    }
    
    convenience init(withDocument document:FTNoteshelfDocument) {
        self.init()
        self.documentUUID = document.documentUUID;
        self.currentDocument = document
    }
    
    func startImageTextRecognition(){
        if (self.isRecognitionInProgress == true ||  FTVisionNotebookRecognitionHelper.shouldProceedRecognition == false
            || FTUserDefaults.isInSafeMode()){
            return
        }
        self.isRecognitionInProgress = true
        self.visionRecogQueue.async {[weak self] in
            var pageToProcess : FTPageProtocol?;
            if let allPages = self?.currentDocument?.pages(), allPages.isEmpty == false {
                for iCount in 0...allPages.count-1 {
                    if let eachPage = allPages[iCount] as? FTNoteshelfPage, eachPage.canRecognizeVisionText {
                        pageToProcess = eachPage
                        break
                    }
                    if #available(iOS 13.0, *) {
                        //added below line as a temproary fix for memory increase issue while accessing the string from PDFPage due to iOS13. Hence adding runloop to make sure os gets some time to release the memory.
                        RunLoop.current.run(until: Date().addingTimeInterval(0.1));
                    }
                }
            }
            if(nil != pageToProcess) {
                let bgTask = startBackgroundTask();
                let lastUpdatedDate = pageToProcess?.lastUpdated;
                
                let task: FTVisionRecognitionTask = FTVisionRecognitionTask()
                task.languageCode = FTVisionLanguageMapper.currentISOLanguageCode()
                task.currentDocument = self?.currentDocument
                task.viewSize = pageToProcess!.pdfPageRect.size
                if let page = pageToProcess{
                    if let image = page.pdfPageRef?.thumbnail(of: task.viewSize, for: PDFDisplayBox.cropBox) {
                        task.imageToProcess = image
                    }
                }
                
                //********When recognition finished********
                task.onCompletion = {[weak self] (info, error) -> (Void) in
                    self?.isRecognitionInProgress = false
                    endBackgroundTask(bgTask);
                    if let weakSelf = self, weakSelf.currentDocument != nil {
                        if error != nil{
                            return
                        }
                        if(nil != lastUpdatedDate) {
                            info?.lastUpdated = lastUpdatedDate;
                        }
                        #if DEBUG
                        //debugPrint("FTVisionNotebookRecognitionHelper \(info?.recognisedString ?? "NULL")")
                        #endif
                        if info == nil{ //If engine error
                            FTLanguageResourceManager.shared.writeLogString("Vision API Error:: \(pageToProcess!.pageIndex() + 1)", currentDocument: self?.currentDocument)
                            return
                        }
                        else {
                            pageToProcess?.visionRecognitionInfo = info
                        }
                        weakSelf.startImageTextRecognition()
                    }
                }
                //********
                FTVisionRecognitionTaskManager.shared.addBackgroundTask(task)
            }
            else {
                self?.isRecognitionInProgress = false;
            }
        }
    }
    
    @objc func wakeUpVisionRecognitionHelperIfNeeded(){
        if self.isRecognitionInProgress == false {
            if #available(iOS 13.0, *) {
                self.startImageTextRecognition()
            }
        }
    }

    static func supportsImageToTextRecognition() -> Bool {
// We're disabling recognition forcefully for the mac catalyst
#if targetEnvironment(macCatalyst)
        return false
#else
        return true
#endif
    }
}
