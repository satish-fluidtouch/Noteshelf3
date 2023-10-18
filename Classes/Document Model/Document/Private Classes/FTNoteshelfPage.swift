//
//  FTNoteshelfPage.swift
//  Noteshelf
//
//  Created by Amar on 25/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
#if !targetEnvironment(macCatalyst)
import EvernoteSDK
#endif
#endif
import PDFKit
import FTDocumentFramework
import MobileCoreServices
import FTCommon

enum FTPDFContent: Int {
    case unknown,hasContent,noContent;
}

@objcMembers class FTPageSearchingInfo: NSObject {
    var searchKey: String = ""
    internal var searchItems: [FTSearchableItem]?
    var pageUUID: String!
}

class FTNoteshelfPage : NSObject, FTPageProtocol
{
    private(set) var pageBackgroundColor: UIColor?;
    private var searchLock = DispatchSemaphore(value: 1);
    var zoomTargetOrigin = CGPoint.zero;
    var isCover: Bool = false
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    fileprivate var tileMapAnnotations = [FTTileMap]();
    #endif
    internal var searchingInfo: FTPageSearchingInfo? {
        didSet {
            if(nil == searchingInfo && nil == oldValue) {
                return;
            }
            runInMainThread {
                let notificationString = "DidChangeSearchResults_".appending(self.uuid);
                NotificationCenter.default.post(name: Notification.Name.init(notificationString), object: self, userInfo: nil);
            }
        }
    }

    private var documentUUID:  String = FTUtils.getUUID();
    fileprivate var _uuid : String = FTUtils.getUUID();
    fileprivate weak var _parent : FTNoteshelfDocument?;
    fileprivate var _tags = NSMutableOrderedSet()
    fileprivate var _pageRect : CGRect = CGRect.null; //Only for migrated Notebooks
    fileprivate var _pdfPageRect : CGRect = CGRect.null; //Used to store PDF Page Rect when PDFKit was not used
    fileprivate var _pdfKitPageRect : CGRect = CGRect.null; //Used to store PDF Page Rect when PDFKit is used
    fileprivate var _bookmarkTitle : String = "";
    fileprivate var _bookmarkColor : String = "C69C3C";
    fileprivate var isInitializationInprogress = false;

    fileprivate var pageTemplateFileItem : FTPDFKitFileItemPDF?;
    
    var lineHeight : Int = Int(34) {
        didSet {
            if(!self.isInitializationInprogress) {
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
            }
        }
    };
    
    var bottomMargin: Int = 0;
    var topMargin: Int = 0;
    var leftMargin: Int = 0;

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    fileprivate var pageSqliteFileItem : FTNSqliteAnnotationFileItem?;
    fileprivate var _pageThumbnail : FTPageThumbnail!;

    //***********************PAGE RECOGNITION***************
    private var _recognitionInfo : FTRecognitionResult?;
    var recognitionInfo : FTRecognitionResult? {
        get {
            guard let recognitionDocument = self.parentDocument as? FTRecognitionHelper else {
                return nil;
            }
            let fileItem = recognitionDocument.recognitionCache?.recognitionCachePlist();
            return  fileItem?.getRecognitionInfo(forPage: self);
        }
        set {
            guard let recognitionDocument = self.parentDocument as? FTRecognitionHelper else {
                return;
            }
            let fileItem = recognitionDocument.recognitionCache?.recognitionCachePlist();
            fileItem?.setRecognitionInfo(forPageID: self.uuid, recognitionInfo: newValue);
            recognitionDocument.recognitionCache?.saveRecognitionInfoToDisk(forcibly: false);
        }
    }
    private var _visionRecognitionInfo : FTVisionRecognitionResult?;
    var visionRecognitionInfo : FTVisionRecognitionResult? {
        get {
            guard let recognitionDocument = self.parentDocument as? FTRecognitionHelper else {
                return nil;
            }
            let fileItem = recognitionDocument.recognitionCache?.visionRecognitionCachePlist();
            return  fileItem?.getRecognitionInfo(forPage: self);
        }
        set {
            guard let recognitionDocument = self.parentDocument as? FTRecognitionHelper else {
                return;
            }
            let fileItem = recognitionDocument.recognitionCache?.visionRecognitionCachePlist();
            fileItem?.setRecognitionInfo(forPage: self, recognitionInfo: newValue);
            recognitionDocument.recognitionCache?.saveRecognitionInfoToDisk(forcibly: false);
        }
    }
    @objc var canRecognizeHandwriting: Bool{
        var canRecognize = false
        let recognitionInfo = self.recognitionInfo
        if(nil == recognitionInfo) {
            canRecognize = true;
        }
        else if(recognitionInfo!.languageCode != FTLanguageResourceManager.shared.currentLanguageCode) {
            canRecognize = true;
        }
        else if let recogLastUpdated = recognitionInfo?.lastUpdated,
            let selfUpdated = self.lastUpdated,
            recogLastUpdated.doubleValue != selfUpdated.doubleValue {
            canRecognize = true;
        }
        return canRecognize
    }
    
    var canRecognizeVisionText: Bool {
        var canRecognize = false
        if self.hasPDFText() {
            return canRecognize
        }
        let visionRecognitionInfo = self.visionRecognitionInfo
        if(nil == visionRecognitionInfo || visionRecognitionInfo?.lastUpdated == nil) {
            canRecognize = true;
        }
        else if(visionRecognitionInfo!.languageCode != FTVisionLanguageMapper.currentISOLanguageCode()) {
            canRecognize = true;
        }
        return canRecognize
    }

    //*****************************************************
    #endif
    var isFirstPage : Bool = false;
    var isPageModified : Bool = false;
    var hasContents: FTPDFContent = .unknown;
    
    var associatedPDFPageIndex : Int = 0;
    var associatedPDFKitPageIndex : UInt {
        var value = self.associatedPDFPageIndex-1;
        if(value < 0) {
            FTLogError("Unexpected", attributes: ["Reason" : "Invalid Page Index","Page Index" : self.associatedPDFPageIndex])
            value = 0;
        }
        return UInt(value);
    }
    
    var associatedPDFFileName : String? {
        didSet {
            if(!self.isInitializationInprogress) {
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
            }
            if(oldValue != nil) {
                self.pageBackgroundColor = nil;
            }
            hasContents = .unknown;
        }
    };
    
    fileprivate var pdfKitPageRect : CGRect {
        get {
            if(!_pdfKitPageRect.isNull) {
                return _pdfKitPageRect;
            }
            if(!_pdfPageRect.isNull) {
                self.pdfKitPageRect = _pdfPageRect;
                return self.pdfKitPageRect;
            }
            let rect = self.getPDFKitPageRect();
            if(!rect.isNull) {
                self.pdfKitPageRect = rect;
            }
            return _pdfKitPageRect;
        }
        set {
            _pdfKitPageRect = newValue;
        }
    }
    
    private func getPDFKitPageRect() -> CGRect
    {
        var rect = CGRect.null;
        let fileItem = self.templateFileItem();
        if(nil != fileItem) {
            if(self.templateInfo.version.floatValue > Float(0)) {
                rect = fileItem!.pageRectOfPage(atNumber: self.associatedPDFKitPageIndex);
            }
            else {
                let cgPDFPageRef = self.pdfPageRef?.pageRef;
                var pageRect = UIScreen.main.bounds;
                if(nil != cgPDFPageRef) {
                    pageRect = cgPDFPageRef!.getBoxRect(CGPDFBox.mediaBox);
                    if(pageRect.size.width > 0 && pageRect.size.height > 0) {
                        let transform = cgPDFPageRef!.getDrawingTransform(CGPDFBox.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true);
                        pageRect = pageRect.applying(transform);
                    }
                }
                pageRect.origin = CGPoint.zero;
                rect = pageRect;
            }
        }
        return rect;
    }
    
    func pdfscale(inRect: CGRect) -> CGFloat {
        var scale : CGFloat = 1;
        if(self.templateInfo.version.floatValue == 0) {
            let pageRect = self.pdfPageRect;
            if(!pageRect.isNull) {
                scale = inRect.width/pageRect.size.width;
            }
            return scale;
        }
        else {
            if(!_pdfPageRect.isNull) {
                let pageRect = self.getPDFKitPageRect();
                if(!pageRect.isNull) {
                    scale = inRect.width/pageRect.width;
                }
            }
            else {
                let pageRect = self.pdfPageRect;
                if(!pageRect.isNull) {
                    scale = inRect.width/pageRect.size.width;
                }
            }
        }
        return scale;
    }
    
    var deviceModel : String = FTUtils.deviceModel();
    
    var creationDate : NSNumber! = NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double);
    var lastUpdated : NSNumber! = NSNumber.init(value: Date.timeIntervalSinceReferenceDate as Double) {
        didSet{
            if(!self.isInitializationInprogress) {
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
            }
        }
    };
    
    var isBookmarked : Bool = false{
        didSet{
            if(!self.isInitializationInprogress) {
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
            }
        }
    };
    var bookmarkTitle : String!{
        get{
            return _bookmarkTitle
        }
        set {
            _bookmarkTitle = newValue
        }
    };
    var bookmarkColor : String!{
        get{
            if(_bookmarkColor.uppercased() == "8ACCEA"){ // This will check for older bookmarked color code and returns new bookmarked color
                return "C69C3C"
            }
            return _bookmarkColor
        }
        set {
            _bookmarkColor = newValue
        }
    };

    var isDirty : Bool = false {
        didSet{
            if isDirty == true{
                self.isPageModified = true
                self.parentDocument?.isDirty = true
            }
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            
            if(!self.isInitializationInprogress) {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FTPageDidUpdatedPropertiesNotification), object: self);
            }
            if(isDirty == true && !self.isInitializationInprogress) {
                let annotationFileItem = self.sqliteFileItem();
                if(nil != annotationFileItem) {
                    annotationFileItem!.annotations = annotationFileItem!.annotations;
                    self.lastUpdated = Date.timeIntervalSinceReferenceDate as NSNumber;
                }
            }
            if isDirty {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(generateThumbnail), object: nil);
                self.perform(#selector(generateThumbnail), with: nil, afterDelay: 1.5)
            }
//            if isDirty == true{
//                self._parent =?.recognitionManager?.wakeUpRecognitionHelperIfNeeded()
//            }
            #endif
        }
    }
    
    var uuid : String {
        return _uuid;
    };
    
    var parentDocument : FTDocumentProtocol? {
        return _parent;
    };
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @objc private func generateThumbnail(){
        self.thumbnail()?.shouldGenerateThumbnail = true
        self.thumbnail()?.thumbnailImage(onUpdate: { image, string in})
    }
    #endif

    var pdfPageRef : PDFPage? {
        var pageRefToReturn : PDFPage?;
        objc_sync_enter(self);
        if((self.associatedPDFFileName != nil) && (self.parentDocument != nil))
        {
            let fileItem = self.templateFileItem();
            if(fileItem != nil) {
                pageRefToReturn = fileItem!.pdfPageRef(atPageNumber: self.associatedPDFKitPageIndex);
            }
        }
        objc_sync_exit(self);
        return pageRefToReturn;
    };
    
    var pdfPageRect : CGRect {
        get{
            var pageRectToReturn = CGRect.zero;
            if(!self._pageRect.isNull) {
                pageRectToReturn =  self._pageRect;
            }
            else if(!self.pdfKitPageRect.isNull) {
                pageRectToReturn = self.pdfKitPageRect;
            }
            
            if(pageRectToReturn.equalTo(CGRect.zero)) {
                let tempFileName = self.associatedPDFFileName;
                FTCLSLog("template file item :\(String(describing: tempFileName)) is nil");
                if(nil == self.parentDocument) {
                    FTCLSLog("parent document is nil");
                }
                else {
                    FTCLSLog("file path: \(String(describing: self.parentDocument?.URL.path))");
                    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                    let annotation = self.annotations().filter({ (annotation) -> Bool in
                        return annotation.isReadonly;
                    });
                    
                    if annotation.isEmpty == false {
                        FTCLSLog("Migrated noteboook book from NS1");
                    }
                    else if(!self._pageRect.isNull) {
                        FTCLSLog("Migrated PDF book from NS1");
                    }
                    #endif
                    if(nil == self._parent?.templateFolderItem()) {
                        FTCLSLog("Template folder is nil");
                    }
                    else {
                        let childrens = self._parent!.templateFolderItem()!.children;
                        childrens?.forEach({ (fileItem) in
                            let fileName = (fileItem as? FTFileItem)?.fileName ?? " - ";
                            FTCLSLog("Template fileItem: \(fileName)");
                        });
                    }
                }
                pageRectToReturn = CGRect(x: 0, y: 0, width: 768, height: 960);
                self.pdfKitPageRect = pageRectToReturn;
            }
            if self.rotationAngle > 0 {
                pageRectToReturn = pageRectToReturn.rotate(by: self.rotationAngle)
                pageRectToReturn.origin = .zero
            }
            return pageRectToReturn;
        }
        set {
            if(self.pdfKitPageRect != newValue) {
                self.pdfKitPageRect = newValue;
                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !TARGET_OS_SIMULATOR
                     populateTileMaps(true)
                 #endif
            }
        }
    };

    var undoManager: UndoManager? {
        return self.parentDocument?.undoManager
    }

    var rotationAngle: UInt = 0 {
        didSet {
            if(!self.isInitializationInprogress) {                
                NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
            }
        }
    }

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func rotate(by angle: UInt) {
        if angle.isMultiple(of: 90) && angle <= 270 {
            rotationAngle = (rotationAngle + UInt(angle))%360
            self.thumbnail()?.shouldGenerateThumbnail = true

            //This is to update the transparent cover of the book, if the user has rotated the page but not written anything on it.
            if self.isFirstPage {
                self.isPageModified = true
            }
            //Temporarily we're removing all the searching info, once we rotate the page.
            //This should be properly handled by transforming the search results.
            searchingInfo = nil
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION && !TARGET_OS_SIMULATOR
                 populateTileMaps(true)
             #endif
        } else {
            FTDebugLog.log("⚠️ Invalid Angle provided for page rotation")
        }
    }
    #endif

    func resetRotation() {
        self.rotationAngle = 0
    }

    var pageCurrentIndex: Int = -1;
    
    func pageIndex() -> Int
    {
        return pageCurrentIndex;
    }
    
    //MARK:- Life cycle -
    convenience init(parentDocument : FTNoteshelfDocument) {
        self.init();
        self._parent = parentDocument;
        self.documentUUID = parentDocument.documentUUID;
    }
    
    deinit {
        self.searchLock.signal();
        NotificationCenter.default.post(name: Notification.Name(rawValue: FTPageDidGetReleasedNotification), object: self);
    }
    
    internal func copyPageAttributes() -> FTNoteshelfPage
    {
        guard let parentDoc = self.parentDocument as? FTNoteshelfDocument else { fatalError("Parent document is nil")}
        let newPage = FTNoteshelfPage(parentDocument: parentDoc);
        newPage.isInitializationInprogress = true;
        newPage.associatedPDFFileName = self.associatedPDFFileName;
        newPage.associatedPDFPageIndex = self.associatedPDFPageIndex;
        newPage.isCover = self.isCover
        
        newPage.lineHeight = self.lineHeight;
        newPage.bottomMargin = self.bottomMargin;
        newPage.topMargin = self.topMargin;
        newPage.leftMargin = self.leftMargin;

        newPage.pageBackgroundColor = self.pageBackgroundColor;
        newPage.pdfKitPageRect = self.pdfKitPageRect;
        newPage._pageRect = self._pageRect;
        newPage.isInitializationInprogress = false;
        newPage.hasContents = self.hasContents;
        return newPage;
    }
    
    //MARK:- Content Read/Write -
    func updatePageAttributesWithDictionary(_ dict : [String : Any])
    {
        self.isInitializationInprogress = true;
        if let uuid = dict["uuid"] as? String {
            _uuid = uuid
        }
        isBookmarked = (dict["isBookmarked"] as? NSNumber)?.boolValue ?? false;
        isCover = (dict["isCover"] as? NSNumber)?.boolValue ?? false;

        if let _bookmarkTitle = dict["bookmarkTitle"] as? String {
            self.bookmarkTitle = _bookmarkTitle
        }
        if let _bookmarkColor = dict["bookmarkColor"] as? String {
            self.bookmarkColor = _bookmarkColor
        }
        
        let arr = dict["tags"] as? [String] ?? [String]()
        self._tags = NSMutableOrderedSet.init(array: arr)
        creationDate = dict["creationDate"] as? NSNumber;
        
        if let _lastUpdated = dict["lastUpdated"] as? NSNumber {
            self.lastUpdated = _lastUpdated
        }

        if let pageRectPDFKit = dict["pdfKitPageRect"] as? String {
            _pdfKitPageRect = NSCoder.cgRect(for: pageRectPDFKit);
        }
        

        if let pageRect = dict["pdfPageRect"] as? String {
            _pdfPageRect = NSCoder.cgRect(for: pageRect);
            _pdfKitPageRect = _pdfPageRect;
        }
        if let pageIndex = dict["associatedPageIndex"] as? NSNumber {
            associatedPDFPageIndex = pageIndex.intValue;
        }
        associatedPDFFileName = dict["associatedPDFFileName"] as? String;
        if let _deviceModel = dict["deviceModel"] as? String {
            deviceModel = _deviceModel
        }

        if let value = dict["pageRect"] as? String {
            self._pageRect = NSCoder.cgRect(for: value);
        }
        
        if let pageLineheight = dict["lineHeight"] as? NSNumber {
            self.lineHeight = pageLineheight.intValue;
        }

        if let bottomMargin = dict["bottomMargin"] as? NSNumber {
            self.bottomMargin = bottomMargin.intValue;
        }
        if let topMargin = dict["topMargin"] as? NSNumber {
            self.topMargin = topMargin.intValue;
        }
        if let leftMargin = dict["leftMargin"] as? NSNumber {
            self.leftMargin = leftMargin.intValue;
        }

        if let pageLineheight = dict["rotationAngle"] as? NSNumber {
            self.rotationAngle = pageLineheight.uintValue;
        }

        //TODO: For temporarily the condition to check if the color is 000000 added to avoid the ios15 issue where the clear color was sent when asked for the page background color. We can remove this after few release.
        if let bgColor = dict["pageBGColor"] as? String, bgColor != "000000" {
            self.pageBackgroundColor = UIColor(hexString: bgColor)
        }
        
        if let hasContent = dict["hasPDFContent"] as? NSNumber, let content = FTPDFContent(rawValue: hasContent.intValue) {
            self.hasContents = content;
        }
        self.isInitializationInprogress = false;
    }
    
    func dictionaryRepresentation() -> [String : Any]
    {
        var dictRep = [String : Any]();
        
        dictRep["associatedPDFFileName"] = self.associatedPDFFileName as AnyObject?;
        dictRep["associatedPageIndex"] = NSNumber.init(value: self.associatedPDFPageIndex as Int);
        dictRep["deviceModel"] = self.deviceModel as AnyObject?;
        dictRep["creationDate"] = self.creationDate;
        dictRep["lastUpdated"] = self.lastUpdated;
        dictRep["tags"] = self.tags() as AnyObject?;
        dictRep["uuid"] = self.uuid as AnyObject?;
        dictRep["isBookmarked"] = NSNumber.init(value: self.isBookmarked as Bool);
        dictRep["isCover"] = NSNumber.init(value: self.isCover as Bool);

        dictRep["bookmarkTitle"] = self.bookmarkTitle
        dictRep["bookmarkColor"] = self.bookmarkColor
        dictRep["rotationAngle"] = self.rotationAngle
        
        if let color = self.pageBackgroundColor?.hexString {
             dictRep["pageBGColor"] = color
        }
        
        if(!self._pageRect.isNull) {
            dictRep["pageRect"] = NSCoder.string(for: self._pageRect);
        }
        if(!_pdfPageRect.isNull) {
            dictRep["pdfPageRect"] = NSCoder.string(for: _pdfPageRect);
        }
        if(!_pdfKitPageRect.isNull) {
            dictRep["pdfKitPageRect"] = NSCoder.string(for: _pdfKitPageRect);
        }
        dictRep["lineHeight"] = lineHeight;

        if bottomMargin > 0 {
            dictRep["bottomMargin"] = bottomMargin;
        }

        if topMargin > 0 {
            dictRep["topMargin"] = topMargin;
        }

        if leftMargin > 0 {
            dictRep["leftMargin"] = leftMargin;
        }
        if self.hasContents != .unknown {
            dictRep["hasPDFContent"] = NSNumber(integerLiteral: self.hasContents.rawValue);
        }
        return dictRep;
    }
    
    //MARK:- Page Size/Ref scale -
    func pageReferenceViewSize() -> CGSize
    {
        let pageRect = self.pdfPageRect;
        var minSize = pageRect.size;
        
        if(!self._pageRect.isNull) {
            let v1ProtraitRect = CGRect.init(x: 0, y: 0, width: 768, height: 1024-44-20);
            let v1LandscapeRect = CGRect.init(x: 0, y: 0, width: 1024, height: 768-44-20);
            
            if(pageRect.size.width > pageRect.size.height)
            {
                //landscape so get portrait value
                minSize = aspectFittedRect(pageRect, v1ProtraitRect).size;
            }
            else
            {
                //portrait so get landscape value
                minSize = aspectFittedRect(pageRect, v1LandscapeRect).size;
            }
        }
        return minSize;
    }
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    //MARK:- File Items -
    internal func sqliteFileItem() -> FTNSqliteAnnotationFileItem?
    {
        let annotationFolder = self._parent?.annotationFolderItem();
        if(nil == self.parentDocument || nil == annotationFolder) {
            return nil;
        }
        objc_sync_enter(self);
        if(nil != self.pageSqliteFileItem && nil == self.pageSqliteFileItem!.parent) {
            self.pageSqliteFileItem = nil;
        }

        if(nil == self.pageSqliteFileItem) {
            var annotationsFileItem = annotationFolder?.childFileItem(withName: self.sqliteFileName()) as? FTNSqliteAnnotationFileItem;
            if(nil == annotationsFileItem)
            {
                annotationsFileItem = FTNSqliteAnnotationFileItem.init(fileName : self.sqliteFileName()) as FTNSqliteAnnotationFileItem;
                annotationsFileItem?.securityDelegate = self._parent;
                annotationFolder!.addChildItem(annotationsFileItem);
            }
            annotationsFileItem?.associatedPage = self;
            self.pageSqliteFileItem = annotationsFileItem;
        }
        objc_sync_exit(self);
        return self.pageSqliteFileItem;
    }
    #endif
    fileprivate func templateFileItem() -> FTPDFKitFileItemPDF?
    {
        guard let tempalteFileName = self.associatedPDFFileName else {
            FTCLSLog("Template file name is nil");
            return nil;
        }
        objc_sync_enter(self);
        let rawTempalteFileName = "rawenc-".appending(tempalteFileName);
        if(nil != self.pageTemplateFileItem && nil == self.pageTemplateFileItem!.parent) {
            self.pageTemplateFileItem = nil;
        }
        
        if((nil == self.pageTemplateFileItem) ||
            ((self.pageTemplateFileItem!.fileName != tempalteFileName) && (self.pageTemplateFileItem!.fileName != rawTempalteFileName))
            )
        {
            let parentDocument = (self.parentDocument as? FTNoteshelfDocument);
            self.pageTemplateFileItem = parentDocument?.templateFolderItem()?.childFileItem(withName: tempalteFileName) as? FTPDFKitFileItemPDF;
            
            //since for some users we can see that the file is getting prefixed with rawenc- so inorder to avoid crash for those we are checking for the fileitem with this prefixes name;
            if(nil == self.pageTemplateFileItem) {
                self.pageTemplateFileItem = parentDocument?.templateFolderItem()?.childFileItem(withName: rawTempalteFileName) as? FTPDFKitFileItemPDF;
                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                if(nil != self.pageTemplateFileItem) {
                }
                #endif
            }
        }
        objc_sync_exit(self);
        return self.pageTemplateFileItem;
    }

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    //MARK:- Thumbnail -
    func thumbnail() -> FTPageThumbnailProtocol?
    {
        objc_sync_enter(self);
        if(nil == self._pageThumbnail) {
            self._pageThumbnail = FTPageThumbnail(page: self, documentUUID: self.documentUUID,thumbnailGenerator: self.parentDocument?.thumbnailGenerator);
        }
        objc_sync_exit(self);
        return self._pageThumbnail;
    }

    //MARK:- annotations -
    func annotations() -> [FTAnnotation]
    {
        let annotationsFileItem = self.sqliteFileItem();
        if(nil != annotationsFileItem) {
            return annotationsFileItem!.annotations;
        }
        return [FTAnnotation]();
    }

    func audioAnnotations() -> [FTAnnotation] {
        var annotations = self.annotations();
        annotations = annotations.filter({ (eachAnnotation) -> Bool in
            return eachAnnotation.annotationType == .audio;
        });
        return annotations;
    }
    #endif
    //MARK:- File Names -
    internal func sqliteFileName() -> String
    {
        return self.uuid;
    }
    
    internal func usedTemplateFileNames() -> [String]
    {
        if let fileName = self.associatedPDFFileName {
            return [fileName,"rawenc-".appending(fileName)];
        }
        return [String]();
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    internal func resourceFileNames() -> Set<String>
    {
        var resourceFileNames = Set<String>();

        if let annotatiions = self.sqliteFileItem()?.annotataionsWithResources() {
            annotatiions.forEach { (eachAnnotation) in
                if let annotationResourceFileNames = eachAnnotation.resourceFileNames() {
                    resourceFileNames.formUnion(Set(annotationResourceFileNames ));
                }
            }
        }
        return resourceFileNames;
    }
    #endif
    
    //MARK:- Template Info -
    var templateInfo: FTTemplateInfo {
        var templateInfo: FTTemplateInfo?;
        if let doc = self.parentDocument as? FTNoteshelfDocument,
            let fileName = self.associatedPDFFileName {
            templateInfo = doc.templateValues(fileName);
        }
        return templateInfo ?? FTTemplateInfo();
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    //MARK:- Unload Contents -
    func unloadContents()
    {
        let annotations = self.annotations();
        for eachAnnotation in annotations {
            eachAnnotation.unloadContents();
        }
    }
    
    func unloadPDFContentsIfNeeded() {
        self.templateFileItem()?.unloadContentsOfFileItem();
    }
    #endif
}


//MARK:- FTPageTagsProtocol -
extension FTNoteshelfPage : FTPageTagsProtocol
{
    func tags() -> [String]
    {
        if let arrStr = self._tags.array as? [String] {
            return arrStr
        }
        return []
    }
    
    func addTag(_ tag : String)
    {
        self._tags.add(tag)
        if(!self.isInitializationInprogress) {
            NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
        }
    }
    
    func removeTag(_ tag : String)
    {
        self._tags.remove(tag);
        if(!self.isInitializationInprogress) {
            NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
        }
    }

    func removeAllTags() {
        self._tags.removeAllObjects()
        if(!self.isInitializationInprogress) {
            NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
        }
    }
    
    func rename(tag: String, with title:String) {
        if self._tags.count > 0 {
            let index = self._tags.index(of: tag)
            if index < self._tags.count {
                self._tags.replaceObject(at: index, with: title)
                
                if(!self.isInitializationInprogress) {
                    NotificationCenter.default.post(name: NSNotification.Name.FTDidChangePageProperties, object: self.parentDocument as? FTNoteshelfDocument);
                }
            }
        }
    }
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//MARK:- FTPageSearchProtocol -
extension FTNoteshelfPage : FTPageSearchProtocol
{
    @objc
    @discardableResult
    func searchFor(_ searchKey : String,tags : [String]) -> Bool
    {
        self.searchLock.wait();
        if let key = self.searchingInfo?.searchKey, key == searchKey {
            self.searchLock.signal();
            return true
        }
        
        if(searchKey.isEmpty && tags.isEmpty) {
            self.searchLock.signal();
            return false;
        }
        // Only Tags
        //-> If tag is present , get the page which has tags
        // If tags and key is present, get the tag first and then search key in tagged page
        // If no tags, and only key, get page which has text in it
        var found = false;

        var searchableItems = [FTSearchableItem]();
        var tagsFound = false
        for eachTag in tags {
            tagsFound = self.tags().contains(where: { (element) -> Bool in
                return element == eachTag
            })
            if !tagsFound {break}
        }
        //If any tags are present and found in this page, proceed further search is specific tagged page
        //If no tags, also continue search with searchKey
        let processFurtherSearch = tags.isEmpty || (!tags.isEmpty && tagsFound)
        if processFurtherSearch, !searchKey.isEmpty, let textAnnotations = self.sqliteFileItem()?.textAnnotationsContainingKeyword(searchKey) {
            if(!textAnnotations.isEmpty) {
                found = true;
            }
            textAnnotations.forEach({ (textAnnotation) in
                autoreleasepool(invoking: {
                    if let textAnn = textAnnotation as? FTTextAnnotation {
                        let newBoundRect = textAnn.boundingRect;
                        if let boundsArray = textAnn.attributedString?.boundsForOccurance(of: searchKey,
                                                                                          containerSize: newBoundRect.size,
                                                                                          containerInset: FTTextView.textContainerInset(textAnn.version)) as? [NSValue] {
                            for eachValue in boundsArray {
                                var rect = eachValue.cgRectValue;
                                rect.origin.x += newBoundRect.origin.x;
                                rect.origin.y += newBoundRect.origin.y;
                                let searchItem = FTSearchItem(withRect: rect,type: FTSearchableItemType.annotation);
                                searchableItems.append(searchItem);
                            }
                        }
                    }
                });
            });
        }
        if(processFurtherSearch && !searchKey.isEmpty) {
            if self.canContinuePDFContentSearch(), let pdfPageRef = self.pdfPageRef?.copy() as? PDFPage {
                let pageRect = self.pdfPageRect;
                let document = PDFDocument();
                document.insert(pdfPageRef, at: 0);

                self.pdfContentSearchDidStart();
                let selections = document.findString(searchKey, withOptions: NSString.CompareOptions.caseInsensitive);
                self.pdfContentSearchDidComplete();
                if(!selections.isEmpty) {
                    found = true;
                    for eachItem in selections {
                        let rect = pdfPageRef.convertRect(eachItem.bounds(for: pdfPageRef), toViewBounds: pageRect, rotationAngle: Int(self.rotationAngle));
                        let searchItem = FTSearchItem(withRect: rect,type: FTSearchableItemType.pdfText);
                        searchableItems.append(searchItem);
                    }
                }
            }

            let searchedItems:[FTSearchItem] = self.getHandWrittenSearchedItems(forKey: searchKey)
            if(!searchedItems.isEmpty){
                found = true;
            }
            searchableItems.append(contentsOf: searchedItems)

            let visionSearchedItems:[FTSearchItem] = self.getVisionTextSearchedItems(forKey: searchKey)
            if(!visionSearchedItems.isEmpty){
                found = true;
            }
            searchableItems.append(contentsOf: visionSearchedItems)
        }

        let result = FTPageSearchingInfo()
        result.searchKey = searchKey
        result.pageUUID = self.uuid
        if !searchableItems.isEmpty {
            result.searchItems = searchableItems
        }
        if found && !searchKey.isEmpty && searchableItems.isEmpty {
            found = false
        }
        self.searchingInfo = result

        if #available(iOS 13.0, *) {
            //added below line as a temproary fix for memory increase issue while accessing the string from PDFPage due to iOS13. Hence adding runloop to make sure os gets some time to release the memory.
            RunLoop.current.run(until: Date().addingTimeInterval(0.1));
        }
        self.searchLock.signal();
        return found;
    }
    
    internal func getHandWrittenSearchedItems(forKey searchText:String) -> [FTSearchItem]{
        var searchedItems:[FTSearchItem] = []
        let recognitionInfo:FTRecognitionResult? = self.recognitionInfo
        
        if recognitionInfo != nil {
            let recognisedText = recognitionInfo!.recognisedString
            let characterRects:[CGRect] = recognitionInfo!.characterRects
            
            let indexes: [Int] = recognisedText.indices(of: searchText)
            indexes.forEach { (index) in
                let newString = recognisedText[...index]
                //The spaceCount logic seems not useful, please take note of this.
                let spaceCount = newString.count - newString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count;
                let finalIndex = min(index-spaceCount, characterRects.count-1)
                //
                var charRect:CGRect = characterRects[finalIndex]
                if(searchText.count > 1){
                    for nextIndex in (finalIndex + 1)...(finalIndex + searchText.count - 1){
                        let nextRect = characterRects[nextIndex]
                        if nextRect.equalTo(CGRect.zero) == false {
                            charRect = charRect.union(nextRect)
                        }
                    }
                }
                let searchItem = FTSearchItem.init(withRect: charRect,type: FTSearchableItemType.handWritten);
                searchedItems.append(searchItem)
            }
        }
        
        return searchedItems
    }
    internal func getVisionTextSearchedItems(forKey searchText:String) -> [FTSearchItem]{
        var searchedItems:[FTSearchItem] = []
        let recognitionInfo:FTVisionRecognitionResult? = self.visionRecognitionInfo
        
        if recognitionInfo != nil {
            let recognisedText = recognitionInfo!.recognisedString
            let characterRects:[CGRect] = recognitionInfo!.characterRects
            
            let indexes: [Int] = recognisedText.indices(of: searchText)
            indexes.forEach { (index) in
                let newString = recognisedText[...index]
                let spaceCount = newString.count - newString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count;
                let finalIndex = min(index-spaceCount, characterRects.count-1)
                var searchRect:CGRect = characterRects[finalIndex]
                if(searchText.count > 1){
                    for nextIndex in (finalIndex + 1)...(finalIndex + searchText.count - 1){
                        let nextRect = characterRects[nextIndex]
                        if nextRect.equalTo(CGRect.zero) == false {
                            searchRect = searchRect.union(nextRect)
                        }
                    }
                }
                let angle = Int(self.rotationAngle)
                searchRect = transform(rect: searchRect,
                                       angle: angle,
                                       refRect: self.pdfPageRect)
                let searchItem = FTSearchItem.init(withRect: searchRect,type: FTSearchableItemType.handWritten);
                searchedItems.append(searchItem)
            }
        }
        
        return searchedItems
    }

}

private func transform(rect: CGRect,
                       angle: Int,
                       refRect: CGRect) -> CGRect {

    var rectToReturn = rect
    if angle == 180 {
        let origin = rectToReturn.origin
        let x = refRect.width - origin.x - rectToReturn.size.width
        let y = refRect.height - origin.y - rectToReturn.size.height
        rectToReturn.origin = CGPoint(x: x, y: y)
    } else if angle == 90 || angle == 270 {

        //Interchange the Width and Height
        rectToReturn.size = CGSize(width: rectToReturn.height,
                                   height: rectToReturn.width)

        //Transform the origin with respect to the angle.
        let newOrigin : CGPoint
        if angle == 90 {
            newOrigin = CGPoint(x: refRect.width - rectToReturn.origin.y - rectToReturn.width, y: rectToReturn.origin.x)
        } else { //For 270°
            newOrigin = CGPoint(x: rectToReturn.origin.y,
                                y: refRect.height - rectToReturn.origin.x - rectToReturn.height)
        }
        rectToReturn.origin = newOrigin
    }
    return rectToReturn
}
#endif

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
extension FTNoteshelfPage : FTPageAnnotationFindBounds
{
    func findDefaultAudioRect(current :CGRect) -> CGRect
    {
        let audioAnnotations = self.audioAnnotations();
        let overlapThreshold = CGFloat(audioRecordSize);
        var boundingRect = current.integral;
        boundingRect.size = CGSize.init(width: audioRecordSize, height: audioRecordSize);
        var origin = boundingRect.origin;
        
        for eachAnnotation in audioAnnotations {
            let currentOrigin = CGPointIntegral(eachAnnotation.boundingRect.origin);
            let xDiff = abs(currentOrigin.x - origin.x);
            let yDiff = abs(currentOrigin.y - origin.y);
            
            if(
                (currentOrigin == origin)
                    || (xDiff < CGFloat(10))
                    || (yDiff < (overlapThreshold))
                ) {
                origin.y = currentOrigin.y + overlapThreshold + 10;
            }
            
            var tempRect = boundingRect;
            tempRect.origin = origin;
            
            let pageRect = self.pdfPageRect;
            if(pageRect.maxY < tempRect.maxY || pageRect.maxX < tempRect.maxX) {
                origin = CGPoint.init(x:pageRect.width-audioRecordSize-audioRecordSize*0.5, y: 0);
            }
        }
        boundingRect.origin = origin;
        return boundingRect;
    }
}
#endif

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
extension FTNoteshelfPage : FTPageTileAnnotationMap
{
    private func populateTileMaps(_ migrate : Bool = false)
    {
        self.tileMapAnnotations.removeAll()
        let numOfRows = 8;
        let numOfColumns = 8;
        
        let pageRect = self.pageReferenceViewSize();
        let eachWidth = pageRect.width/CGFloat(numOfRows);
        let eachHeight = pageRect.height/CGFloat(numOfColumns);
        for row in 0..<numOfRows {
            for col in 0..<numOfColumns {
                autoreleasepool {
                    let tileMap = FTTileMap();
                    let xOrigin = CGFloat(col)*eachWidth;
                    let yOrigin = CGFloat(row)*eachHeight;
                    tileMap.boundingRect = CGRect.init(x: xOrigin, y: yOrigin, width: eachWidth, height: eachHeight);
                    self.tileMapAnnotations.append(tileMap);
                }
            }
        }
        if(migrate) {
            self.annotations().forEach { (eachAnnottion) in
                if(eachAnnottion.shouldAddToPageTile) {
                    self.tileMapAddAnnotation(eachAnnottion);
                }
            }
        }
    }
    
    func tileMapAddAnnotation(_ annotation: FTAnnotation) {
        if(self.tileMapAnnotations.isEmpty) {
            self.populateTileMaps();
        }
        let maps = self.tileMappingRect([annotation.renderingRect]);
        maps.forEach { (eachTile) in
            eachTile.annotations.insert(annotation);
        }
    }
    
    func tileMapRemoveAnnotation(_ annotation: FTAnnotation) {
        let maps = self.tileMappingRect([annotation.boundingRect]);
        maps.forEach { (eachTile) in
            let index = eachTile.annotations.index(of: annotation);
            if(nil != index) {
                eachTile.annotations.remove(at: index!);
            }
        }
    }
    
    func tileMappingRect(_ rects : [CGRect]) -> [FTTileMap]
    {
//        var tileMap = [FTTileMap]()
//        for eachTile in self.tileMapAnnotations where eachTile.tileContainsRect(rects) {
//            tileMap.append(eachTile);
//        }

        let tileMap = self.tileMapAnnotations.filter{ $0.tileContainsRect(rects) }
        return tileMap
    }
    
    func clearMapCache()
    {
        if(!(self.sqliteFileItem()?.isModified ?? false)) {
            self.tileMapAnnotations.removeAll();
        }
    }
}
#endif

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//MARK:- FTCopying -
extension FTNoteshelfPage : FTCopying {
    internal func copyPage(_ toDocument: FTDocumentProtocol) -> FTNoteshelfPage {
        guard let parentDoc = toDocument as? FTNoteshelfDocument else { fatalError("Parent document is nil")}
        let newPage = FTNoteshelfPage(parentDocument: parentDoc);
        newPage.isInitializationInprogress = true;
        newPage.associatedPDFFileName = self.associatedPDFFileName;
        newPage.associatedPDFPageIndex = self.associatedPDFPageIndex;
        newPage.isBookmarked = self.isBookmarked;
        newPage.bookmarkTitle = self.bookmarkTitle;
        newPage.bookmarkColor = self.bookmarkColor;
        newPage._pageRect = self._pageRect;
        newPage._pdfPageRect = self._pdfPageRect;
        
        newPage.lineHeight = self.lineHeight;
        newPage.bottomMargin = self.bottomMargin;
        newPage.topMargin = self.topMargin;
        newPage.leftMargin = self.leftMargin;
        newPage.isCover = self.isCover
        newPage.pdfKitPageRect = self.pdfKitPageRect;
        newPage.rotationAngle = self.rotationAngle
        newPage.pageBackgroundColor = self.pageBackgroundColor;
        newPage.hasContents = self.hasContents;
        //copy tags
        for eachTag in self.tags() {
            newPage.addTag(eachTag);
        }
        newPage.isInitializationInprogress = false;
        return newPage;
    }
    
    internal func deepCopyPage(_ toDocument: FTDocumentProtocol, onCompletion: @escaping (FTPageProtocol) -> Void)
    {
        let newPage = self.copyPage(toDocument);
        newPage.isInitializationInprogress = true;
        newPage.pageBackgroundColor = self.pageBackgroundColor;
        newPage.hasContents = self.hasContents
        if let info = self.recognitionInfo, info.lastUpdated == self.lastUpdated{
            let newRecognitionInfo = FTRecognitionResult.init(withDictionary: info.dictionaryRepresentation())
            newRecognitionInfo.lastUpdated = newPage.lastUpdated
            newPage.recognitionInfo = newRecognitionInfo
        }
        else
        {
            newPage.recognitionInfo = self.recognitionInfo
        }
        
        //copy annotations
        let pageAnnotations = self.annotations();
        if let templateInfo = self.templateInfo.copy() as? FTTemplateInfo,
            let newFileName = newPage.associatedPDFFileName {
            newPage._parent?.setTemplateValues(newFileName, values: templateInfo);
        }
        
        //copy pdf file if needed
        let copiedPageTempateFileItem = newPage.templateFileItem();
        if(nil == copiedPageTempateFileItem) {
            let pdfTemplateFileItem = FTPDFKitFileItemPDF.init(fileName: newPage.associatedPDFFileName)!
            pdfTemplateFileItem.securityDelegate = self._parent;
            
            newPage._parent!.templateFolderItem()!.addChildItem(pdfTemplateFileItem);
            FileManager.coordinatedCopyAtURL(self.templateFileItem()!.fileItemURL,
                                             toURL: pdfTemplateFileItem.fileItemURL,
                                             onCompletion:
                { (_, _) in
                    newPage.deepCopyAnnotations(pageAnnotations){
                        newPage.isInitializationInprogress = false;
                        DispatchQueue.main.async {
                            onCompletion(newPage);
                        }
                    }
            });
        }
        else {
            newPage.deepCopyAnnotations(pageAnnotations) {
                newPage.isInitializationInprogress = false;
                DispatchQueue.main.async {
                    onCompletion(newPage);
                }
            }
        }
    }
}

//MARK:- Copy Annotations -
extension FTNoteshelfPage {
    func deepCopyAnnotations(_ annotations : [FTAnnotation],
                             insertFrom : Int = -1,
                             onCompletion : @escaping  (()->()))
    {
        self._startCopyingAnnotations(annotations,
                                      copiedAnnotations : [FTAnnotation](),
                                      onCompletion: { (copiedAnnotations) in
                                        self.undoManager?.disableUndoRegistration()
                                        var indices: [Int]?
                                        if insertFrom != -1 {
                                            var insertIndices = [Int]();
                                            let count = copiedAnnotations.count;
                                            for i in 0..<count {
                                                insertIndices.append(insertFrom + i);
                                            }
                                            indices = insertIndices;
                                        }
                                        self.addAnnotations(copiedAnnotations, indices: indices);
                                        self.undoManager?.enableUndoRegistration()
                                        onCompletion();
        })
    }
    
    private func _startCopyingAnnotations(_ annotations : [FTAnnotation],
                                          copiedAnnotations : [FTAnnotation],
                                          onCompletion : @escaping  (([FTAnnotation])->()))
    {
        
        autoreleasepool{
            var pageAnnotations = annotations;
            var copyAnnotations = copiedAnnotations;
            if let annotation = pageAnnotations.first {
                pageAnnotations.removeFirst();
                annotation.deepCopyAnnotation(self, onCompletion: { (copiedAnnotation) in
                    if let copiedAnnotation = copiedAnnotation {
                        copyAnnotations.append(copiedAnnotation)
                    }
                    DispatchQueue.main.async {
                        self._startCopyingAnnotations(pageAnnotations,
                                                      copiedAnnotations : copyAnnotations,
                                                      onCompletion: onCompletion)
                    }
                });
            }
            else {
                onCompletion(copyAnnotations);
            }
        };
    }
}

//MARK:- Mark delete -
extension FTNoteshelfPage : FTDeleting {
    
    func willDelete()
    {
        objc_sync_enter(self);
        let filteredAnnotations = self.annotations() ;
        filteredAnnotations.forEach({ (eachAnnotation) in
            eachAnnotation.willDelete();
        });
        
        let annotationsFileItem = self.sqliteFileItem();
        if(nil != annotationsFileItem) {
            annotationsFileItem!.deleteContent();
        }
        self.thumbnail()?.delete();
        self.recognitionInfo = nil // To remove record from recognition plist
        self.undoManager?.removeAllActions(withTarget: self)
        objc_sync_exit(self);
    }
}

extension FTNoteshelfPage: FTThumbnailable {
    ///This rotates the page by clock wise 90°.
    ///We're currently supporting counter clock wise 90°, when we rotate from the finder.
    func rotate() {
        self.rotate(by: 90)
    }
}
#endif

extension FTNoteshelfPage {
    func hasPDFText() -> Bool {
        if FTUserDefaults.isInSafeMode() {
            return false
        }

        if self.hasContents == .unknown
            , let templateURL = self.templateFileItem()?.fileItemURL,
            let pdfDoc = PDFDocument.init(url: templateURL) {
            let pageNumber = Int(self.associatedPDFKitPageIndex);
            let page = pdfDoc.page(at: pageNumber);
            if let pdfText = page?.string?.trimmingCharacters(in: CharacterSet.whitespaces), !pdfText.isEmpty {
                self.hasContents = .hasContent;
            }
            else {
                self.hasContents = .noContent;
            }
        }
        return (self.hasContents == .hasContent)
    }
}

extension CGRect {
    func rotate(by angle: UInt) -> CGRect {
        let x = self.midX
        let y = self.midY
        let transform = CGAffineTransform(translationX: x, y: y)
            .rotated(by: CGFloat(angle) * .pi / 180)
            .translatedBy(x: -x, y: -y)
        return self.applying(transform)
    }

    mutating func rotate(by angle: CGFloat, refPoint: CGPoint) {
        let transform = CGAffineTransform(translationX: refPoint.x, y: refPoint.y)
            .rotated(by: angle)
            .translatedBy(x: -refPoint.x, y: -refPoint.y)
        self = self.applying(transform)
    }
}

extension FTNoteshelfPage: FTPageBackgroundColorProtocol {

    func updateBackgroundColor(color: UIColor) {
        self.pageBackgroundColor = color
    }

    func pageBackgroundColor(onCompletion : @escaping (UIColor?)->()) {
        if(nil != self.pageBackgroundColor) {
            onCompletion(self.pageBackgroundColor);
        }
        else {
            DispatchQueue.global().async { [weak self] in
                guard let strongSelf = self else {
                    DispatchQueue.main.async {
                        onCompletion(nil);
                    }
                    return;
                }
                var color: UIColor?;
                if let page = strongSelf.pdfPageRef {
                    color = page.getBackgroundColor();
                }
                DispatchQueue.main.async {
                    strongSelf.pageBackgroundColor = color;
                    onCompletion(color);
                }
            }
        }
    }
}

private extension FTNoteshelfPage {
    var timeStampKey: String {
        return "timeStamp";
    }
    
    var minDuration: TimeInterval {
        return 12 * 60 * 60;
    }
    
    var contentCache: FTCache? {
        guard var doc = self.parentDocument as? FTCacheProtocol else {
            return nil;
        }
        if nil == doc.cache,let uuid = self.parentDocument?.documentUUID {
            doc.cache = FTCache(identifier: uuid);
        }
        return doc.cache;
    }

    func canContinuePDFContentSearch() -> Bool {
        var canContinue = false;
        let val = self.contentCache?.object(forKey: self.uuid) as? [String:Any] ?? [String:Any]();
        let timeStamp = (val[timeStampKey] as? TimeInterval) ?? 0;
        let curTimeStamp = Date().timeIntervalSinceReferenceDate;
        if(curTimeStamp - timeStamp > minDuration) {
            canContinue = true;
        }
        return canContinue;
    }
        
    func pdfContentSearchDidStart() {
        var val = self.contentCache?.object(forKey: self.uuid) as? [String:Any] ?? [String:Any]();
        val[timeStampKey] = Date().timeIntervalSinceReferenceDate;
        self.contentCache?.setObject(val, forKey: self.uuid);
    }
    
    func pdfContentSearchDidComplete() {
        self.contentCache?.removeObject(forKey: self.uuid);
    }
}

protocol FTCacheProtocol {
    var cache: FTCache? {get set};
}

class FTCache: NSObject {
    private var _contents: NSMutableDictionary?;
    private var identifier = UUID().uuidString;
    
    init(identifier _iden: String) {
        identifier = _iden
    }
    
    private func cacheURL() -> URL {
        let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                              .userDomainMask,
                                                              true).last;
        let cacheFolderURL = Foundation.URL(fileURLWithPath: cacheFolder!);
        let fileName = self.identifier.appending(".plist");
        return cacheFolderURL.appendingPathComponent(fileName);
    }
    
    private var contents: NSMutableDictionary? {
        objc_sync_enter(self);
        if nil == _contents {
            _contents = NSMutableDictionary(contentsOf: self.cacheURL());
        }
        objc_sync_exit(self);
        return _contents
    }
    
    func setObject(_ object:Any,forKey key: String) {
        objc_sync_enter(self);
        self.contents?.setObject(object, forKey: key as NSCopying);
        self.contents?.write(to: self.cacheURL(), atomically: true);
        objc_sync_exit(self);
    }
    
    func removeObject(forKey key: String) {
        objc_sync_enter(self);
        self.contents?.removeObject(forKey: key);
        self.contents?.write(to: self.cacheURL(), atomically: true);
        objc_sync_exit(self);
    }
    
    func object(forKey key: String) -> Any? {
        objc_sync_enter(self);
        let value = self.contents?.object(forKey: key);
        objc_sync_exit(self);
        return value;
    }
}

extension FTNoteshelfPage: NSItemProviderWriting {
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [kUTTypeData as String]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        // 5
        do {
            let dict = ["bookMarkTitle" : self.bookmarkTitle,
                        "Color":self.bookmarkColor] as [String : Any];
            let data = try PropertyListSerialization.data(fromPropertyList: dict,
                                                              format: .xml,
                                                              options: 0)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
