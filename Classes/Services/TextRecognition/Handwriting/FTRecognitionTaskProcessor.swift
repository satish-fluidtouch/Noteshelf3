//
//  FTRecognitionTaskProcessor.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTScriptEvent: NSObject{
    var type: UInt = 0 //0 -> down 1 -> moved 2 -> up
    var point: CGPoint = CGPoint.zero
}
private let maxAllowedRecognitionPoints : Int = 400_000;
private var dictUniqueRecogEventDict: [String : TimeInterval] = [:];

private extension Helper {
    static func defaultDPI() -> Float {
#if targetEnvironment(macCatalyst)
        return Helper.kDpiPad/Float(UIScreen.main.scale)
#else
        return Helper.scaledDpi()
#endif
    }
}

class FTRecognitionTaskProcessor: NSObject {
    var languageCode: String!
    var canAcceptNewTask: Bool = true

    fileprivate var editor: IINKEditor?
    private var engineErrorMessage: String?
    private var fontMetricsProvider: FontMetricsProvider!
    private var recognitionPackage: FTRecognitionPackage?
    
    private lazy var engine: IINKEngine? = {
        // Check that the MyScript certificate is present
        if myCertificate.length == 0
        {
            self.engineErrorMessage = "Please replace the content of MyCertificate.c with the certificate you received from the developer portal"
            return nil
        }
        
        // Create the iink runtime environment
        let data = Data(bytes: myCertificate.bytes, count: myCertificate.length)
        guard let engine = IINKEngine(certificate: data) else
        {
            self.engineErrorMessage = "Invalid certificate"
            return nil
        }
        
        return engine
    }()
        
    deinit {
        self.recognitionPackage = nil
        self.editor?.part = nil
    }

    required init(with langCode: String) {
        super.init()
        self.languageCode = langCode
    }
    
    fileprivate func createEditorWRTLanguage(){
        let configurationPath = Bundle.languageConfigurationPath(forLanguage: self.languageCode)
        if (configurationPath == nil) {// In case of an on-demand resource purged
            FTLanguageResourceManager.shared.currentLanguageCode = "en_US";
        }
        else{
            try? self.engine?.configuration.set(stringArray: [configurationPath!], forKey: "configuration-manager.search-path")
            try? self.engine?.configuration.set(string: NSTemporaryDirectory(), forKey: "content-package.temp-folder")
            try? self.engine?.configuration.set(string: self.languageCode, forKey: "lang")
        }
        self.initializeRecognitionProcessor()
    }
    
    private func initializeRecognitionProcessor() {
        if(self.editor == nil){
            do{
                guard let renderer = try self.engine?.createRenderer(dpiX: Helper.defaultDPI(), dpiY: Helper.defaultDPI(), target: nil) else {
                    print("Error: Unable to create the MyScript Renderer")
                    return
                }
                self.editor = self.engine?.createEditor(renderer: renderer, toolController: nil)
                self.fontMetricsProvider = FontMetricsProvider();
                self.editor?.set(fontMetricsProvider: self.fontMetricsProvider)
                try? self.editor?.set(viewSize: CGSize.init(width: 768, height: 960))
                self.editor?.part = nil
                self.recognitionPackage = FTRecognitionPackage.init(with: self.editor, engine: self.engine)
                self.recognitionPackage?.assignPartToEditor()
            }
            catch{
                print("Myscript Exception", error)
            }
        }
        
        let conf: IINKConfiguration? = self.engine?.configuration;
        let horizontalMarginMM: Double = 0;
        let verticalMarginMM: Double = 0;
        try? conf?.set(boolean: true, forKey: "export.jiix.text.chars")
        try? conf?.set(boolean: false, forKey: "text.guides.enable")
        
        try? conf?.set(number: verticalMarginMM, forKey: "text.margin.top")
        try? conf?.set(number: verticalMarginMM, forKey: "text.margin.left")
        try? conf?.set(number: verticalMarginMM, forKey: "text.margin.right")
        try? conf?.set(number: verticalMarginMM, forKey: "text.margin.bottom")
        
        try? conf?.set(number: horizontalMarginMM, forKey: "math.margin.top")
        try? conf?.set(number: horizontalMarginMM, forKey: "math.margin.left")
        try? conf?.set(number: horizontalMarginMM, forKey: "math.margin.right")
        try? conf?.set(number: horizontalMarginMM, forKey: "math.margin.bottom")
    }
}

extension FTRecognitionTaskProcessor: FTBackgroundTaskProcessor {
    private func updateRecognitionLanguage(_ languageCode: String){
        self.languageCode = languageCode
        self.editor = nil
    }
    
    func startTask(_ task: FTBackgroundTask, onCompletion: (() -> (Void))?){
        self.canAcceptNewTask = false
        if let currentTask = task as? FTRecognitionTask{
            if(currentTask.languageCode != self.languageCode){
                self.updateRecognitionLanguage(currentTask.languageCode)
            }
            var error: NSError?
            let result: FTRecognitionResult? = self.getRecognitionText(for: currentTask.pageAnnotations,
                                                                       viewSize: currentTask.viewSize,
                                                                       error: &error);
            self.canAcceptNewTask = true
            onCompletion?()
            currentTask.onCompletion?(result, error)
        }
        else{
            onCompletion?()
            //ToDo:: Return Error
        }
    }
    
    private func getRecognitionText(for annotations: [FTAnnotationProtocol],
                                    viewSize:CGSize,
                                    error:inout NSError?) -> FTRecognitionResult? {
//        var t1 : TimeInterval?
        #if DEBUG
        //debugPrint("Engine Started")
        //t1 = Date.timeIntervalSinceReferenceDate
        #endif
        let events = self.generateEvents(for: annotations);
        //FTCLSLog("Page Recognition Started: Points \(events.count)")
        //FTLanguageResourceManager.shared.writeLogString("Stroke Count: \(String(describing: events.count))", currentDocument: nil)
        if events.isEmpty {
            let recognitionData = FTRecognitionResult()
            recognitionData.recognisedString = ""
            recognitionData.languageCode = self.languageCode
            recognitionData.characterRects = []
            recognitionData.lastUpdated = NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double)
            return recognitionData
        }
        
        if let annotation = annotations.last as? FTAnnotation,
            let page = annotation.associatedPage,
            let documentUUID = page.parentDocument?.documentUUID {
            let pageUUID = page.uuid;
            let key = "\(pageUUID)-\(documentUUID)"
            let currentTime = Date.timeIntervalSinceReferenceDate

            DispatchQueue.global().async {
                let timestamp = dictUniqueRecogEventDict[key] ?? 0;
                if((currentTime - timestamp) >= 60*60) {
                    dictUniqueRecogEventDict[key] = currentTime
                }
            }
        }
        if(nil == editor) {
            createEditorWRTLanguage();
        }
        //If engine got certificate error
        guard let editor = self.editor else {
            error = NSError(domain: "Editor Error", code: 101, userInfo: nil);
            return nil;
        }
        editor.clear()
        try? editor.set(viewSize: CGSize(width: viewSize.width, height: viewSize.height))
        #if DEBUG
        //let t2 = Date.timeIntervalSinceReferenceDate
        //debugPrint("For Loop End: \(t2-t1!)")
        #endif
        FTObjCMethods.finishBulkEvents(events.count, events: events, andEditor: self.editor);
        #if DEBUG
        //let t3 = Date.timeIntervalSinceReferenceDate
        //debugPrint("Time: \(t3-t1!)")
        #endif
        do {
            let jsonString: String? = try editor.export(selection: IINKContentBlock(), mimeType: IINKMimeType.JIIX)
            if let data = jsonString?.data(using: .utf8),
               let jsonDict = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:Any]
            {
                let arrayChars = jsonDict["chars"] as? [[String:Any]]
                let recognitionData = FTRecognitionResult()
                let fullString = jsonDict["label"] as? String
                recognitionData.recognisedString = fullString ?? ""
                let transform = editor.renderer.viewTransform
                
                var characterRects: [CGRect] = []
                arrayChars?.forEach({ (dictChar) in
                    if let boundingBox = dictChar["bounding-box"] as? [String: CGFloat] {
                        var charRect = CGRect.zero

                        charRect.origin.x = boundingBox["x"] ?? 0;
                        charRect.origin.y = boundingBox["y"] ?? 0;
                        charRect.size.width = boundingBox["width"] ?? 0;
                        charRect.size.height = boundingBox["height"] ?? 0;

                        let transformedRect = charRect.applying(transform)
                        characterRects.append(transformedRect)
                    }
                    else{
                        characterRects.append(CGRect.zero)
                    }
                })
                recognitionData.characterRects = characterRects
                recognitionData.languageCode = self.languageCode
                recognitionData.lastUpdated = NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double)
                return recognitionData
            }
            else {
                return nil
            }
        }
        catch let _error as NSError {
            #if DEBUG
            debugPrint(_error)
            #endif
            return nil
        }    }
}

private extension FTRecognitionTaskProcessor {
    func generateEvents(for annotations: [FTAnnotationProtocol]) -> [FTScriptEvent]
    {
        #if DEBUG
        var segmentCountOriginal: Int = 0;
        var segmentCountOptimized: Int = 0;
        #endif
        var events = [FTScriptEvent]();
        annotations.forEach { (eachItem) in
            if let stroke = eachItem as? FTStroke,
               !stroke.penType.isHighlighterPenType() {
                let optimizedSegments = stroke.segmentArray;
                //let optimizedSegments = SwiftSimplify.simplify(stroke.segmentArray, tolerance: .good, highQuality:true)
                #if DEBUG
                segmentCountOriginal += stroke.segmentArray.count;
                segmentCountOptimized += optimizedSegments.count;
                #endif

                let segmentCount = optimizedSegments.count;
                
                var isStartingPoint: Bool = true;
                var endingPoint: CGPoint = CGPoint.zero;
                //************************
                if (segmentCount > 0){
                    for iCount in 0..<segmentCount {
                        let segmentsArray = optimizedSegments;
                        let segment = segmentsArray[iCount];
                        let isErased = segment.isErased
                        let capturePoint = CGPoint(ftpoint: segment.startPoint);
                        if (
                            isErased == true
                            //|| !segment!.pointee.isControlSegment
                            )
                        {
                            if (isStartingPoint){
                                continue
                            }
                            else
                            {
                                
                            }
                        }
                        if (isStartingPoint){
                            isStartingPoint = false
                            let scriptPoint = FTScriptEvent.init()
                            scriptPoint.point = capturePoint
                            scriptPoint.type = 0
                            events.append(scriptPoint);
                        }
                        else
                        {
                            let scriptPoint = FTScriptEvent.init()
                            scriptPoint.point = capturePoint
                            scriptPoint.type = 1
                            events.append(scriptPoint);
                        }
                        endingPoint = capturePoint;
                    }
                    if(isStartingPoint == false){
                        let scriptPoint = FTScriptEvent.init()
                        scriptPoint.point = endingPoint
                        scriptPoint.type = 2
                        events.append(scriptPoint);
                    }
                    //************************
                }
            }
        }
        
        //added below check to avoid crash due to more number of points. limiting the points to
        if(events.count > maxAllowedRecognitionPoints) {
//            FTCLSLog("Recognitions: Points \(events.count)")
            let count = events.count - maxAllowedRecognitionPoints;
            events = Array(events.dropLast(count));
            events.last?.type = 2;
        }
        return events;
    }
}
