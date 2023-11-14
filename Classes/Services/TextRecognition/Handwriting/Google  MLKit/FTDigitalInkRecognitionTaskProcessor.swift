//
//  FTDigitalInkRecognitionTaskProcessor.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
import MLKit
#endif

class FTDigitalInkRecognitionManager: NSObject {
    static let shared = FTDigitalInkRecognitionManager();
    func configure() {
#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
        if let inkModel = self.digitalINkModel(for: FTUtils.currentLanguage()),!inkModel.isDownloaded {
            inkModel.startDownloading();
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.inkModelDownloadSuccess(_:)), name: .mlkitModelDownloadDidSucceed, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.inkModelDownloadSuccess(_:)), name: .mlkitModelDownloadDidFail, object: nil);
#endif
    }
    
#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
    @objc private func inkModelDownloadSuccess(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? DigitalInkRecognitionModel {
            debugPrint("mlKitLangiage dowbloaded: \(model)")
        }
    }
    
    @objc private func inkModelDownloadFailed(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? DigitalInkRecognitionModel {
            debugPrint("mlKitLangiage failed: \(model)")
        }
    }
    func digitalINkModel(for language: String, considerRegion: Bool = true, pickDefaultIfNotAvailable: Bool = true) -> DigitalInkRecognitionModel? {
        var inkModel: DigitalInkRecognitionModel?;

        var curLang = language;
        if considerRegion, let regionCode = NSLocale.current.region?.identifier {
            curLang = curLang.appending("-\(regionCode)");
        }
        if let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: curLang) {
            inkModel = DigitalInkRecognitionModel.init(modelIdentifier: identifier);
        }
        else if let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: language) {
            inkModel = DigitalInkRecognitionModel.init(modelIdentifier: identifier);
        }
        else if pickDefaultIfNotAvailable
                    ,let identifier = DigitalInkRecognitionModelIdentifier(forLanguageTag: "en_us") {
            inkModel = DigitalInkRecognitionModel.init(modelIdentifier: identifier);
        }
        return inkModel;
    }
#endif
}

class FTDigitalInkRecognitionTaskProcessor: NSObject,FTRecognitionProcessor {
    private var language = "en";
#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
    private var recognizer: DigitalInkRecognizer?;
#endif
    
    required init(with langCode: String) {
        language = langCode;
    }
    
    func startTask(_ task: FTBackgroundTask, onCompletion: (() -> (Void))?){
        guard let currentTask = task as? FTRecognitionTask else {
            fatalError("task should be of FTRecognitionTask");
        }
#if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
        onCompletion?();
        currentTask.onCompletion?(nil,nil);
#else
        self.getRecognitionText(for: currentTask.pageAnnotations
                                , viewSize: currentTask.viewSize) { result, error in
            onCompletion?();
            currentTask.onCompletion?(result,error as? NSError);
        }
#endif
    }
}

#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
private extension FTDigitalInkRecognitionTaskProcessor {
    func getRecognitionText(for annotations: [FTAnnotationProtocol],
                            viewSize:CGSize,
                            onCompletion :@escaping (FTRecognitionResult?,Error?)->()) {
        
        let recognitionData = FTRecognitionResult();
        recognitionData.lastUpdated = NSNumber(value: Date.timeIntervalSinceReferenceDate);
        
        guard let model = FTDigitalInkRecognitionManager.shared.digitalINkModel(for: language), model.isDownloaded else {
            FTDigitalInkRecognitionManager.shared.configure();
            onCompletion(recognitionData,nil);
            return;
        }
                
        let events = self.generateEvents(annotations);
        if !events.isEmpty {
            let options = DigitalInkRecognizerOptions(model: model)
            recognizer = DigitalInkRecognizer.digitalInkRecognizer(options: options);
            
            let ink = Ink(strokes: events)
            
            let writingArea = WritingArea(width: Float(viewSize.width), height: Float(viewSize.height));
            let context = DigitalInkRecognitionContext(preContext: "", writingArea: writingArea)
            
            recognizer?.recognize(ink: ink,context: context) { recognitionResult, error in
                if let result = recognitionResult, let candidate = result.candidates.first {
                    recognitionData.recognisedString = candidate.text;
                    recognitionData.lastUpdated = NSNumber(value: Date.timeIntervalSinceReferenceDate)
                }
                onCompletion(nil == error ? recognitionData : nil ,error);
            }
        }
        else {
            onCompletion(recognitionData,nil);
        }
    }
    
    func generateEvents(_ annotations: [FTAnnotationProtocol]) -> [Stroke]
    {
        var events = [Stroke]();
        annotations.forEach { (eachItem) in
            if let stroke = eachItem as? FTStroke, !stroke.penType.isHighlighterPenType() {
                let segmentsArray = stroke.segmentArray;
                let segmentCount = segmentsArray.count;
                var endingPoint: FTPoint?;
                
                //************************
                if (segmentCount > 0){
                    var strokePoints = [StrokePoint]();
                    
                    for iCount in 0..<segmentCount {
                        let segment = segmentsArray[iCount];
                        let capturePoint = segment.startPoint;
                        if (segment.isErased) {
                            if !strokePoints.isEmpty {
                                if let endPoint = endingPoint {
                                    let point = StrokePoint(x: endPoint.x, y: endPoint.y);
                                    strokePoints.append(point);
                                }
                                events.append(Stroke(points: strokePoints));
                                strokePoints.removeAll();
                            }
                            endingPoint = nil;
                        }
                        else {
                            let point = StrokePoint(x: capturePoint.x, y: capturePoint.y);
                            strokePoints.append(point);
                            endingPoint = segment.endPoint;
                        }
                    }
                    if !strokePoints.isEmpty {
                        if let endPoint = endingPoint {
                            let point = StrokePoint(x: endPoint.x, y: endPoint.y);
                            strokePoints.append(point);
                        }
                        events.append(Stroke(points: strokePoints));
                    }
                    //************************
                }
            }
        }
        return events;
    }
}
#endif

#if !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
extension DigitalInkRecognitionModel {
    var isDownloaded: Bool {
        return ModelManager.modelManager().isModelDownloaded(self);
    }
    
    func startDownloading() {
        let condition = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true);
        ModelManager.modelManager().download(self, conditions: condition);
    }
}
#endif
