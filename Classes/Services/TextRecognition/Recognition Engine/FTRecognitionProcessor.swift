//
//  FTRecognitionTaskProcessor.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
class FTScriptEvent: NSObject{
    var type: UInt = 0 //0 -> down 1 -> moved 2 -> up
    var point: CGPoint = CGPoint.zero
}
private let maxAllowedRecognitionPoints : Int = 500000;

class FTRecognitionTaskProcessor: NSObject {
    fileprivate var editor: IINKEditor?
    private var engineErrorMessage: String?
    var languageCode: String!
    private var partIdentifier: String!
    private var fontMetricsProvider: FontMetricsProvider!
    var canAcceptNewTask: Bool = true
    
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
        self.editor?.part = nil
        FTPackageNamePool.shared.removePackageIdentifier(self.partIdentifier)
        if(nil != self.partIdentifier) {
            self.engine?.deletePackage(self.partIdentifier, error: nil)
        }
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    required init(with languageCode: String?) {
        super.init()
        self.languageCode = languageCode
        self.createEditorWRTLanguage()
    }
    fileprivate func createEditorWRTLanguage(){
        let configurationPath = Bundle.languageConfigurationPath(forLanguage: self.languageCode)
        if (configurationPath == nil) {// In case of an on-demand resource purged
            FTLanguageResourceManager.shared.currentLanguageCode = "en_US";
        }
        else{
            try? self.engine?.configuration.setStringArray([configurationPath!], forKey: "configuration-manager.search-path")
            try? self.engine?.configuration.setString(NSTemporaryDirectory(), forKey: "content-package.temp-folder")
            try? self.engine?.configuration.setString(self.languageCode, forKey: "lang")
        }
        self.partIdentifier = FTPackageNamePool.shared.getPackageIdentifier();
        self.initializeRecognitionProcessor()
    }
    
    private func initializeRecognitionProcessor(){
        if(self.editor == nil){
            let renderer: IINKRenderer?
            do{
                renderer = try self.engine?.createRenderer(withDpiX: scaledDpi(), dpiY: scaledDpi(), target: nil, error: ())
                self.editor = self.engine?.createEditor(renderer!)
                self.fontMetricsProvider = FontMetricsProvider();
                self.editor?.setFontMetricsProvider(self.fontMetricsProvider)
                self.editor?.setViewSize(CGSize.init(width: 768, height: 960), error: nil)
                self.editor?.part = nil
                self.assignPartToEditor()
            }
            catch{
                
            }
        }
        
        let conf: IINKConfiguration? = self.engine?.configuration;
        let horizontalMarginMM: Double = 0;
        let verticalMarginMM: Double = 0;
        try? conf?.setBoolean(true, forKey: "export.jiix.text.chars")
        try? conf?.setBoolean(false, forKey: "text.guides.enable")
        
        try? conf?.setNumber(verticalMarginMM, forKey: "text.margin.top")
        try? conf?.setNumber(verticalMarginMM, forKey: "text.margin.left")
        try? conf?.setNumber(verticalMarginMM, forKey: "text.margin.right")
        try? conf?.setNumber(verticalMarginMM, forKey: "text.margin.bottom")
        
        try? conf?.setNumber(horizontalMarginMM, forKey: "math.margin.top")
        try? conf?.setNumber(horizontalMarginMM, forKey: "math.margin.left")
        try? conf?.setNumber(horizontalMarginMM, forKey: "math.margin.right")
        try? conf?.setNumber(horizontalMarginMM, forKey: "math.margin.bottom")
    }
    private func assignPartToEditor(){
        var package: IINKContentPackage?
        do{
            package = try self.engine?.openPackage(self.partIdentifier)
        }
        catch{
            do{
                package = try self.createPackage(withName: self.partIdentifier)
            }
            catch{
                self.editor?.part = nil
                return
            }
        }
        do{
            self.editor?.part = try package!.getPartAt(0)
        }
        catch{
            
        }
    }
    private func createPackage(withName packageName: String) throws -> IINKContentPackage?
    {
        var resultPackage: IINKContentPackage?
        let fullPath = FileManager.default.pathForFile(inDocumentDirectory: packageName) + ".iink"
        if let engine = self.engine {
            resultPackage = try engine.createPackage(fullPath.decomposedStringWithCanonicalMapping)
            // Add a blank page type Text Document
            if let part = try resultPackage?.createPart("Text") /* Options are : "Diagram", "Drawing", "Math", "Text Document", "Text" */ {
                print(part.identifier)
            }
        }
        return resultPackage
    }
}

extension FTRecognitionTaskProcessor: FTTaskProcessorProtocol {
    private func updateRecognitionLanguage(_ languageCode: String){
        self.languageCode = languageCode
        self.editor = nil
        self.createEditorWRTLanguage()
    }
    func startRecognitionWithTask(_ task: FTTaskProtocol, onCompletion: (()->(Void))?){
        if(self.languageCode != FTLanguageResourceManager.shared.currentLanguageCode){
            self.updateRecognitionLanguage(FTLanguageResourceManager.shared.currentLanguageCode!)
        }
        self.canAcceptNewTask = false
        if let currentTask = task as? FTRecognitionTask{
            let result: FTRecognitionResult? = self.getRecognitionText(forAnnotations: currentTask.pageAnnotations!, viewSize: currentTask.viewSize)
            self.canAcceptNewTask = true
            onCompletion?()
            currentTask.onCompletion?(result, nil)
        }
        else{
            onCompletion?()
            //ToDo:: Return Error
        }
    }
    
    private func getRecognitionText(forAnnotations annotations: [AnyObject], viewSize:CGSize) -> FTRecognitionResult? {
        var events : [FTScriptEvent] = [];
        var totalPoints:Int = 0
        var segmentCountOriginal: Double = 0;
        var segmentCountOptimized: Double = 0;

        var t1 : TimeInterval?
        
        #if DEBUG
        debugPrint("Engine Started")
        t1 = Date.timeIntervalSinceReferenceDate
        #endif
        annotations.forEach { (eachItem) in
            #if TARGET_OS_SIMULATOR
            let annotation = eachItem as! FTAnnotation;
            var shouldProcessAnnotation = false;
            if(annotation.annotationType == FTAnnotationType.stroke && !isHighlighterPen((annotation as! FTStroke).penType)) {
                shouldProcessAnnotation = true;
            }
            #else
            var shouldProcessAnnotation = false;
            let annotation = eachItem as! FTAnnotationV2;
            if let stroke = eachItem as? FTStrokeV2, !stroke.penType.isHighlighterPenType() {
                shouldProcessAnnotation = true;
            }
            #endif
            if(shouldProcessAnnotation) {
                #if TARGET_OS_SIMULATOR
                let strokeAnnotation = annotation as! FTStroke
                let segmentCount = strokeAnnotation.segmentCount;

                #else
                let strokeAnnotation = annotation as! FTStrokeV2
                segmentCountOriginal = (segmentCountOriginal + Double(strokeAnnotation.segmentArray.count))
                //let optimizedSegments = strokeAnnotation.segmentArray;
                let optimizedSegments = SwiftSimplify.simplify(strokeAnnotation.segmentArray, tolerance: .good, highQuality:true)

                segmentCountOptimized = (segmentCountOptimized + Double(optimizedSegments.count))
                let segmentCount = optimizedSegments.count;

                #endif
                
                var isStartingPoint: Bool = true;
                var endingPoint: CGPoint = CGPoint.zero;
                //************************
                if (segmentCount > 0){
                    for iCount in 0...segmentCount-1 {
                        #if TARGET_OS_SIMULATOR
                        let segment = strokeAnnotation.getSegmentAt(UInt(iCount))
                        let erasedSegment = strokeAnnotation.getTransientSegment(at: UInt(iCount))
                        let isErased = erasedSegment?.pointee.erased.boolValue;
                        let capturePoint = CGPoint.init(x: CGFloat(segment!.pointee.startPoint.x), y: CGFloat(segment!.pointee.startPoint.y))
                        #else
                        let segmentsArray = optimizedSegments;
                        let segment = segmentsArray[iCount];
                        let isErased = strokeAnnotation.isErasedSegment(segment, index: iCount);
                        let capturePoint = CGPoint.init(ftpoint: segment.startPoint);
                        #endif
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
                        totalPoints = totalPoints + 1
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
        FTLanguageResourceManager.shared.writeLogString("Stroke Count: \(String(describing: events.count))", currentDocument: nil)
        if(events.count == 0){
            let recognitionData = FTRecognitionResult()
            recognitionData.recognisedString = ""
            recognitionData.languageCode = self.languageCode
            recognitionData.characterRects = []
            recognitionData.lastUpdated = NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double)
            return recognitionData
        }
        //added below check to avoid crash due to more number of points. limiting the points to
        if(events.count > maxAllowedRecognitionPoints) {
            let logString = "Points: \(events.count)";
            FTUtils.cls_Log_Swift(logString)
            let count = events.count - maxAllowedRecognitionPoints;
            events = Array(events.dropLast(count));
            events.last?.type = 2;
        }
        self.editor?.clear()
        self.editor?.setViewSize(CGSize.init(width: viewSize.width, height: viewSize.height), error: nil)
        
        #if DEBUG
        let t2 = Date.timeIntervalSinceReferenceDate
        debugPrint("For Loop End: \(t2-t1!)")
        debugPrint("segmentCountOriginal: \(segmentCountOriginal) segmentCountOptimized: \(segmentCountOptimized)")

        #endif
        FTObjCMethods.finishBulkEvents(events.count, events: events, andEditor: self.editor);
        #if DEBUG
        let t3 = Date.timeIntervalSinceReferenceDate
        debugPrint("Time: \(t3-t1!)")
        #endif
        do
        {
            let jsonString: String? = try self.editor?.export_(IINKContentBlock(), mimeType: IINKMimeType.JIIX)
            
            if let data = jsonString?.data(using: .utf8), let jsonDict = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any>
            {
                let arrayChars = jsonDict["chars"] as! [Dictionary<String, Any>]
                let recognitionData = FTRecognitionResult()
                let fullString = jsonDict["label"] as? String
                recognitionData.recognisedString = fullString ?? ""
                let transform = self.editor!.renderer.viewTransform
                
                var characterRects: [CGRect] = []
                arrayChars.forEach({ (dictChar) in
                    if let boundingBox = dictChar["bounding-box"] as? Dictionary<String, Any>{
                        var charRect = CGRect.init()
                        charRect.origin.x = CGFloat((boundingBox["x"]! as! NSNumber).floatValue)
                        charRect.origin.y = CGFloat((boundingBox["y"]! as! NSNumber).floatValue)
                        charRect.size.width = CGFloat((boundingBox["width"]! as! NSNumber).floatValue)
                        charRect.size.height = CGFloat((boundingBox["height"]! as! NSNumber).floatValue)
                        
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
            else
            {
                return nil
            }
        }
        catch let error as NSError {
            #if DEBUG
            debugPrint(error)
            #endif
            return nil
        }
    }
}
