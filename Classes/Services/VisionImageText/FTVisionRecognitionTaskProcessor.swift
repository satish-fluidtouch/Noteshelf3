//
//  FTVisionRecognitionTaskProcessor.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 25/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Vision

typealias FTRequestCompletionHandler = (FTVisionRecognitionResult?, Error?) -> Void

class FTVisionRecognitionTaskProcessor: NSObject {
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var completionHandler: FTRequestCompletionHandler?

    var canAcceptNewTask: Bool = true
    private var languageCode: String = "en";

    private var viewSize: CGSize = CGSize.zero
    
    required init(with langCode: String) {
        super.init();
        self.languageCode = langCode
        self.textRecognitionRequest = VNRecognizeTextRequest(completionHandler: {[weak self] (request, _) in
            guard let `self` = self else {
                return
            }
                // Update transcript view.
            if let results = request.results as? [VNRecognizedTextObservation] {
                var recognisedText: String = ""
                var charRects: [CGRect] = [CGRect]()
                var wordRects: [CGRect] = [CGRect]()
                
                for eachLineObservation in results {
                    if(!recognisedText.isEmpty) {
                        recognisedText.append("\n")
                        charRects.append(CGRect.zero)
                    }

                    let eachLine: VNRecognizedText = eachLineObservation.topCandidates(1)[0]
                    let eachLineString = eachLine.string
                    recognisedText.append(eachLineString)

                    var prevWordRect = CGRect.zero
                    for i in 0...eachLineString.count - 1 {
                        let charRange : NSRange = NSRange.init(location: i, length: 1);
                        if let newRange = Range.init(charRange, in: eachLineString) {
                            let observation = try? eachLine.boundingBox(for: newRange)
                            if let charObservation = observation {
                                let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.viewSize.height)
                                let translate = CGAffineTransform.identity.scaledBy(x: self.viewSize.width, y: self.viewSize.height)
                                let originalRect = charObservation.boundingBox.applying(translate).applying(transform)
                                if originalRect.size.equalTo(CGSize.zero) == false {//Check if it is not a space character
                                    prevWordRect = originalRect
                                    wordRects.append(originalRect)
                                }
                                if originalRect.size.equalTo(CGSize.zero) //If char is space OR line ending reached
                                   || i == (eachLineString.count - 1) {
                                    if prevWordRect.equalTo(CGRect.zero) {
                                        prevWordRect = originalRect
                                    }
                                    var XPosition: CGFloat = prevWordRect.origin.x
                                    let eachCharWidth = prevWordRect.width / CGFloat(wordRects.count)
                                    //Word's width equally deviding to each character [WORKAROUND for Apple API issue]
                                    wordRects.forEach { (eachRect) in
                                        var adjustedRect = eachRect
                                        adjustedRect.origin.x = XPosition
                                        adjustedRect.size.width = eachCharWidth
                                        charRects.append(adjustedRect)
                                        XPosition += eachCharWidth
                                    }
                                    if originalRect.size.equalTo(CGSize.zero) {
                                        charRects.append(originalRect)
                                    }
                                    wordRects.removeAll()
                                    prevWordRect = CGRect.zero
                                }
                            }
                        }
                    }
                }

                let result: FTVisionRecognitionResult = FTVisionRecognitionResult()
                result.recognisedString = recognisedText
                result.characterRects = charRects
                result.languageCode = langCode
                self.completionHandler?(result, nil)
            }
        });

        self.textRecognitionRequest?.recognitionLevel = .fast
        // Update language-based correction.
        self.textRecognitionRequest?.usesLanguageCorrection = false
        self.textRecognitionRequest?.recognitionLanguages = [FTVisionLanguageMapper.currentISOLanguageCode()]
    }
    deinit {
        #if DEBUG
        debugPrint("deinit \(self.classForCoder)");
        #endif
    }
    
    func recognizeText(forImage image:UIImage?, onCompletion: FTRequestCompletionHandler?){
        guard let newImage = image else { return }

        self.textRecognitionRequest?.cancel()
        self.viewSize = newImage.size

        if let cgImage = newImage.cgImage {
            self.completionHandler = onCompletion
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            if let textRecogResult = self.textRecognitionRequest {
                do {
                    try requestHandler.perform([textRecogResult])
                }
                catch {
                    self.completionHandler = nil;
                    onCompletion?(nil, NSError.init(domain: "FTVisionRecognitionError", code: 103, userInfo: nil))
                }
            }
        } else {
            // Clean up Vision objects
            onCompletion?(nil, NSError.init(domain: "FTVisionRecognitionError", code: 102, userInfo: nil))
        }
    }
}

extension FTVisionRecognitionTaskProcessor: FTBackgroundTaskProcessor {
    func startTask(_ task: FTBackgroundTask, onCompletion: (() -> (Void))?) {
        if FTUserDefaults.isInSafeMode() {
            onCompletion?()
            return
        }

        self.canAcceptNewTask = false
        if let currentTask = task as? FTVisionRecognitionTask{
            self.canAcceptNewTask = true
            self.recognizeText(forImage: currentTask.imageToProcess) {(result, error) in
                onCompletion?()
                currentTask.onCompletion?(result, error as NSError?)
            }
        }
        else{
            onCompletion?()
            //ToDo:: Return Error
        }
    }
}
