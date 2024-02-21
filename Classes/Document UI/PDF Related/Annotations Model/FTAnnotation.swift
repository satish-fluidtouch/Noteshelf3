//
//  FTAnnotation.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

@objc protocol FTAnnotationContainsProtocol {
    func isPointInside(_ point : CGPoint) -> Bool;
    func intersectsPath(_ inSelectionPath : CGPath,withScale scale:CGFloat,withOffset selectionOffset: CGPoint) -> Bool
}

@objc protocol FTAnnotationDidAddToPageProtocol {
    func didMoveToPage();
}

protocol FTAnnotationErase
{
    func canErase(eraseRect rects: [CGRect]) -> Bool;
}

protocol FTAnnotationStrokeErase
{
    func eraseSegments(in rects : [CGRect],addTo segCache : FTSegmentTransientCache) -> CGRect
}


@objcMembers class FTAnnotation : NSObject, FTAnnotationProtocol,NSCoding
{
    var boundingRect : CGRect = CGRect.null
    var forceRender : Bool = false;

    var uuid : String = UUID().uuidString;
    var groupId : String?

    var hidden : Bool = false;
    var modifiedTimeInterval : TimeInterval = Date.timeIntervalSinceReferenceDate;
    var createdTimeInterval : TimeInterval = Date.timeIntervalSinceReferenceDate;
    var isReadonly : Bool = false;
    var version : Int = 1;
    var isLocked : Bool = false;
    var inLineEditing = false
    var currentScale : CGFloat = 0;
    var copyMode : Bool = false;
    var isEditingInProgress : Bool {
        return false;
    };

    weak var associatedPage : FTPageProtocol?;
    
    var supportsUndo : Bool {
        return true;
    }
    
    var renderingRect : CGRect {
        return self.boundingRect
    };
    
    var annotationType : FTAnnotationType {
        return .none;
    }
    
    var allowsResize : Bool {
        return false;
    }

    var allowsLocking: Bool {
        return false
    }

    var allowsLassoSelection : Bool {
        return !self.isReadonly && !self.isLocked
    }

    var allowsEditing : Bool {
        return false;
    }
    
    var supportsZoomMode: Bool {
        return false
    }
    
    var isMediaType: Bool {
        return (self.annotationType == .image || self.annotationType == .sticker || self.annotationType == .webclip || self.annotationType == .audio)
    }

    override init()
    {
        super.init();
        self.version = type(of: self).defaultAnnotationVersion();
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRecieveMemoryWarning(_:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil);
    }
    
    convenience init(withPage page : FTPageProtocol?)
    {
        self.init();
        self.associatedPage = page;
    }

    required init?(coder aDecoder: NSCoder) {
        super.init();
        if let uniqueId = aDecoder.decodeObject(forKey: "uuid") as? String {
            self.uuid = uniqueId;
        }
        self.isReadonly = aDecoder.decodeBool(forKey: "isReadonly");
        self.version = aDecoder.decodeInteger(forKey: "version");
        #if !targetEnvironment(macCatalyst)
        self.boundingRect = aDecoder.decodeCGRect(forKey: "boundingRect");
        #else
        if let boundRect = aDecoder.decodeObject(forKey: "boundingRect") as? NSValue {
            self.boundingRect = boundRect.cgRectValue;
        }
        #endif
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.uuid, forKey: "uuid");
        aCoder.encode(self.isReadonly, forKey: "isReadonly");
        aCoder.encode(self.version, forKey: "version");
        #if !targetEnvironment(macCatalyst)
            aCoder.encode(self.boundingRect, forKey: "boundingRect");
        #else
        aCoder.encode(NSValue(cgRect: self.boundingRect), forKey: "boundingRect");
        #endif
    }

    private var selectedDict = [Int:Bool]();
    func setSelected(_ val:Bool,for windowHash:Int) {
        let hashKey = windowHash;
        if(val) {
            selectedDict[hashKey] = true;
        }
        else {
            selectedDict.removeValue(forKey: hashKey);
        }
    }
    
    func isSelected(for windowHash: Int?) -> Bool {
        let hashKey = windowHash ?? 0;
        return selectedDict[hashKey] ?? false;
    }
    
    func loadContents()
    {
        
    }

    func saveContents() -> Bool
    {
        return true;
    }
    
    func unloadContents()
    {
        
    }

    func setOffset(_ offset : CGPoint)
    {
        
    }

    func setRotation(_ angle: CGFloat, refPoint: CGPoint) {

    }

    func resourceFileNames() -> [String]?
    {
        return nil;
    }
    
    var supportsENSync : Bool {
        return true;
    }
    
    class func defaultAnnotationVersion() -> Int {
        return Int(4);
    }
    
    var shouldAlertForMigration : Bool {
        return false;
    }
    
    var supportsHandwrittenRecognition : Bool {
        return false;
    }

    func repairIfRequired() -> Bool {
        //As of v8.3, we're repairing only Stroke Annotation.
        return false
    }
    
    func canSelectUnderLassoSelection() -> Bool {
        return true
    }
    
    func canCancelEndEditingAnnotaionWhenPopOverPresents() -> Bool {
        return false
    }
}

extension FTAnnotation : FTAnnotationDidAddToPageProtocol
{
    func didMoveToPage() {
        
    }
}

extension FTAnnotation : FTCopying
{
    func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotation?) -> Void) {
        onCompletion(nil);
    }
    
    func deepCopy(_ onCompletion: @escaping (AnyObject) -> Void) {
        
    }
    
    func deepCopyPage(_ toDocument: FTDocumentProtocol, onCompletion: @escaping (FTPageProtocol) -> Void) {
        
    }
}

//Memory Warning
extension FTAnnotation
{
    @objc func didRecieveMemoryWarning(_ notification : Notification)
    {
        
    }
}
extension FTAnnotation : FTDeleting
{
    func willDelete() {
        
    }
}

extension FTAnnotation : FTTransformScale
{
    func apply(_ scale: CGFloat) {
        
    }
}

extension FTAnnotation : FTAnnotationUndoRedo
{
    func undoInfo() -> FTUndoableInfo {
        let info = FTUndoableInfo.init(withAnnotation: self);
        return info;
    }
    
    func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        self.boundingRect = info.boundingRect;
    }
}
