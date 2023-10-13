//
//  FTNoteshelfDocument.swift
//  Noteshelf
//
//  Created by Amar on 25/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//
let APP_SUPPORTED_MAX_DOC_VERSION = Float(8);
let DOC_VERSION : String = "8.0";
let DOCUMENTS_KEY : String = "documents";
let DOCUMENT_TYPE = "document_type"
let DOCUMENT_ID_KEY =  "document_ID";
let NOTEBOOK_ID_KEY =  "notebook_ID";
let PAGE_NUMBERS_KEY = "page_numbers";
let ASSIGNMENT_TITLE = "assignment_title"
let DOCUMENT_VERSION_KEY = "document_Ver";
let DEVICE_ID = "device_ID";
let APP_VERSION = "app_version";
let USER_IDs_KEY =  "user_IDs";
let SHELF_TITLE_OPTION = "shelf_title";
let ASSIGNMENTS_PLIST = "Assignments.plist"
let NOTEBOOK_RECOVERY_PLIST = "RecoverBook.plist"
let DOCUMENT_TAGS_KEY =  "tags";
let INSERTCOVER = "insertCover"

import Foundation
import UIKit
import FTDocumentFramework
import FTCommon
import FTNewNotebook

@objc protocol FTNoteshelfDocumentDelegate : FTDocumentDelegate {
    func documentWillStartSaving(_ document: FTDocumentProtocol)
}

private class FTNSDocumentListener: NSObject {
    weak var documentDelegate: FTNoteshelfDocumentDelegate?;
}

class FTNoteshelfDocument : FTDocument,FTDocumentProtocol,FTPrepareForImporting,FTDocumentProtocolInternal,FTCacheProtocol
{
    var cache: FTCache?;
    fileprivate var searchOperationQueue = OperationQueue.init();
    fileprivate var openPurpose = FTDocumentOpenPurpose.write;
    
    internal weak var documentPlistItem: FTNSDocumentInfoPlistItem?;

    override var delegate: FTDocumentDelegate! {
        willSet {
            if !(newValue is FTNoteshelfDocument) {
                fatalError("use addListner() method instead");
            }
        }
    }
    private var documentListners = [NSInteger : FTNSDocumentListener]();
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    private weak var _recognitionHelper: FTNotebookRecognitionHelper?
    private weak var _visionRecognitionHelper: FTVisionNotebookRecognitionHelper?
    lazy var recognitionCache: FTRecognitionCache? = {
        return FTRecognitionCache.init(withDocument: self, language: FTLanguageResourceManager.shared.currentLanguageCode);
    }();
    
    fileprivate var localCacheWrapper: FTLocalMetadataCache?;
    
    
    lazy var pdfOutliner: FTPDFOutliner? = {
        return FTPDFOutliner.init(withDocument: self);
    }();

    var localMetadataCache: FTDocumentLocalMetadataCacheProtocol? {
        return self.localCacheWrapper;
    }

    var thumbnailGenerator : FTThumbnailGenerator? = FTThumbnailGenerator();

    private var _onScreenRenderer: FTOnScreenRenderer?
    #endif

    fileprivate var previousFileModeificationDate : Date?;
    internal var isInDocCreationMode = false;
    var wasPinEnabled:Bool = false
    var isDirty: Bool = false
    var isJustCreatedWithQuickNote = false
    
    @objc dynamic var hasNS1Content: Bool = false{
        willSet {
            self.willChangeValue(forKey: "hasNS1Content");
        }
        didSet {
            self.didChangeValue(forKey: "hasNS1Content");
        }
    }

    required override init(fileURL url: URL) {
        super.init(fileURL: url);
        self.wasPinEnabled = self.isPinEnabled()
    }

    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
        NotificationCenter.default.removeObserver(self);
        self.searchOperationQueue.cancelAllOperations();
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        self.releaseRecognitionHelperIfNeeded()
        self.releaseVisionRecognitionHelperIfNeeded()
        FTTexturePool.shared.evictCacheForDocument(docId: documentUUID)
        #endif
    }
    
    var URL: Foundation.URL {
        return self.fileURL;
    }
    
    var documentUUID: String = FTUtils.getUUID() {
        didSet {
            let propertyInfoPlist = self.propertyInfoPlist();
            if(nil != propertyInfoPlist) {
                let currentValue = propertyInfoPlist!.object(forKey: DOCUMENT_ID_KEY) as? String;
                if(currentValue != self.documentUUID) {
                    propertyInfoPlist!.setObject(self.documentUUID, forKey: DOCUMENT_ID_KEY);
                }
            }
        }
    };
    
    var assignmentUUID : String? {
        didSet {
            let assignmentInfoPlist = self.assignmentInfoPlist(createIfNeeded: true);
            if(oldValue == nil && self.assignmentUUID != nil) {
                assignmentInfoPlist!.setObject(self.assignmentUUID, forKey: NOTEBOOK_ID_KEY);
            }
        }
    }
    
    var assignmentTitle : String? {
        didSet {
            let assignmentInfoPlist = self.assignmentInfoPlist(createIfNeeded: true);
            if(oldValue == nil && self.assignmentTitle != nil) {
                assignmentInfoPlist!.setObject(self.assignmentTitle, forKey: ASSIGNMENT_TITLE);
            }
        }
    }
    
    var pageNumbers: [Int]? {
        didSet {
            let assignmentInfoPlist = self.assignmentInfoPlist(createIfNeeded: true);
            if(self.pageNumbers != nil && assignmentInfoPlist != nil) {
               assignmentInfoPlist!.setObject(self.pageNumbers, forKey: PAGE_NUMBERS_KEY);
            }
        }
    }
    override var thumbnailImage: UIImage? {
        return self.shelfImage;
    }

    var shelfImage: UIImage? {
        get{
            if let rootItem = self.rootFileItem {
                let shelfItemImageFileItem = rootItem.childFileItem(withName: "cover-shelf-image.png") as? FTFileItemImage;
                return shelfItemImageFileItem?.image();
            }
            FTLogError("root_item_nil", attributes: ["doc_state":self.documentState.rawValue])
            return nil;
        }
        set {
            if let rootItem = self.rootFileItem {
                var shelfItemImageFileItem = rootItem.childFileItem(withName: "cover-shelf-image.png") as? FTFileItemImage;
                if(nil == shelfItemImageFileItem)
                {
                    shelfItemImageFileItem = FTFileItemImage.init(fileName: "cover-shelf-image.png");
                    shelfItemImageFileItem?.securityDelegate = self;
                    rootItem.addChildItem(shelfItemImageFileItem);
                }
                shelfItemImageFileItem?.setImage(newValue);
            }
        }
    }
    
    var hasAnyUnsavedChanges: Bool {
        let documentInfoPlist = self.documentInfoPlist();
        var changes = super.hasUnsavedChanges
            || ((nil != documentInfoPlist) && documentInfoPlist!.isModified);

        let allPages = self.pages()
        if(!changes){
            changes = self.shouldGenerateCoverThumbnail
        }
        if(!changes) {
            for eachPage in allPages where eachPage.isDirty {
                    changes = true;
                    break;
            }
        }
        return changes;
    }
    var shouldGenerateCoverThumbnail : Bool {
        var changes = false
        
//        if (self.wasPinEnabled == true && self.isPinEnabled() == true) {
//            return false
//        }
        if (self.wasPinEnabled != self.isPinEnabled()){
            return true
        }
        else{
            let allPages = self.pages()
            if let firstPage = allPages.first{
                if(!firstPage.isFirstPage || firstPage.isPageModified){
                    changes = true;
                }
            }
        }
        return changes
    }

    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    func cancelAllThumbnailGeneration() {
        for page in self.pages() {
            page.thumbnail()?.cancelThumbnailGeneration();
        }
    }
    #endif

    //MARK:- Create Doc / Insert PDF to Doc -
    @available(*, renamed: "createDocument(_:)")
    func createDocument(_ info : FTDocumentInputInfo,onCompletion : @escaping  ((NSError?,Bool) -> Void))
    {
        self.isInDocCreationMode = true;
        if let templateURL = info.inputFileURL, info.isTemplate, templateURL.pathExtension == nsBookExtension {
            DispatchQueue.main.async(execute: {
                self.createDocumentFromNSTemplate(info, onCompletion: { (error, success) in
                    DispatchQueue.main.async(execute: {
                        self.isInDocCreationMode = false;
                        if(success) {
                            self.openDocumentAndUpdateLocalCache {
                                onCompletion(error,success)
                            }
                        }
                        else {
                            onCompletion(error,success)
                        }
                    });
                });
            });
            return;
        }

        self.createDefaultFileItems();
        self.shelfImage = info.coverTemplateImage;
        self.documentInfoPlist()!.defaultPageRect = CGRect(x: 0, y: 0, width: 768, height: 1024);
        self.propertyInfoPlist()!.setObject(DOC_VERSION, forKey: DOCUMENT_VERSION_KEY);
        self.propertyInfoPlist()!.setObject(self.documentUUID, forKey: DOCUMENT_ID_KEY);
        self.propertyInfoPlist()!.setObject(FTUtils.deviceModelFriendlyName(), forKey: DEVICE_ID);
        self.propertyInfoPlist()!.setObject(appVersion(), forKey: APP_VERSION);
        self.propertyInfoPlist()!.setObject([String](), forKey: USER_IDs_KEY);
        self.propertyInfoPlist()!.setObject([String](), forKey: DOCUMENT_TAGS_KEY);

        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if info.overlayStyle != FTCoverStyle.default{ //When creating a new notebook while moving pages
                self.shelfImage = self.transparentThumbnail(isEncrypted: info.isEnCrypted)
            }
        #endif
        self.save(to: self.fileURL, for: UIDocument.SaveOperation.forCreating) { (createSuccess) in
            if(createSuccess) {
                if(nil != info.inputFileURL) {
                    self.documentPlistItem = nil;
                    self.openDocument(purpose: .write, completionHandler: { (openSuccess,_) in
                        
                        let blockTocall : (Bool,NSError?)->() = { (success,error) in
                            
                            self.updateLocalCacheForNewlyCreatedDocumentIfNeeded();
                            self.closeDocument(completionHandler: { _ in
                                DispatchQueue.main.async(execute: {
                                    if(nil != error) {
                                        try? FileManager().removeItem(at: self.fileURL);
                                    }
                                    self.isInDocCreationMode = false;
                                    onCompletion(error,success);
                                });
                            });
                        };

                        if(openSuccess) {
                            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//                            info.isTemplate = false
                            if info.isTemplate && info.isCover {
                                // If it is a template, insert the cover as first page followed by respective template.
                                self.insertCoverAsPage(info) { success, error in
                                    blockTocall(success,error);
                                }
                            } else {
                                self.insertFileFromInfo(info,onCompletion: { (success, error) in
                                    if success,let pinModel = info.pinModel, let pin = pinModel.pin {
                                        self.pin = pin
                                        self.setHint(pinModel.hint)
                                        self.secureDocument(onCompletion: { (success) in
                                            blockTocall(success,error);
                                        });
                                    }
                                    else {
                                        blockTocall(success,error);
                                    }
                                });
                            }
                            #else
                            self.insertFileFromInfo(info,onCompletion: { (success, error) in
                                blockTocall(success,error);
                            });
                            #endif
                        }
                        else {
                            DispatchQueue.main.async(execute: {
                                self.isInDocCreationMode = false;
                                onCompletion(FTDocumentCreateErrorCode.error(.openFailed),openSuccess);
                            });
                        }
                    });
                }
                else {
                    DispatchQueue.main.async(execute: {
                        self.isInDocCreationMode = false;
                        onCompletion(nil,createSuccess);
                    });
                }
            }
            else {
                self.isInDocCreationMode = false;
                onCompletion(FTDocumentCreateErrorCode.error(.saveFailed),createSuccess);
            }
        };
    }
    
    private func insertCoverAsPage(_ info : FTDocumentInputInfo,
                                   onCompletion : @escaping ((Bool,NSError?) -> Void)) {
        let coverInfo = FTDocumentInputInfo()
        coverInfo.isCover = info.isCover
        coverInfo.insertAt = 0
        coverInfo.rootViewController = info.rootViewController
        coverInfo.coverTemplateImage = info.coverTemplateImage
        var defaultFileURL = Bundle.main.url(forResource: "cover_template", withExtension: "pdf");
        if let url = info.coverTemplateUrl, FileManager().fileExists(atPath: url.path) {
            defaultFileURL = url
        }
        var error: NSError?
        if let url = defaultFileURL, FileManager().fileExists(atPath: url.path) {
            let tempPath = FTUtils.copyFileToTempLoc(FTUtils.getUUID(), defaultFileURL!.path as NSString, error: &error)
            let inputUrl = Foundation.URL(fileURLWithPath: tempPath!)
            coverInfo.inputFileURL = inputUrl
            #if !NS2_SIRI_APP && !NOTESHELF_ACTION
            self.insertFileFromInfo(coverInfo, onCompletion: { (success, error) in
                info.insertAt = 1
                if info.isCover && info.isTemplate {
                    info.isCover = false
                }
                self.insertFileFromInfo(info) { success, error in
                    //Since we have created a notebook with two pages(cover and template),setting the index to 1 will land on to template.
                    self.localMetadataCache?.lastViewedPageIndex = 1
                    if success,let pinModel = info.pinModel, let pin = pinModel.pin {
                        self.pin = pin
                        self.setHint(pinModel.hint)
                        self.secureDocument(onCompletion: { (success) in
                            onCompletion(success, error)
                        });
                    }
                    else {
                        onCompletion(success, error)
                    }
                }
            })
        #else
            self.insertFileFromInfo(info,onCompletion: { (success, error) in
                onCompletion(success, error)
            });
        #endif
        }
    }
    
    fileprivate var tempZipLoc: NSString {
        let folder = (FTUtils.applicationCacheDirectory() as NSString).appendingPathComponent("TempZip")
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {

        }
        return folder as NSString
    }
    func insertFile(_ info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void)) {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        if let templateURL = info.inputFileURL, info.isTemplate, templateURL.pathExtension == nsBookExtension {
            DispatchQueue.main.async(execute: {
                self.insertPageFromNSTemplate(info, onCompletion: { (error, success) in
                    DispatchQueue.main.async(execute: {
                        onCompletion(error,success);
                    });
                });
            });
            return;
        }
        #endif
        self.insertFileFromInfo(info,onCompletion: { (success, error) in
            DispatchQueue.main.async(execute: {
                onCompletion(error,success);
            });
        });
    }
    
    func updatePageTemplate(page : FTPageProtocol,info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void)) {
        self.updatePageTemplateFromInfo(page: page, info: info, onCompletion: onCompletion);
    }
    
    //MARK:- Doc creation from selectedPages
    func createDocumentAtTemporaryURL(_ toURL : Foundation.URL,
                                      purpose: FTDocumentCreationPurpose,
                                      fromPages : [FTPageProtocol],
                                      documentInfo: FTDocumentInputInfo?,
                                      onCompletion :@escaping ((Bool,NSError?) -> Void)) -> Progress
    {
        let info: FTDocumentInputInfo;
        if let dInfo = documentInfo {
            info = dInfo;
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            info.coverTemplateImage = self.shelfCoverImage(for: fromPages)
        #endif
        }
        else {
            info = FTDocumentInputInfo()
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                info.coverTemplateImage = self.shelfCoverImage(for: fromPages)
            #endif
            info.isNewBook = true;
        }
        let progress = Progress();
        progress.totalUnitCount = Int64(1);

        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        let blocktocall : () -> () = {
            let operation = FTDocumentFromPages.init(with: self,purpose: purpose);
            let subProgress = operation.createDocumentAtTemporaryURL(toURL,
                                                                     fromPages: fromPages,
                                                                     documentInfo: info)
            { (error) in
                onCompletion((nil == error),error as NSError?);
            };
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }
        if self.hasAnyUnsavedChanges {
            func runSave() {
                self.saveDocument { (success) in
                    if(success) {
                        blocktocall();
                    }
                    else {
                        onCompletion(false,FTDocumentCreateErrorCode.error(.saveFailed));
                    }
                }
            }
            
            let isInMainThread = Thread.current.isMainThread;
            if(!isInMainThread) {
                runInMainThread {
                    runSave();
                }
            }
            else {
                runSave();
            }
        }
        else {
            blocktocall();
        }
        #endif
        return progress;
    }
    
    //MARK:- Doc insertion at index
    func insertDocumentAtURL(_ url : Foundation.URL,
                             atIndex : Int,
                             onCompletion :@escaping ((Bool,NSError?) -> Void)) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        let documentToInsert = FTDocumentFactory.documentForItemAtURL(url);
        guard let docInternalProtocol = documentToInsert as? FTDocumentProtocolInternal else {
            fatalError("\(documentToInsert) should implement FTDocumentProtocolInternal");
        }
        docInternalProtocol.openDocument(purpose: .read) { (success,error) in
            if(success) {
                let pages = documentToInsert.pages();
                let subProgress = self.recursivelyCopyPages(pages,
                                                            currentPageIndex: 0,
                                                            startingInsertIndex: atIndex,
                                                            pageInsertPosition: .inBetween,
                                                            onCompletion:
                    { (success, error, _) in
                        onCompletion(success,error);
                });
                progress.addChild(subProgress, withPendingUnitCount: 1);
            }
            else {
                var docError = error;
                if(nil == docError) {
                    docError = FTDocumentTemplateImportErrorCode.error(.openFailed);
                }
                onCompletion(false,docError);
            }
        }
        return progress;
    }
    
   
    //MARK:- Override Methods -
    override func loadInitialDataForDocument() {
        super.loadInitialDataForDocument();
        self.previousFileModeificationDate  = self.fileModificationDate;
        
        let propertyInfoPlist = self.propertyInfoPlist();
        if let docUUID = propertyInfoPlist?.object(forKey: DOCUMENT_ID_KEY) as? String {
            self.documentUUID = docUUID;
        }
        
        let assignmentInfoPlist = self.assignmentInfoPlist(createIfNeeded: false);
        if(nil != assignmentInfoPlist) {
            if assignmentInfoPlist?.object(forKey: NOTEBOOK_ID_KEY) != nil {
                self.assignmentUUID = assignmentInfoPlist?.object(forKey: NOTEBOOK_ID_KEY) as? String;
            }
            if assignmentInfoPlist?.object(forKey: PAGE_NUMBERS_KEY) != nil {
                self.pageNumbers = assignmentInfoPlist?.object(forKey: PAGE_NUMBERS_KEY) as? [Int]
            }
            if assignmentInfoPlist?.object(forKey: ASSIGNMENT_TITLE) != nil {
                self.assignmentTitle = assignmentInfoPlist?.object(forKey: ASSIGNMENT_TITLE) as? String;
            }
        }
        
        let documentInfoFileItem = self.documentInfoPlist();
        if(nil != documentInfoFileItem) {
            documentInfoFileItem!.parentDocument = self;
            let documentsList = documentInfoFileItem!.object(forKey: DOCUMENTS_KEY) as? [String:AnyObject];
            if(documentsList != nil)
            {
                for (key,_) in documentsList!
                {
                    let fileItem = self.templateFolderItem()?.childFileItem(withName: key) as? FTPDFKitFileItemPDF;
                    if(fileItem != nil) {
                        fileItem!.documentPassword = self.decryptedPasswordForDocumentName(key);
                    }
                }
            }
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            //initialize local cache
            self.localCacheWrapper = FTLocalMetadataCache.init(documentUUID: documentUUID,documentRect:documentInfoFileItem!.defaultPageRect);
            self.localCacheWrapper?.loadMetadataCache();
            #endif
            //notification observers
            self.addObservers();
        }
    }
    
    func openDocument(purpose: FTDocumentOpenPurpose, completionHandler: ((Bool, NSError?) -> Void)?) {
        FTCLSLog("Doc open: Initiated");
        self.openPurpose = purpose;
        super.open { (success) in
            if(!success) {
                completionHandler?(false,nil);
                return;
            }
            
            if(self.isInDocCreationMode
                || (self.isValidDocument() && self.isDocumentVersionSupported())
                    ) {
                
                //**************************** User IDs from all the devices
                if let currentUserID = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") as? String{
                    if let userIDs = self.propertyInfoPlist()?.object(forKey: USER_IDs_KEY) as? [String]{
                        if userIDs.contains(currentUserID) == false{
                            var newUserIDs = userIDs
                            newUserIDs.append(currentUserID)
                            self.propertyInfoPlist()?.setObject(newUserIDs, forKey: USER_IDs_KEY)
                        }
                    }
                    else{
                        self.propertyInfoPlist()?.setObject([currentUserID], forKey: USER_IDs_KEY)
                    }
                }
                
                //****************************
                FTCLSLog("Doc open: valid");
                if(nil != completionHandler) {
                    completionHandler!(success,nil);
                }
            }
            else {
                var error : NSError?;
                if(!self.isDocumentVersionSupported()) {
                    error = FTDocumentTemplateImportErrorCode.error(.requiresAppUpdate);
                }
                else {
                    let infoFileItem = self.propertyInfoPlist();
                    var params = [String:Any]()
                    if(nil != infoFileItem) {
                        var deviceID = infoFileItem!.object(forKey: DEVICE_ID) as? String;
                        if(nil == deviceID) {
                            deviceID = "Unknown";
                        }

                        var appversion = infoFileItem?.object(forKey: APP_VERSION) as? String;
                        if(nil == appversion) {
                            appversion = "Unknown";
                        }
                        params = ["UUID": self.documentUUID,
                                  "deviceID": deviceID!,
                                  "appversion": appversion!]
                    } else {
                        params = ["UUID": self.documentUUID,
                                  "Plist": "Not Found"]
                    }
                    FTLogError("Doc Corrupt", attributes: params)
                }
                
                self.closeDocument(completionHandler: { _ in
                    if(nil != completionHandler) {
                        completionHandler!(false,error);
                    }
                });
            }
        }
    }
    
    func saveDocument(completionHandler : ((Bool) -> Void)?)
    {
        if(self.openPurpose == .read) {
            FTLogError("Doc Saved in Readonly");
            completionHandler?(true);
            return;
        }
        if(self.hasAnyUnsavedChanges) {
            (self.delegate as? FTNoteshelfDocumentDelegate)?.documentWillStartSaving(self);
        }
        FTCLSLog("Doc: Save");
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        self.recognitionCache?.saveRecognitionInfoToDisk(forcibly: true);
        if(self.hasAnyUnsavedChanges) {
            if let cache = self.recognitionCache, let cachePlist = cache.recognitionCachePlist() {
                let mutableDict = NSMutableDictionary.init(dictionary: cachePlist.contentDictionary);
                self.recognitionInfoPlist()?.updateContent(mutableDict);
            }
            if let cache = self.recognitionCache, let cachePlist = cache.visionRecognitionCachePlist() {
                let mutableDict = NSMutableDictionary.init(dictionary: cachePlist.contentDictionary);
                self.visionRecognitionInfoPlist()?.updateContent(mutableDict);
            }

            //This was added in version 6.2, when we removed the bounding rect from the Segment level storage.
            updateDocumentVersionToLatest()
        }
        #endif

        super.save { (success) in
            if(success) {
                self.previousFileModeificationDate = self.fileModificationDate;
                let pages = self.pages();
                for eachPage in pages {
                    eachPage.isDirty = false;
                }
            }
            completionHandler?(success);
        }
    }
    
    func closeDocument(completionHandler: ((Bool) -> Void)?)
    {
         FTCLSLog("Doc: Close");
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        self.recognitionCache?.saveRecognitionInfoToDisk(forcibly: true)
        #endif
        super.close { (success) in
            self.removeObservers();
            completionHandler?(success);
        }
    }

    func prepareForClosing() {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        //save local meta data cache
        self.localCacheWrapper?.saveMetadataCache();
        self.deleteUnusedFileItems();
        #endif
    }
    
    func saveAndCloseWithCompletionHandler(_ onCompletion :((Bool) -> Void)?)
    {
        FTCLSLog("Doc: Save and Close");
        self.prepareForClosing();
        self.saveDocument { (saveSuccess) in
            if(saveSuccess) {
                self.closeDocument(completionHandler: { (_) in
                    onCompletion?(saveSuccess);
                });
            }
            else {
                onCompletion?(saveSuccess);
            }
        }
    }
    
    override func open(completionHandler: ((Bool) -> Void)? = nil)
    {
        self.openDocument(purpose: self.openPurpose) { (success, _) in
            completionHandler?(success);
        }
    }

    override func save(completionHandler onCompletion: ((Bool) -> Void)?)
    {
        self.saveDocument(completionHandler: onCompletion);
    }

    override func close(completionHandler: ((Bool) -> Void)?)
    {
        self.closeDocument(completionHandler: completionHandler);
    }
    
    override func fileItemFactory() -> FTFileItemFactory! {
        let factory = FTNSDocumentFileItemFactory();
        factory.securityDelegate = self;
        return factory;
    }

    //MARK:- Page Operations -
    func pages() -> [FTPageProtocol] {
        if let documentInfoPlist = self.documentInfoPlist() {
            return documentInfoPlist.pages;
        }
        else {
            return [FTPageProtocol]();
        }
    }
    
    func resetPageModificationStatus(){
        self.wasPinEnabled = self.isPinEnabled()
        var isFirstPage = true
        for eachPage in self.pages()
        {
            eachPage.isFirstPage = isFirstPage
            eachPage.isPageModified = false
            isFirstPage = false
        }
    }
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @discardableResult func insertPageAbove(page: FTPageProtocol) -> FTPageProtocol? {
        return self._insertPageAtIndex(page.pageIndex(), referencePage: page);
    }
    
    @discardableResult func insertPageBelow(page: FTPageProtocol) -> FTPageProtocol? {
        return self._insertPageAtIndex(page.pageIndex()+1, referencePage: page);
    }

    @discardableResult 
    func insertPageAtIndex(_ index : Int) -> FTPageProtocol?
    {
        let pageCopy : FTPageProtocol?;
        if(index >= self.pages().count) {
            pageCopy = self.pages().last;
        }
        else {
            pageCopy = self.pages()[max(0, index-1)];
        }
        return self._insertPageAtIndex(index, referencePage: pageCopy);
    }
    
    private func _insertPageAtIndex(_ index : Int,referencePage : FTPageProtocol?) -> FTPageProtocol?
    {
        var copiedPage : FTPageProtocol?;
        var isTemplate = false;
        var pageRect = CGRect(x: 0, y: 0, width: 768, height: 1024);
        if let sourcePageToCopy = referencePage as? FTNoteshelfPage {
            copiedPage = sourcePageToCopy.copyPageAttributes();
            isTemplate = sourcePageToCopy.templateInfo.isTemplate;
            pageRect = sourcePageToCopy.pdfPageRect;
        }

        if let copiedPage = copiedPage, !isTemplate {
            let generator = FTPDFFileGenerator.init();
            let fileName = FTUtils.getUUID().appending(".\(pdfExtension)");
            let path = generator.generateBlankPDFFileWithPageRect(pageRect, fileName: fileName);
            
            if let tempFileItem = FTFileItemPDFTemp(fileName: fileName) {
                tempFileItem.setSourceFileURL(NSURL.fileURL(withPath: path));
                
                copiedPage.associatedPDFFileName = fileName;
                copiedPage.associatedPDFPageIndex = Int(1);
                copiedPage.isCover = false
                copiedPage.lineHeight = Int(34);
                copiedPage.pdfPageRect = tempFileItem.pageRectOfPage(atNumber: copiedPage.associatedPDFKitPageIndex);
                
                self.templateFolderItem()!.addChildItem(tempFileItem);
                self.setTemplateValues(fileName, values: FTTemplateInfo());
            }
        }
        
        if let page = copiedPage as? FTNoteshelfPage {
            let image = FTPDFExportView.snapshot(forPage: page, size: CGSize(width: 300,height: 400), screenScale: UIScreen.main.scale, shouldRenderBackground: true);
            copiedPage?.thumbnail()?.updateThumbnail(image,updatedDate:Date(timeIntervalSinceReferenceDate: page.lastUpdated.doubleValue));
            self.documentInfoPlist()?.insertPage(page ,atIndex:index);
        }
        
        return copiedPage;
    }

    #endif
    
    func deleteTag(_ tagName : String)
    {
        let pages = self.pages();
        for eachPage in pages where eachPage is FTPageTagsProtocol
        {
            (eachPage as? FTPageTagsProtocol)?.removeTag(tagName);
        }
    }
    
    func allTags() -> Set<String> {
        var tagsSet = Set<String>();
        
        let pages = self.pages();
        for eachPage in pages where eachPage is FTPageTagsProtocol
        {
            if let tags = (eachPage as? FTPageTagsProtocol)?.tags() {
                tagsSet.formUnion(tags);
            }
        }
        return tagsSet;
    }
    
    override func writeContents(_ contents: Any, andAttributes additionalFileAttributes: [AnyHashable : Any]? = nil, safelyTo url: URL, for saveOperation: UIDocument.SaveOperation) throws {
        if(self.openPurpose == .read) {
            FTLogError("Doc writeContents in Readonly");
            return;
        }
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        if(url.urlByDeleteingPrivate() != self.fileURL.urlByDeleteingPrivate()) {

            if let currentUserID = UserDefaults.standard.object(forKey: "USER_ID_FOR_CRASH") as? String{
                let params = ["UserID" : currentUserID,"URL" : url.path,"fileURL" : self.fileURL.path]
                FTLogError("Doc URL Mismatch", attributes: params)
            }
        }
        #endif
        try super.writeContents(contents,
                                andAttributes: additionalFileAttributes,
                                safelyTo: url,
                                for: saveOperation);

        //writing fileattributes
            let uuidAttribute = FileAttributeKey.ExtendedAttribute(key: .documentUUIDKey, string: self.documentUUID)
            try? self.URL.setExtendedAttributes(attributes: [uuidAttribute])
            let isSecureAttribute = FileAttributeKey.ExtendedAttribute(key: .documentIsSecure, string: self.isPinEnabled().boolToString.lowercased())
            try? self.URL.setExtendedAttributes(attributes: [uuidAttribute, isSecureAttribute])
    }
    
    fileprivate var isInRevertMode = false;

    override func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)?) {
        if(!isInRevertMode && !self.documentState.contains(UIDocument.State.progressAvailable) && !self.documentState.contains(UIDocument.State.closed)) {
            isInRevertMode = true;
            FTCLSLog("Doc: Revert");
            if((nil == self.pin && self.isPinEnabled())
                || (nil != self.pin && !self.isPinEnabled())) {
                self.notifySecurityUpdate();
            }
            else if let oldPin = self.pin, self.isPinEnabled() {
                self.authenticate(oldPin, coordinated: true, completion: { (success, _) in
                    if success {
                        self.revertDocument(withRevertURL: url, andCompletionHandler: completionHandler);
                    }
                    else {
                        self.notifySecurityUpdate();
                    }
                });
            }
            else {
                self.revertDocument(withRevertURL: url, andCompletionHandler: completionHandler);
            }
        }
    }
    
    override func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        FTCLSLog("accommodatePresentedItemDeletion");
        super.accommodatePresentedItemDeletion {  [weak self] (error) in
                DispatchQueue.main.async(execute: {
                    if let del = self?.delegate, del.responds(to: #selector(FTDocumentDelegate.documentDidDelete(_:))) {
                        del.documentDidDelete?(self);
                    completionHandler(error);
                    }
                });
        }
    }
    
    override func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
        FTCLSLog("savePresentedItemChanges: haschanges:\(self.hasUnsavedChanges)");
        if(!Thread.current.isMainThread) {
            DispatchQueue.main.async {
                self.savePresentedItemChanges(completionHandler: completionHandler);
            }
            return;
        }
        
        if self.delegate != nil
            && (self.delegate.responds(to: #selector(FTDocumentDelegate.documentWillGetReloaded(_:onCompletion:)))) {
            self.delegate.documentWillGetReloaded!(self, onCompletion: {
                if(self.hasUnsavedChanges) {
                    self.saveDocument { _ in
                        completionHandler(nil);
                    };
                }
                else {
                    completionHandler(nil);
                }
            });
        }
        else {
            if(self.hasUnsavedChanges) {
                self.saveDocument { _ in
                    completionHandler(nil);
                };
            }
            else {
                completionHandler(nil);
            }
        }
    }
    
    override func presentedItemDidResolveConflict(_ version: NSFileVersion) {
        super.presentedItemDidResolveConflict(version);
        FTCLSLog("presentedItemDidResolveConflictVersion");
            DispatchQueue.main.async(execute: { [weak self] in
                if let del = self?.delegate, del.responds(to: #selector(FTDocumentDelegate.documentDidResolveConflict(_:))) {
                    del.documentDidResolveConflict?(self);
                }
            });
    }
    
    override func presentedItemDidMove(to newURL: URL) {
        //Since sometimes in IOS13 though the document is not moved or renamed , it is getting called some times with private prefixed and comparison is failing when compared against without private prefix url.
        let prevURL = (self.presentedItemURL ?? self.fileURL).urlByDeleteingPrivate();
        let newMovedURL = newURL.urlByDeleteingPrivate();
        let isMoved = (newMovedURL != prevURL);
        
        super.presentedItemDidMove(to: newURL);
        if(isMoved) {
            DispatchQueue.main.async { [weak self] in
                if let del = self?.delegate, del.responds(to: #selector(FTDocumentDelegate.documentDidGetRenamed(_:))) {
                    del.documentDidGetRenamed?(self);
                }
            }
        }
    }
    
    override func autosave(completionHandler: ((Bool) -> Void)? = nil) {
        if(self.openPurpose == .read) {
            FTLogError("Doc Auto Save in Readonly");
            completionHandler?(true);
        }
        else {
            super.autosave { [weak self] (success) in
                self?.previousFileModeificationDate = self?.fileModificationDate;
                completionHandler?(success);
            }
        }
    }
    
    //MARK:- Custom
    private func notifySecurityUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("FTDocumentDidGetSecurityUpdate"), object: nil);
    }
    
    private func revertDocument(withRevertURL url: URL, andCompletionHandler completionHandler: ((Bool) -> Void)?) {
        FTCLSLog("revertDocument");
        super.revert(toContentsOf: url, completionHandler:{ (success) in
            self.isInRevertMode = false;
            if(nil != completionHandler) {
                completionHandler!(success);
            }
        });
    }
    
    //MARK:- Template Info -
    func setTemplateValues(_ tempName : String,values : FTTemplateInfo)
    {
        if let fileItem = self.documentInfoPlist() {
            var documentsList = fileItem.object(forKey: DOCUMENTS_KEY) as? [String:AnyObject] ?? [String:AnyObject]();
            documentsList[tempName] = values.dictRepresenataion() as AnyObject;
            fileItem.setObject(documentsList, forKey: DOCUMENTS_KEY);
        }
    }
    
    func templateValues(_ tempName : String) -> FTTemplateInfo? {
        var tempInfo : FTTemplateInfo?;
        
        if let fileItem = self.documentInfoPlist(),
            let documentsList = fileItem.object(forKey: DOCUMENTS_KEY) as? [String:AnyObject],
            let info = documentsList[tempName] as? [String:AnyObject]  {
            tempInfo = FTTemplateInfo(info: info);
        }
        return tempInfo;
    }

    fileprivate func decryptedPasswordForDocumentName(_ documentName : String) -> String?
    {
        var password : String?;
        if let templateInfo = self.templateValues(documentName),
            let passwordEntered = templateInfo.password {
            password = passwordEntered;
        }
        return password;
    }
    
    //MARK:- Delete Unused Resource -
    fileprivate func deleteUnusedFileItems()
    {
        //Iterate through all the resources in resources folder and see if we can map it to any of the annotation or page. If we cant find any resource with this mapping mark it for deletion.
//        var existingResourceFileNames = Set<String>();
        var existingAnnotationFolderItemFileNames = Set<String>();
//        var existingTemplatesItemFileNames = Set<String>();

        let pages = self.pages();
        if(pages.isEmpty) {
            FTCLSLog("deleteUnusedFileItems: no pages found");
            return;
        }
        
        for eachPage in pages {
            autoreleasepool {
                let pdfPage = eachPage as! FTNoteshelfPage;
                
                existingAnnotationFolderItemFileNames.insert(pdfPage.sqliteFileName());
                //commented out the below code in v4.0.5 to optmize closing of book time as the annotation related file should be deleted when user deletes and save is issued. one more round of checking is not need at this level.Also since the pdfs are not deleting from our end unneccessary check is removed.
//                existingTemplatesItemFileNames.formUnion(pdfPage.usedTemplateFileNames());
//                #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
//                existingResourceFileNames.formUnion(pdfPage.resourceFileNames());
//                #endif
            }
        }
        
//        commented out the below code in v4.0.5
//        removing unused Resource file
//        self.deleteUnusedFilesIn(self.resourceFolderItem(), currentlyUsedItems: existingResourceFileNames);
        
        //removing unused annotations file
        self.deleteUnusedFilesIn(self.annotationFolderItem(), currentlyUsedItems: existingAnnotationFolderItemFileNames);
        
//        commented out the below code in v4.0.5
//        removing unused template files
//        self.deleteUnusedFilesIn(self.templateFolderItem(), currentlyUsedItems: existingTemplatesItemFileNames);
    }
    
    fileprivate func deleteUnusedFilesIn(_ folderFileItem : FTFileItem?,currentlyUsedItems : Set<String>)
    {
        if(nil == folderFileItem) {
            return;
        }
     
        let shouldAvoidDeletionOfTemplateFoloderItems = (folderFileItem == self.templateFolderItem());
        
        let folderContents = folderFileItem!.children;
        var folderContentNames =  Set<String>();
        
        for eachFileItem in folderContents!
        {
            folderContentNames.insert((eachFileItem as! FTFileItem).fileName);
        }
        
        folderContentNames.subtract(currentlyUsedItems);
        
        let itemsToDelete = Array(folderContentNames);
        for eachItem in itemsToDelete
        {
            let fileItem = folderFileItem!.childFileItem(withName: eachItem);
            if(fileItem != nil)
            {
                //TODO: Temporarily avoiding the deletion of template items as we found some issues where rawenc is getting appended to the pdf files from outside. 
                if(shouldAvoidDeletionOfTemplateFoloderItems) {
                    FTCLSLog("attemp to del : \(String(describing: fileItem!.fileName))");
                }
                else {
                    fileItem!.deleteContent();
                }
            }
        }
    }
   
    //MARK:- Observer add/remove -
    fileprivate func addObservers()
    {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FTDidChangePageProperties, object: self, queue: nil) { [weak self] (_) in
            if let documentInfoPlist = self?.documentInfoPlist() {
                let pages = documentInfoPlist.pages;
                documentInfoPlist.pages = pages;
            }
        }
        
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: nil) { [weak self] (_) in
            guard let weakSelfObject = self else {
                return;
            }
            objc_sync_enter(weakSelfObject);
            let pages = weakSelfObject.pages();
            for eachPage in pages {
                eachPage.unloadContents();
            }
            
            let templateFolderItem = weakSelfObject.templateFolderItem();
            if(nil != templateFolderItem) {
                let templateItems = templateFolderItem!.children;
                if(templateItems?.count ?? 0 > 0) {
                    FTCLSLog("⚠️ Mem warning received: unloading templates");
                }
                templateItems?.forEach({ (template) in
                    (template as? FTFileItem)?.unloadContentsOfFileItem();
                });
            }
            objc_sync_exit(weakSelfObject);
        };
        #endif
    }
    
    fileprivate func removeObservers()
    {
        NotificationCenter.default.removeObserver(self);
    }
    
    //MARK:- FTPrepareForImporting -
    func prepareForImporting(_ onCompletion: @escaping (Bool, NSError?) -> Void) {
        if(self.isPinEnabled()) {
            let propertyInfoPlist = self.fileURL.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(PROPERTIES_PLIST);
            let dictionary = NSMutableDictionary(contentsOf: propertyInfoPlist) ?? NSMutableDictionary();
            dictionary.setObject(FTUtils.getUUID(), forKey: DOCUMENT_ID_KEY as NSCopying);
            dictionary.write(to: propertyInfoPlist, atomically: true);

            let annotationFolderPath = self.fileURL.appendingPathComponent(ANNOTATIONS_FOLDER_NAME);
            if(!FileManager().fileExists(atPath: annotationFolderPath.path)){
                _ = try? FileManager().createDirectory(at: annotationFolderPath, withIntermediateDirectories: true, attributes: nil);
            }

            let resourcesFolderPath = self.fileURL.appendingPathComponent(RESOURCES_FOLDER_NAME);
            if(!FileManager().fileExists(atPath: resourcesFolderPath.path)){
                _ = try? FileManager().createDirectory(at: resourcesFolderPath, withIntermediateDirectories: true, attributes: nil);
            }
            #if !NOTESHELF_ACTION
            self.updateCoverForMigratedPinEnabledBooks()
            #endif
            onCompletion(true , nil);
        }
        else {
            self.openDocument(purpose: .write) { (success, error) in
                if(success) {
                    self.documentUUID = FTUtils.getUUID();

                    #if !NOTESHELF_ACTION
                        if self.URL.isNS2Book {
                            self.updateCoverForMigratedBooks { success, error in
                                saveAndClose()
                            }
                        } else {
                            saveAndClose()
                        }
                    #else
                        saveAndClose()
                    #endif
                    func saveAndClose() {
                        self.saveAndCloseWithCompletionHandler({ (success) in
                            onCompletion(success , success ? nil : FTDocumentTemplateImportErrorCode.error(.prepareForImportFailed));
                        })
                    }
                }
                else {
                    var docError = error;
                    if(nil == docError) {
                        docError = FTDocumentTemplateImportErrorCode.error(.prepareForImportFailed);
                    }
                    onCompletion(success , docError);
                }
            };
        }
    }
    
    #if !NOTESHELF_ACTION
    func updateCoverForMigratedPinEnabledBooks() {
        if self.URL.isNS2Book {
            let imageUrl = self.fileURL.appendingPathComponent("cover-shelf-image.png")
            if FileManager().fileExists(atPath: imageUrl.path) {
                let image = UIImage(contentsOfFile: imageUrl.path)
                if image?.coverStyle() == .default {
                    let propertyInfoPlist = self.fileURL.appendingPathComponent(METADATA_FOLDER_NAME).appendingPathComponent(PROPERTIES_PLIST);
                    let dictionary = NSMutableDictionary(contentsOf: propertyInfoPlist) ?? NSMutableDictionary();
                    dictionary.setValue(true, forKey: INSERTCOVER)
                    dictionary.write(to: propertyInfoPlist, atomically: true);
                } else {
                    if let lockedImage = UIImage(named: "locked") {
                        try? lockedImage.pngData()?.write(to: imageUrl)
                    }
                }
            }
        }
    }
    
    func insertCoverForPasswordProtectedBooks(onCompletion : @escaping ((Bool,NSError?) -> Void)) {
        self.updateCoverForMigratedBooks(onCompletion: onCompletion)
    }
    
    private func updateCoverForMigratedBooks(onCompletion : @escaping ((Bool,NSError?) -> Void)) {
        if self.shelfImage?.coverStyle() == FTCoverStyle.default {
            // If the document has cover then insert new page as cover.
            let coverInfo = FTDocumentInputInfo()
            coverInfo.isCover = true
            coverInfo.insertAt = 0
            var inputFileurl: URL?
            //NS2 cover size will be (136,180), hence resizing to NS3 cover size to show on shelf
            let coverSizeImage = self.shelfImage?.resizedImage(portraitCoverSize) // used to show thumbnail on shelf
            if let shelfImage {
                let newSize = CGSize(width: shelfImage.size.width * 2, height: shelfImage.size.height * 2)
                let pdfSizeImage = shelfImage.resizedImage(newSize)//used to show cover inside notebook
                let path = FTPDFFileGenerator().generateCoverPDFFile(withImages: [pdfSizeImage, coverSizeImage ?? shelfImage])
                inputFileurl = Foundation.URL(fileURLWithPath: path)
            }
            self.shelfImage = coverSizeImage
            if let url = inputFileurl, FileManager().fileExists(atPath: url.path) {
                coverInfo.inputFileURL = url
                self.insertFileFromInfo(coverInfo, onCompletion: { (success, error) in
                    onCompletion(success, error)
                })
            } else {
                onCompletion(false, nil)
            }
        } else {
            // Else, just update the cover image.
            self.shelfImage = self.generateCoverImage()
            onCompletion(true, nil)
        }
    }
    #endif
    fileprivate func isValidDocument() -> Bool
    {
        if(self.pages().isEmpty) {
            var params = ["Reason" : "page count 0"]
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
            if let documentVersion = self.propertyInfoPlist()?.object(forKey: DOCUMENT_VERSION_KEY) as? String {
                params["Doc ver"] = documentVersion
            }
            else{
            }
            #endif
            FTLogError("Doc Corrupt", attributes: params)
            return false;
        }
        
        return self.validateFileItemsForDocumentConsistancy();
    }
    
    fileprivate func isDocumentVersionSupported() -> Bool
    {
        let documentVersion = self.propertyInfoPlist()?.object(forKey: DOCUMENT_VERSION_KEY) as? String;
        if(nil == documentVersion) {
            let params = ["Reason" : "Metadata file Missing"]
            FTLogError("Doc Corrupt", attributes: params)
            return false;
        }
        
        let value = (documentVersion! as NSString).floatValue;
        if(value > APP_SUPPORTED_MAX_DOC_VERSION) {
            let params : [String: Any] = ["Reason" : "Old app ver",
                                          "Doc ver" : documentVersion ?? "unknown",
                                          "App Support ver" : APP_SUPPORTED_MAX_DOC_VERSION]
            FTLogError("Doc Corrupt", attributes: params)
            return false;
        }
        return true;
    }

    //MARK:- Duplicate Pages -
    //Starting Insert Index is consider only if pageInsertPosition is InBetween
    //NextToCurrent works only for duplicating pages within same document
    //None inserts page starting from 0
    //AtTheEnd always inserts at the end of the document
    //currentPageIndex always starts from 0
    internal func recursivelyCopyPages(_ pages : [FTPageProtocol],
                                       currentPageIndex : Int,
                                       startingInsertIndex : Int,
                                       pageInsertPosition : FTPageInsertPostion,
                                       onCompletion :@escaping ((Bool,NSError?,[FTPageProtocol]) -> Void)) -> Progress
    {
        let copiedPages : [FTPageProtocol] = [FTPageProtocol]();
        
        let progress = Progress();
        progress.totalUnitCount = Int64(pages.count);

        self._recursivelyCopyPages(pages, currentPageIndex: currentPageIndex,
                                   startingInsertIndex: startingInsertIndex,
                                   pageInsertPosition: pageInsertPosition,
                                   copiedPages: copiedPages,
                                   progress: progress,
                                   onCompletion: onCompletion)
        return progress;
    }
    
    fileprivate func _recursivelyCopyPages(_ pages : [FTPageProtocol],
                                           currentPageIndex : Int,
                                           startingInsertIndex : Int,
                                           pageInsertPosition : FTPageInsertPostion,
                                           copiedPages : [FTPageProtocol],
                                           progress: Progress,
                                           onCompletion :@escaping ((Bool,NSError?,[FTPageProtocol]) -> Void))
    {
        if(currentPageIndex < pages.count) {
            let page = pages[currentPageIndex];
            (page as? FTCopying)?.deepCopyPage?(self, onCompletion: { (copiedPage) in
                
                progress.completedUnitCount += 1;
                
                var indexToInsert = currentPageIndex;
                switch pageInsertPosition {
                case .none:
                    indexToInsert = currentPageIndex;
                case .inBetween:
                    indexToInsert = startingInsertIndex + currentPageIndex;
                case .nextToCurrent:
                    let pageIndex = self.pages().index(where: { (item) -> Bool in
                        if(item.uuid == page.uuid) {
                            return true;
                        }
                        return false;
                    });
                    indexToInsert = pageIndex!+1;
                case .atTheEnd:
                    indexToInsert = self.pages().count;
                }
                self.recoveryInfoPlist()?.addPageIndex(page.pageIndex(), pageUUID: copiedPage.uuid);
                self.documentInfoPlist()?.insertPage(copiedPage as! FTNoteshelfPage, atIndex: indexToInsert);
                var modifiedCopiedPages: [FTPageProtocol] = copiedPages;
                modifiedCopiedPages.append(copiedPage);
                let newIndex = currentPageIndex + 1;
                DispatchQueue.main.async {
                    self._recursivelyCopyPages(pages,
                                               currentPageIndex : newIndex,
                                               startingInsertIndex : startingInsertIndex,
                                               pageInsertPosition : pageInsertPosition,
                                               copiedPages : modifiedCopiedPages,
                                               progress: progress,
                                               onCompletion: onCompletion);
                }
            });
        }
        else {
            DispatchQueue.main.async {
                self.saveDocument(completionHandler: { (success) in
                    onCompletion(success,success ? nil : FTDocumentCreateErrorCode.error(.saveFailed),copiedPages);
                });
            }
        }
    }

    override func shouldIgnore(fromEncryption fileItemURL: URL!) -> Bool {
        var shouldIgnore = super.shouldIgnore(fromEncryption: fileItemURL);
        if(!shouldIgnore) {
            if(fileItemURL.lastPathComponent == "cover-shelf-image.png") {
                shouldIgnore = true;
            }
            else if(fileItemURL.lastPathComponent == "cover-band-image.png") {
                shouldIgnore = true;
            }
        }
        return shouldIgnore;
    }
    
    func updateDocumentVersionToLatest()
    {
        if let propertyPlist = self.propertyInfoPlist() {
            let documentVersion = propertyPlist.object(forKey: DOCUMENT_VERSION_KEY) as? String;
            if((nil == documentVersion) || (documentVersion! != DOC_VERSION)) {
                propertyPlist.setObject(DOC_VERSION, forKey: DOCUMENT_VERSION_KEY);
            }
        }
    }

    private func openDocumentAndUpdateLocalCache(onCompletion: @escaping () -> ()) {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        self.openDocument(purpose: .write) { (opensuccess, error) in
            if opensuccess {
                self.updateLocalCacheForNewlyCreatedDocumentIfNeeded()
                self.closeDocument { _ in
                    onCompletion()
                }
            }
            else {
                onCompletion()
            }
        }
        #else
        onCompletion()
        #endif
    }
    
    private func updateLocalCacheForNewlyCreatedDocumentIfNeeded()
    {
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        //check for global font availability if present follow step 1,2,3 or skip these steps
        if let fontInfo = FTUserDefaults.defaultFontFontAll() {
            if let size = fontInfo[FTFontStorage.fontSizeKey], let name = fontInfo[FTFontStorage.fontNameKey], let colorHex = fontInfo[FTFontStorage.textColorKey], let defaultUnderLine = fontInfo[FTFontStorage.isUnderlinedKey], let textAlignment = fontInfo[FTFontStorage.textAlignmentKey], let isLineSpaceEnabled = fontInfo[FTFontStorage.isLineSpaceEnabledKey], let lineSpace = fontInfo[FTFontStorage.lineSpaceKey], let strikeThrough = fontInfo[FTFontStorage.isStrikeThroughKey] {

                let numberFormatter = NumberFormatter()
                let sizeNum = numberFormatter.number(from: size)
                let floatSize = CGFloat(sizeNum?.floatValue ?? 10.0)

                let alignmentNum = numberFormatter.number(from: textAlignment)
                let intAlignment = alignmentNum?.intValue ?? 0

                let lineSpaceNum = numberFormatter.number(from: lineSpace)
                let intLineSpace = lineSpaceNum?.intValue ?? 0

                if let defaultFont = UIFont(name: name, size: floatSize) {
                    self.localMetadataCache?.defaultBodyFont = defaultFont
                    self.localMetadataCache?.defaultTextColor = UIColor(hexString: colorHex)
                    self.localMetadataCache?.defaultIsUnderline = (defaultUnderLine as NSString).boolValue
                    self.localMetadataCache?.defaultIsStrikeThrough = (strikeThrough as NSString).boolValue
                    self.localMetadataCache?.defaultTextAlignment = intAlignment
                    self.localMetadataCache?.defaultIsLineSpaceEnabled = (isLineSpaceEnabled as NSString).boolValue
                    self.localMetadataCache?.defaultAutoLineSpace = intLineSpace
                    self.localMetadataCache?.saveMetadataCache()
                }
            }
        }
        #endif
    }
}

extension FTNoteshelfDocument : FTDocumentSearchProtocol
{
    func cancelSearchOperation(onCompletion: (() -> ())?) {
        
        if(self.searchOperationQueue.operationCount == 0) {
            let allPages = self.pages();
            for eachPage in allPages {
                (eachPage as? FTPageSearchProtocol)?.searchingInfo = nil;
            }

            if(nil != onCompletion) {
                DispatchQueue.main.async(execute: {
                    onCompletion!();
                });
            }
            return;
        }
        
        self.searchOperationQueue.maxConcurrentOperationCount = 1;
        self.searchOperationQueue.cancelAllOperations();

        var operation : BlockOperation!;
        operation = BlockOperation();
        operation.addExecutionBlock { [weak self] in
            let allPages = self?.pages();
            if(nil != allPages) {
                for eachPage in allPages! {
                    autoreleasepool(invoking: {
                        (eachPage as? FTPageSearchProtocol)?.searchingInfo = nil;
                    });
                }
            }
        }
        
        operation.completionBlock = {
            if(nil != onCompletion) {
                DispatchQueue.main.async(execute: {
                    onCompletion!();
                });
            }
        }
        self.searchOperationQueue.addOperation(operation);
    }
    
    func searchDocumentsForKey(_ searchKey: String,
                               tags: [String],
                               onFinding: @escaping (_ page: FTPageProtocol, _ cancelled: Bool) -> Void,
                               onCompletion: @escaping (_ cancelled: Bool) -> Void) -> Progress
    {
        let searchProgress = Progress()
        searchProgress.cancellationHandler = { [weak self] in
            self?.cancelSearchOperation(onCompletion: nil);

        }
        self.searchOperationQueue.maxConcurrentOperationCount = 1;
        let allPages = self.pages();
        searchProgress.totalUnitCount = Int64(allPages.count)

        for eachPage in allPages {
            var operation : BlockOperation!;
            operation = BlockOperation();
            operation.addExecutionBlock { [weak eachPage,weak searchProgress,weak operation] in
                let isCancelled = operation?.isCancelled ?? false;
                if let searchingPage = eachPage as? FTPageSearchProtocol,
                   !isCancelled, searchingPage.searchFor(searchKey, tags: tags) {
                    onFinding(eachPage!,isCancelled);
                }

                if !isCancelled {
                    searchProgress?.completedUnitCount += 1
                }
            }
            self.searchOperationQueue.addOperation(operation);
        }
        
        var operation : BlockOperation!;
        operation = BlockOperation.init {
            
        };
        
        operation.completionBlock = {
            DispatchQueue.main.async(execute: {
                onCompletion(operation.isCancelled);
            });
        }
        
        self.searchOperationQueue.addOperation(operation);
        return searchProgress
    }
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
extension FTNoteshelfDocument : FTRecognitionHelper {
    var recognitionHelper: FTNotebookRecognitionHelper? {
        if _recognitionHelper == nil {
            _recognitionHelper = FTRecognitionServiceProvider.shared.getRecognitionService(forDocument: self)
        }
        return _recognitionHelper
    }
     
    @objc func releaseRecognitionHelperIfNeeded() {
        if let helper = self._recognitionHelper {
            FTRecognitionServiceProvider.shared.clearRecognitionHelper(helper)
        }
    }
    
    var visionRecognitionHelper: FTVisionNotebookRecognitionHelper? {
        if _visionRecognitionHelper == nil {
            _visionRecognitionHelper = FTRecognitionServiceProvider.shared.getVisionRecognitionService(forDocument: self)
        }
        return _visionRecognitionHelper
    }
     
    func releaseVisionRecognitionHelperIfNeeded() {
        if let helper = self._visionRecognitionHelper {
            FTRecognitionServiceProvider.shared.clearVisionRecognitionHelper(helper)
        }
    }
}

extension FTNoteshelfDocument: FTDocumentCoverPage {
    func generateCoverImage() -> UIImage? {
        self.fetchCoverImage(isPinEnabled: self.isPinEnabled())
    }
    
    func transparentThumbnail(isEncrypted: Bool) -> UIImage{
       let isPinEnabled = isEncrypted || isPinEnabled()
       return fetchCoverImage(isPinEnabled: isPinEnabled)
    }
   
    func fetchCoverImage(isPinEnabled: Bool) -> UIImage {
        guard let _shelfImage = self.shelfImage else {
                return UIImage(named: "defaultNoCover")!
        }
        let coverImageSize :CGSize
        var coverImage: UIImage?;
        if isPinEnabled {
            // Password protected :
            // If first page is cover, show standard cover with no strokes
            // Else just show locked icon
            if let page = self.pages().first, page.isCover {
                if let document = page.pdfPageRef?.document {
                    let pdfImage  = document.drawImagefromPdf()
                    coverImage = pdfImage
                }
            } else {
                coverImage = UIImage(named: "locked")
            }
        } else {
            if let page = self.pages().first {
                let pageRect = page.pdfPageRect
                if pageRect.width > pageRect.height {
                    // LandScape
                    if page.isCover {
                        coverImageSize = landscapeCoverSize
                    } else {
                        coverImageSize = landscapeNoCoverSize
                    }
                } else {
                    if page.isCover {
                        coverImageSize = portraitCoverSize
                    } else {
                        coverImageSize = portraitNoCoverSize
                    }
                }
                let shouldRenderBackground = page.isCover ? false : true
                if let overLayImage = FTPDFExportView.snapshot(forPage: self.pages().first,
                                                               size: coverImageSize,
                                                               screenScale: 2,
                                                               shouldRenderBackground: shouldRenderBackground,
                                                               offscreenRenderer: nil,
                                                               with: FTSnapshotPurposeThumbnail) {
                    coverImage = self.generateImageForStandardCover(page: page, overLayImage: overLayImage, shelfImage: _shelfImage, angle: page.rotationAngle, targetSize: coverImageSize)
                }
            }
        }
        if coverImage == nil && self.shelfImage != nil {
            coverImage = self.shelfImage
        }
        let newImage = coverImage ?? UIImage(named: "locked")!;
        return newImage;
    }
    
    //This is used when we are sharing pages.
    func shelfCoverImage(for pages: [FTPageProtocol]) -> UIImage {
        let coverImageSize :CGSize
        var coverImage: UIImage?;
        if let page = pages.first {
            let pageRect = page.pdfPageRect
            if pageRect.width > pageRect.height {
                // LandScape
                if page.isCover {
                    coverImageSize = landscapeCoverSize
                } else {
                    coverImageSize = landscapeNoCoverSize
                }
            } else {
                if page.isCover {
                    coverImageSize = portraitCoverSize
                } else {
                    coverImageSize = portraitNoCoverSize
                }
            }
            let shouldRenderBackground = page.isCover ? false : true
            if let image = FTPDFExportView.snapshot(forPage: page,
                                                           size: coverImageSize,
                                                           screenScale: 2,
                                                           shouldRenderBackground: true) {
                coverImage = image
            }
        }
        let newImage = coverImage ?? UIImage(named: "locked")!;
        return newImage
    }
    
    func generateImageForStandardCover(page: FTPageProtocol, overLayImage: UIImage, shelfImage: UIImage, angle: UInt, targetSize: CGSize) -> UIImage {
        if let document = page.pdfPageRef?.document {
            let pdfImage  = document.drawImagefromPdf(with: CGFloat(angle))
            let imageGenerator = FTFirstPageImageGenerator(withTargetSize: targetSize);
            let coverImage = imageGenerator.generateCoverImage(forImage: pdfImage ?? shelfImage, withCoverOverlayImage: overLayImage)
            return coverImage
        }
        return shelfImage
    }
}
#endif

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
extension FTNoteshelfDocument: FTDocumentRecoverPages {
    func recoverPagesFromDocumentAt(_ url: URL,onCompletion:@escaping (NSError?)->()) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = 1;
        let documentToInsert = FTDocumentFactory.documentForItemAtURL(url);
        guard let docInternalProtocol = documentToInsert as? FTDocumentProtocolInternal else {
            fatalError("\(documentToInsert) should implement FTDocumentProtocolInternal");
        }
        docInternalProtocol.openDocument(purpose: .read) { (success,error) in
            if(success) {
                let recoveryFileItem = (documentToInsert as? FTDocumentFileItems)?.rootFileItem?.childFileItem(withName: NOTEBOOK_RECOVERY_PLIST) as? FTNotebookRecoverPlist;
                
                self.recoverPagesRecursively(documentToInsert.pages(),
                                             recoverFileItem: recoveryFileItem) { (_, error) in
                    docInternalProtocol.closeDocument { (_) in
                        onCompletion(error);
                    }
                }
            }
            else {
                var docError = error;
                if(nil == docError) {
                    docError = FTDocumentTemplateImportErrorCode.error(.openFailed);
                }
                onCompletion(docError);
            }
        }
        return progress;
    }
    
    private func recoverPagesRecursively(_ pages:[FTPageProtocol],
                                         recoverFileItem: FTNotebookRecoverPlist?,
                                         onCompletion: @escaping ((Bool,NSError?) -> Void)) {
        
        var recoveryPages = pages
        let initialIndex = 0
        let eachPage = pages[initialIndex]
        let indexToInsert = recoverFileItem?.pageIndex(pageUUID: eachPage.uuid) ?? self.pages().count;
        
        _ = self.recursivelyCopyPages([eachPage],
                                      currentPageIndex: 0,
                                      startingInsertIndex: indexToInsert,
                                      pageInsertPosition: .inBetween) { (success, error, _) in
            if success {
                recoveryPages.removeFirst()
                if recoveryPages.isEmpty {
                    if self.shouldGenerateCoverThumbnail,
                        let finalImage = self.generateCoverImage() {
                        self.shelfImage = finalImage
                        FTURLReadThumbnailManager.sharedInstance.addImageToCache(image: finalImage, url: self.URL);
                        self.saveDocument { (_) in
                            onCompletion(success, nil)
                        }
                    } else {
                        onCompletion(success, nil)
                    }
                } else {
                    self.recoverPagesRecursively(recoveryPages,
                                                 recoverFileItem: recoverFileItem,
                                                 onCompletion: onCompletion)
                }
            } else {
                onCompletion(false, error)
            }
        }
    }
}
#endif

//MARK:- Delegate observers -
extension FTNoteshelfDocument {
    func addListner(_ listener: FTNoteshelfDocumentDelegate) {
        let hashKey = listener.hash;
        if nil == self.documentListners[hashKey] {
            let docDel = FTNSDocumentListener();
            docDel.documentDelegate = listener;
            self.documentListners[listener.hash] = docDel;
        }
        self.delegate = self;
    }
    
    func removeListner(_ listener: FTNoteshelfDocumentDelegate) {
        let hashKey = listener.hash;
        self.documentListners.removeValue(forKey: hashKey);
    }
}

//MARK:- FTNoteshelfDocumentDelegate -
extension FTNoteshelfDocument: FTNoteshelfDocumentDelegate {
    
    func documentDidReceiveConflict(_ document: FTDocument!, conflictingVersions versions: [Any]!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidReceiveConflict?(document, conflictingVersions: versions);
        }
    }

    func documentDidResolveConflict(_ document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidResolveConflict?(document);
        }
    }
    
    func documentDidDelete(_ document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidDelete?(document);
        }
    }

    func documentDidFail(toSave document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidFail?(toSave: document);
        }
    }

    func document(_ document: FTDocument!, didChange state: UIDocument.State) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.document?(document, didChange: state);
        }
    }
    
    
    func documentWillGetReloaded(_ document: FTDocument!, onCompletion completionBLock: (() -> Void)!) {
        var counter = self.documentListners.count;
        func decrementCounter() {
            counter -= 1;
            if(counter == 0) {
                completionBLock();
            }
        }
        
        self.documentListners.forEach { (key,value) in
            if let del = value.documentDelegate, del.responds(to: #selector(FTDocumentDelegate.documentWillGetReloaded(_:onCompletion:))) {
                del.documentWillGetReloaded?(document, onCompletion: {
                    decrementCounter();
                });
            }
            else {
                decrementCounter();
            }
        }
    }

    func documentDidGetReloaded(_ document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidGetReloaded?(document)
        }
    }

    func documentWillGetRenamed(_ document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentWillGetRenamed?(document)
        }
    }
    
    func documentDidGetRenamed(_ document: FTDocument!) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentDidGetRenamed?(document)
        }
    }
    
    func documentWillStartSaving(_ document: FTDocumentProtocol) {
        self.documentListners.forEach { (key,value) in
            value.documentDelegate?.documentWillStartSaving(document)
        }
    }
}

enum FTBoolValue: String {
    case TRUE = "true"
    case FALSE = "false"
}

extension Bool {
    var boolToString: String {
        return self ? FTBoolValue.TRUE.rawValue : FTBoolValue.FALSE.rawValue
    }
}

extension String {
    var stringToBool: Bool {
        return self == FTBoolValue.TRUE.rawValue ? true : false
    }
}
