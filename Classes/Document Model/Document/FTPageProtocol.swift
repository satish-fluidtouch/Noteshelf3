//
//  FTPage.swift
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

@objc protocol FTPageTagsProtocol : NSObjectProtocol
{
    func tags() -> [String];
    func addTag(_ tag : String);
    func addTags(tags: [String])
    func removeTag(_ tag : String);
    func rename(tag: String, with title:String)
    func removeAllTags()
}

@objc protocol FTPageProtocol : NSObjectProtocol {
    var uuid : String {get};
    var parentDocument : FTDocumentProtocol? {get};

    var lineHeight : Int {get set};
    var bottomMargin: Int {get set};
    var topMargin: Int {get set};
    var leftMargin: Int {get set};

    var isDirty : Bool {get set};
    var isFirstPage : Bool {get set};
    var isPageModified : Bool {get set};
    var associatedPDFPageIndex : Int {get set};
    var associatedPDFKitPageIndex : UInt {get}; //Since in PDFKIt page index starts from 0 instead of 1 [in case of coregraphics pdfdocument) whereenver the PDFPage is requested from PDFDocument of PDFKIT this method needs to be called.
    
    var associatedPDFFileName : String! {get set};
    var deviceModel : String {get set};
    
    var creationDate : NSNumber! {get set};
    var lastUpdated : NSNumber! {get set};
    var isBookmarked : Bool {get set};
    var bookmarkTitle: String! {get set};
    var bookmarkColor: String! {get set};

    var pdfPageRef : PDFPage? { get };
    var pdfPageRect : CGRect { get set};
    ///Angle in Degrees, with multiples of `90`
    var rotationAngle : UInt { get };
    var templateInfo: FTTemplateInfo {get};

    func pageReferenceViewSize() -> CGSize;

    func pageIndex() -> Int;
    
    @objc optional func pdfscale(inRect : CGRect) -> CGFloat;
    
    var zoomTargetOrigin: CGPoint {get set};
    func resetRotation()
    var isCover: Bool {get set}
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    var recognitionInfo : FTRecognitionResult? {get set};
    var visionRecognitionInfo : FTVisionRecognitionResult? {get set};

    func annotations() -> [FTAnnotation];
    func audioAnnotations() -> [FTAnnotation];


    func unloadContents();
    func thumbnail() -> FTPageThumbnailProtocol?;
    /// Angle should be non-negative multiples of 90° and less than 360
    func rotate(by angle: UInt)
    func hasPDFText() -> Bool
    #endif
}

@objc protocol FTPageAnnotationFindBounds : NSObjectProtocol
{
    //pass null for consider full page
    func findDefaultAudioRect(current :CGRect) -> CGRect;
}

@objc protocol FTPageBackgroundColorProtocol : NSObjectProtocol {
    func pageBackgroundColor(onCompletion : @escaping (UIColor?)->());
    var pageBackgroundColor: UIColor? { get }
    func updateBackgroundColor(color: UIColor)
}
