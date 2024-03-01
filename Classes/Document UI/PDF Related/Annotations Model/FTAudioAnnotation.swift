//
//  FTAudioAnnotation.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

@objcMembers class FTAudioAnnotation: FTAnnotation,FTAudioAnnotationProtocol,FTImageRenderingProtocol {
    func associatedNotebookPage() -> FTPageProtocol? {
        return self.associatedPage;
    }
    
    var isHidden: Bool {
        return self.hidden
    }

    override var allowsLassoSelection : Bool {
        return false;
    }

    fileprivate var _imageToRenderTexture : MTLTexture?;
    
    func textureToRender(scale : CGFloat) -> MTLTexture? {
        objc_sync_enter(self);
        if(nil == _imageToRenderTexture || self.currentScale != scale) {
            self.currentScale = scale;
            let image = self.getRecordingIcon();
            _imageToRenderTexture = FTMetalUtils.texture(from: image);
        }
        objc_sync_exit(self);
        return _imageToRenderTexture;
    }

    override var boundingRect: CGRect {
        willSet {
            if(self.boundingRect != CGRect.null && self.boundingRect != newValue) {
                self.markAsDirty();
            }
        }
    }
    
    var audioFileName : String = "" {
        didSet {
            self.audioName = uniqueFileName(for: audioFileName)
        }
    }
    
    var audioName : String = "Recording" {
        willSet {
            if(self.audioName != newValue) {
//                self.markAsDirty();
            }
        }
    };
    
    var screenScale : Float = Float(UIScreen.main.scale);
    var audioState : AudioSessionState = .stateNone
    
    var recordingModel: FTAudioRecordingModel!;
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.screenScale = aDecoder.decodeFloat(forKey: "screenScale");
        if(self.screenScale == 0) {
            self.screenScale = Float(UIScreen.main.scale);
        }
        self.audioName = aDecoder.decodeObject(forKey: "audioName") as? String ?? "";
        
        self.addRequiredObservers();
    }
    
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder);
        if(self.copyMode) {
            aCoder.encode(self.recordingModel, forKey: "recordingModel");
        }
        aCoder.encode(screenScale, forKey: "screenScale");
        aCoder.encode(self.audioName, forKey: "audioName");
    }
    
    static func annotationWithFilePath(_ path : String,
                                       page : FTPageProtocol,
                                       onCompletion : @escaping (FTAnnotation?)->())
    {
        let audioAnnotation = FTAudioAnnotation.init(withPage : page);
        let pageRect = page.pdfPageRect;
        var rect = CGRect.init(x: pageRect.width-audioRecordSize-audioRecordSize*0.5,
                               y: audioRecordSize*0.5,
                               width: audioRecordSize,
                               height: audioRecordSize);
        rect = (page as! FTPageAnnotationFindBounds).findDefaultAudioRect(current: rect);
        audioAnnotation.boundingRect = rect
        let model = FTAudioTrackModel.init(filePath: path);
        let date = Date();
        model.startTimeInterval = date.timeIntervalSinceReferenceDate;
        let sourceAudioFileURL = URL.init(fileURLWithPath: path);
        
        let destFileItem  = audioAnnotation.resourceFileItem(trackFileName: model.audioFileName);
        
        let audioAsset = AVURLAsset.init(url: sourceAudioFileURL);
        let audioDuration = audioAsset.duration;
        let audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        
        model.endTimeInterval = date.addingTimeInterval(audioDurationSeconds).timeIntervalSinceReferenceDate;
        audioAnnotation.addAudio(model);
        
        FileManager.copyCoordinatedItemAtURL(sourceAudioFileURL,
                                             toNonCoordinatedURL: destFileItem!.fileItemURL) { (success, error) in
                                                if(nil != error) {
                                                    onCompletion(nil);
                                                }
                                                else {
                                                    onCompletion(audioAnnotation);
                                                }
        }
    }
    
    override var supportsUndo: Bool {
        return false;
    }
    
    override var annotationType : FTAnnotationType {
        return .audio;
    }

    override init() {
        super.init();
        self.recordingModel = FTAudioRecordingModel.init(fileName: self.uuid);
        self.recordingModel.representedObject = self;
        self.addRequiredObservers();
    }
    
    deinit {
        self.removeRequiredObservers();
    }
    
    convenience init(attributes dict : Dictionary<String, Any>) {
        self.init()
        self.updateWithAttributesDict(dict);
        self.addRequiredObservers();
    }
    
    func addAudio(_ model : FTAudioTrackModel)
    {
        self.recordingModel.addAudioTrack(model);
    }
    
    func removeAudio(_ model : FTAudioTrackModel)
    {
        self.recordingModel.removeAudioTrack(model);
    }
    
    override var isEditingInProgress : Bool {
        return self.recordingModel.isCurrentAudioRecording();
    };

    override func loadContents() {
        self.removeRequiredObservers();
        let dict = self.annotationInfoFileItem()?.contentDictionary;
        self.updateWithAttributesDict(dict as? Dictionary<String, Any>);
        self.addRequiredObservers();
    }
    
    override func saveContents() -> Bool {
        let content = self.dictionaryRepresentation();
        self.annotationInfoFileItem()?.content = content as NSObjectProtocol;
        self.annotationInfoFileItem()?.saveContentsOfFileItem();
        return true;
    }
    
    override func resourceFileNames() -> [String]? {
        var fileNames = [String]();
        fileNames.append(self.annotationInfoPlistName());
        self.recordingModel.audioTracks().forEach { (model) in
            if let fileName = (model as? FTAudioTrackModel)?.audioFileName {
                fileNames.append(fileName);
            }
        }
        return fileNames;
    }
    
    override func unloadContents() {
        
    }
    
    func audioFileURL(_ track: String) -> URL? {
        let audioFileItem = self.resourceFileItem(trackFileName: track);
        return audioFileItem?.fileItemURL;
    }
    
    override func setOffset(_ offset: CGPoint) {
        if(offset != CGPoint.zero) {
            var newBoundingRect = self.boundingRect;
            newBoundingRect.origin = CGPointTranslate(newBoundingRect.origin, offset.x, offset.y);
            self.boundingRect = newBoundingRect;
            self.associatedPage?.isDirty = true;
        }
    }
    
    func isPointInside(_ point: CGPoint) -> Bool {
        if(self.boundingRect.contains(point)){
            let path = UIBezierPath.init(roundedRect: self.boundingRect, cornerRadius: self.boundingRect.width/2);
            if(path.contains(point)) {
                return true;
            }
        }
        return false;
    }
    override var supportsENSync : Bool {
        return false;
    }
}

//MARK:- Private
extension FTAudioAnnotation
{
    private func uniqueFileName(for audioName: String) -> String
    {
        var count = 0;
        var newDocName = audioName;
        
        var nameExists = true;
        while (nameExists) {
            if(count == 0) {
                newDocName = "\(audioName)";
            }
            else {
                newDocName = "\(audioName) \(count)";
            }
            nameExists = self.filenNameExists(audioName: newDocName)
            if(nameExists == false) {
                break;
            }
            else {
                count += 1;
            }
        }
        return newDocName;
    }
    
   private func filenNameExists(audioName: String) -> Bool {
        let audioAnnotations = self.associatedPage?.audioAnnotations()
        var nameExists = false
        audioAnnotations?.forEach({ eachAnn in
            if let ann = eachAnn as? FTAudioAnnotation, ann.audioName == audioName {
                nameExists = true
            }
        })
        return nameExists
    }
    
    fileprivate func dictionaryRepresentation() -> Dictionary<String,Any>
    {
        var info = [String : Any]();
        info["screenScale"] = NSNumber.init(value: self.screenScale);
        info["audioName"] = self.audioName;
        info["recordingModel"] = self.recordingModel.dictionaryRepresentation();
        return info;
    }
    
    fileprivate func markAsDirty()
    {
        if let page = self.associatedPage {
            self.modifiedTimeInterval = Date.timeIntervalSinceReferenceDate;
            page.isDirty = true;
        }
    }

    fileprivate func updateWithAttributesDict(_ dict : Dictionary<String,Any>?)
    {
        if nil != dict {
            self.screenScale = (dict!["screenScale"] as? NSNumber)?.floatValue ?? Float(UIScreen.main.scale);
            self.recordingModel = FTAudioRecordingModel.init(dict: dict!["recordingModel"] as? Dictionary<String,Any>);
            self.audioName = dict!["audioName"] as? String ?? ""
            self.recordingModel.representedObject = self;
        }
    }

    fileprivate func addRequiredObservers()
    {
        self.addObserver(self, forKeyPath: "recordingModel.audioTracks",
                         options: NSKeyValueObservingOptions.new,
                         context: nil);
    }
    
    fileprivate func removeRequiredObservers()
    {
        self.removeObserver(self, forKeyPath: "recordingModel.audioTracks");
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        if(!self.copyMode && keyPath == "recordingModel.audioTracks") {
            self.markAsDirty();
        }
    }
    
    fileprivate func annotationInfoFileItem() -> FTFileItemPlist?
    {
        var fileItem : FTFileItemPlist?
        if let doc = self.associatedPage?.parentDocument as? FTNoteshelfDocument {
            fileItem = doc.resourceFolderItem()?.childFileItem(withName: self.annotationInfoPlistName()) as? FTFileItemPlist;
            if(nil == fileItem) {
                fileItem = FTFileItemPlist.init(fileName: self.annotationInfoPlistName());
                fileItem?.securityDelegate = doc;
                doc.resourceFolderItem()?.addChildItem(fileItem!);
            }
        }
        return fileItem;
    }
    
    fileprivate func resourceFileItem(trackFileName : String) -> FTFileItemAudio?
    {
        var audioFileItem : FTFileItemAudio?
        if let doc = (self.associatedPage?.parentDocument as? FTNoteshelfDocument) {
            if let resourcesFolderItem = doc.resourceFolderItem() {
                audioFileItem = resourcesFolderItem.childFileItem(withName: trackFileName) as? FTFileItemAudio;
                if(nil == audioFileItem) {
                    audioFileItem = FTFileItemAudio.init(fileName: trackFileName);
                    audioFileItem?.securityDelegate = doc;
                    resourcesFolderItem.addChildItem(audioFileItem);
                }
            }
        }
        return audioFileItem;
    }

    fileprivate func annotationInfoPlistName() -> String
    {
        return self.uuid.appending(".plist");
    }
    
    internal func getRecordingIcon() -> UIImage
    {
        return UIImage(named: "audioIcon")!
    }
}

//MARK:- FTCopying
extension FTAudioAnnotation
{
    override func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        let annotation = FTAudioAnnotation.init(withPage : toPage);
        annotation.isReadonly = self.isReadonly;
        annotation.version = self.version;
        annotation.boundingRect = self.boundingRect;
        
        annotation.removeRequiredObservers();
        annotation.recordingModel = self.recordingModel.copy() as? FTAudioRecordingModel;
        annotation.audioName = self.audioName;

        annotation.recordingModel.representedObject = annotation;
        annotation.recordingModel.fileName = annotation.uuid;
        annotation.screenScale = self.screenScale;
        annotation.addRequiredObservers();

        let content = annotation.dictionaryRepresentation();
        annotation.annotationInfoFileItem()?.content = content as NSObjectProtocol;
        var sourceTrackNames = [String]();
        self.recordingModel.audioTracks().forEach { (item) in
            let model = item as! FTAudioTrackModel;
            sourceTrackNames.append(model.audioFileName);
        }
        
        var targetTrackNames = [String]();
        annotation.recordingModel.audioTracks().forEach { (item) in
            let model = item as! FTAudioTrackModel;
            targetTrackNames.append(model.audioFileName);
        }

        self.copyTracks(sourceTrackNames,
                        fromPage: self.associatedPage!,
                        toTrackNames: targetTrackNames,
                        toPage: toPage,
                        currentIndex: 0) { (error) in
                            if(nil != error) {
                                onCompletion(nil);
                            }
                            else {
                                onCompletion(annotation);
                            }
        }
    }
    private func copyTracks(_ sourceTrackNames : [String],
                            fromPage sourcePage : FTPageProtocol,
                            toTrackNames targetTrackNames : [String],
                            toPage destPage : FTPageProtocol,
                            currentIndex index : Int,
                            onCompletion completion :@escaping (Error?)->())
    {
        guard (index < sourceTrackNames.count) else {
            completion(nil);
            return
        }

        var currentIndex = index;
        let fileName = sourceTrackNames[index];

        guard let sourceDocument = sourcePage.parentDocument as? FTDocumentFileItems,
              let sourceFileItem = sourceDocument.resourceFolderItem()?.childFileItem(withName: fileName),
              let document = destPage.parentDocument as? FTNoteshelfDocument,
              let destinationResourceFolder = document.resourceFolderItem() else {
            completion(NSError.init() as Error);
            return
        }

        let targetFileName = targetTrackNames[index];
        let destinationURL = destinationResourceFolder.fileItemURL.appending(path: targetFileName, directoryHint: URL.DirectoryHint.notDirectory)

        guard let copiedFileItem = FTFileItemAudioTemporary(url: destinationURL, sourceURL: sourceFileItem.fileItemURL) else {
            completion(nil);
            return
        }
        copiedFileItem.securityDelegate = document
        destinationResourceFolder.addChildItem(copiedFileItem);

        // TODO: (AK) Work around to make the FileItem modfied to true, as we are not using direct approach for audio file items
        copiedFileItem.updateContent(NSObject())

        currentIndex += 1;

        self.copyTracks(sourceTrackNames,
                        fromPage: sourcePage,
                        toTrackNames: targetTrackNames,
                        toPage: destPage,
                        currentIndex: currentIndex,
                        onCompletion: completion);
    }
}

//MARK:- FTDeleting
extension FTAudioAnnotation
{
    override func willDelete() {
        let recordingModel = self.recordingModel;
        if let document = self.associatedPage?.parentDocument as? FTDocumentFileItems {
            let fileItem = document.resourceFolderItem()?.childFileItem(withName: self.annotationInfoPlistName())
            fileItem?.deleteContent();
            self.recordingModel.audioTracks().forEach { (item) in
                let model = item as! FTAudioTrackModel;
                let audioFileItem = document.resourceFolderItem()?.childFileItem(withName: model.audioFileName);
                audioFileItem?.deleteContent();
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.FTAudioAnnotationDidGetDeleted, object: recordingModel);
    }
}

//MARK:- FTAnnotationContainsProtocol
extension FTAudioAnnotation : FTAnnotationContainsProtocol
{
    func intersectsPath(_ inSelectionPath: CGPath, withScale scale: CGFloat, withOffset selectionOffset: CGPoint) -> Bool {
        var result = false;
        
        var selectionPathBounds = inSelectionPath.boundingBox;
        selectionPathBounds.origin = CGPoint.init(x: selectionPathBounds.origin.x+selectionOffset.x,
                                                  y: selectionPathBounds.origin.y+selectionOffset.y);
        let boundingRect1 = CGRectScale(self.boundingRect, scale);
        if(boundingRect1.intersects(selectionPathBounds)) {
            result = true;
        }
        return result;
    }
}

//MARK:- Export
extension FTAudioAnnotation
{
    @objc func prepareAnnotationForExport(onUpdate : @escaping (Float)->(),
                                    onCompletion : @escaping (URL?,Error?) -> ())
    {
        self.recordingModel.combineTracks(for: self, update: onUpdate, onCompletion: onCompletion)
    }
}

extension FTAudioAnnotation : NSSecureCoding {
    public class var supportsSecureCoding: Bool {
        return true;
    }
}
