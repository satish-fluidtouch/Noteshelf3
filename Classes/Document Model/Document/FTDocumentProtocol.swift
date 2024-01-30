//
//  FTDocumentProtocol.swift
//  Noteshelf
//
//  Created by Amar on 25/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

@objc enum FTDocumentOpenPurpose : Int
{
    case write;
    case read;
}

// Item refers - a document or page(based on context)
@objc enum FTItemPurpose: Int {
    case `default`;
    case trashRecovery;
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
@objc protocol FTRecognitionHelper {
    func releaseRecognitionHelperIfNeeded();
    var recognitionHelper: FTNotebookRecognitionHelper? {get};
    var recognitionCache: FTRecognitionCache? {get};
    
    func releaseVisionRecognitionHelperIfNeeded();
    var visionRecognitionHelper: FTVisionNotebookRecognitionHelper? {get};
}

protocol FTDocumentRecoverPages: NSObjectProtocol {
    func recoverPagesFromDocumentAt(_ url: URL,onCompletion:@escaping  (NSError?)->()) -> Progress;
}
#endif
protocol FTDocumentProtocolInternal: NSObjectProtocol {
    var documentState : UIDocument.State  {get};
    var URL : Foundation.URL {get};
    var documentUUID : String {get};
    func openDocument(purpose: FTDocumentOpenPurpose, completionHandler: ((Bool,NSError?) -> Void)?);
    func closeDocument(completionHandler: ((Bool) -> Void)?);
    func prepareForClosing();
    func saveAndCloseWithCompletionHandler(_ onCompletion :((Bool) -> Void)?)
}

@objc protocol FTDocumentProtocol : NSObjectProtocol {
    //Doc Default Properties
    var documentUUID : String {get};
    var shelfImage : UIImage? {get set};
    var hasNS1Content : Bool {get set};
    var isDirty : Bool {get set};
    var isJustCreatedWithQuickNote: Bool {get set};
    
    @objc optional func addListner(_ listner: FTNoteshelfDocumentDelegate);
    @objc optional func removeListner(_ listner: FTNoteshelfDocumentDelegate);

    var undoManager : UndoManager { get };
    
    init(fileURL : Foundation.URL);
    var URL : Foundation.URL {get};

    var hasAnyUnsavedChanges : Bool {get};
    var shouldGenerateCoverThumbnail : Bool {get};
    var wasPinEnabled : Bool {get set};
    func isPinEnabled() -> Bool;
    func resetPageModificationStatus()
    //Doc insert/create
    func createDocument(_ info : FTDocumentInputInfo,onCompletion : @escaping  ((NSError?,Bool) -> Void));
    
    func insertFile(_ info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void));
    
    func updatePageTemplate(page : FTPageProtocol,info : FTDocumentInputInfo,onCompletion: @escaping ((NSError?, Bool) -> Void));

    //Doc creation from selectedPages
    func createDocumentAtTemporaryURL(_ toURL : Foundation.URL,
                                      purpose: FTItemPurpose,
                                      fromPages : [FTPageProtocol],
                                      documentInfo: FTDocumentInputInfo?,
                                      onCompletion : @escaping ((Bool,NSError?) -> Void)) -> Progress;

    //Doc insertion at index
    func insertDocumentAtURL(_ url : Foundation.URL,
                             atIndex : Int,
                             onCompletion : @escaping ((Bool,NSError?) -> Void)) -> Progress;

    //page operation
    func pages() -> [FTPageProtocol];
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @discardableResult func insertPageAbove(page: FTPageProtocol) -> FTPageProtocol?;
    @discardableResult func insertPageBelow(page: FTPageProtocol) -> FTPageProtocol?;
    @discardableResult func insertPageAtIndex(_ index : Int) -> FTPageProtocol?;
    #endif
    //Delete Tag from all pages
    func deleteTag(_ tagName : String);
    func allTags() -> Set<String>;
    
    //Document Operation
    var documentState : UIDocument.State  {get};
    func saveDocument(completionHandler: ((Bool) -> Void)?);
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    @objc(revertToContentsOfURL:completionHandler:) func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)?);
    var pdfOutliner : FTPDFOutliner? {get};
    #endif

    //local Meta date cache
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    var localMetadataCache : FTDocumentLocalMetadataCacheProtocol? { get };
    var thumbnailGenerator: FTThumbnailGenerator? { get }
    func cancelAllThumbnailGeneration()
    #endif
    
    func updateDocumentVersionToLatest();
}

#if  !NS2_SIRI_APP && !NOTESHELF_ACTION
@objc protocol FTDocumentCoverPage {
    func generateCoverImage() -> UIImage?;
}
#endif

@objc protocol FTDocumentLocalMetadataCacheProtocol : NSObjectProtocol
{
    //Local Cache
    func saveMetadataCache();
    var lastViewedPageIndex : Int {get set};
        
    var shapeDetectionEnabled : Bool {get set};
    var currentDeskMode : RKDeskMode {get set};
    var lastPenMode : RKDeskMode {get set};

    var zoomModeEnabled : Bool {get set};
    var zoomFactor : CGFloat {get set};
    var zoomPalmRestHeight : CGFloat {get set};
    var zoomAutoscrollWidth : Int {get set};
    var zoomLeftMargin : CGFloat {get set};
    
    var zoomPanelButtonPositionIsLeft : Bool {get set};
    var zoomPanelAutoAdvanceEnabled : Bool {get set};
    var zoomPanelLineHeightGuideEnabled : Bool {get set};
    
    var defaultBodyFont: UIFont {get set}
    var defaultTextColor: UIColor {get set}
    var defaultIsUnderline: Bool {get set}
    var defaultIsStrikeThrough: Bool {get set}
    var defaultTextAlignment: Int {get set}
    var defaultAutoLineSpace: Int {get set}
    var defaultIsLineSpaceEnabled: Bool {get set}
    func zoomOrigin(for pageIndex: Int) -> CGPoint;
    func setZoomOrigin(_ point:CGPoint,for index: Int);
}
