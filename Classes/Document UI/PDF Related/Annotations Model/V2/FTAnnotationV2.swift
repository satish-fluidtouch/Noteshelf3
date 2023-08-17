//
//  FTAnnotationV2.swift
//  Noteshelf
//
//  Created by Amar on 24/07/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import NSMetalRender

protocol FTAnnotationContainsProtocol {
    func isPointInside(_ point : CGPoint) -> Bool;
    func intersectsPath(_ inSelectionPath : CGPath,withScale scale:CGFloat,withOffset selectionOffset: CGPoint) -> Bool
}

class FTAnnotationV2 : NSObject, FTAnnotationProtocol,NSCoding
{
    public var boundingRect : CGRect = CGRect.null;
    public var forceRender : Bool = false;
    
    public var uuid : String = UUID().uuidString;
    public var hidden : Bool = false;
    public var modifiedTimeInterval : TimeInterval = Date.timeIntervalSinceReferenceDate;
    public var createdTimeInterval : TimeInterval = Date.timeIntervalSinceReferenceDate;
    public var isReadonly : Bool = false;
    public var version : Int = 1;
    
    public var selected : Bool = false;
    
    var currentScale : CGFloat = 0;
    var copyMode : Bool = false;
    var isEditingInProgress : Bool {
        return false;
    };

    weak var associatedPage : FTPageProtocol?;
    
    var disableUndoManagement : Bool {
        return false;
    }
    
    public var renderingRect : CGRect {
        return self.boundingRect
    };
    
    public var annotationType : FTAnnotationType {
        return .none;
    }
    
    var allowsResize : Bool {
        return false;
    }

    var allowsCopyPaste : Bool {
        return false;
    }

    var allowsEditing : Bool {
        return false;
    }

    public override init()
    {
        super.init();
        self.version = type(of: self).defaultAnnotationVersion();
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didRecieveMemoryWarning(_:)),
                                               name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                               object: nil);
    }
    
    convenience init(withPage page : FTPageProtocol)
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
        self.boundingRect = aDecoder.decodeCGRect(forKey: "boundingRect");
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.uuid, forKey: "uuid");
        aCoder.encode(self.isReadonly, forKey: "isReadonly");
        aCoder.encode(self.version, forKey: "version");
        aCoder.encode(self.boundingRect, forKey: "boundingRect");
    }

    public func loadContents()
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

    func resourceFileNames() -> [String]?
    {
        return nil;
    }
    
    class func defaultAnnotationVersion() -> Int {
        return Int(4);
    }
}

extension FTAnnotationV2 : FTAnnotationContainsProtocol
{
    func isPointInside(_ point : CGPoint) -> Bool
    {
        return self.boundingRect.contains(point);
    }
    
    func intersectsPath(_ inSelectionPath : CGPath,withScale scale:CGFloat,withOffset selectionOffset: CGPoint) -> Bool
    {
        return false;
    }
}

extension FTAnnotationV2 : FTCopying
{
    func deepCopyAnnotation(_ toPage: FTPageProtocol, onCompletion: @escaping (FTAnnotationV2?) -> Void) {
        onCompletion(nil);
    }
    
    func deepCopy(_ onCompletion: @escaping (AnyObject) -> Void) {
        
    }
    
    func deepCopyPage(_ toDocument: FTDocumentProtocol, onCompletion: @escaping (FTPageProtocol) -> Void) {
        
    }
}

//Memory Warning
extension FTAnnotationV2
{
    @objc func didRecieveMemoryWarning(_ notification : Notification)
    {
        
    }
}
extension FTAnnotationV2 : FTDeleting
{
    func willDelete() {
        
    }
}

extension FTAnnotationV2 : FTTransformScale
{
    func apply(_ scale: CGFloat) {
        
    }
}

extension FTAnnotationV2 : FTAnnotationUndoRedo
{
    func undoInfo() -> FTUndoableInfo {
        let info = FTUndoableInfo();
        info.boundingRect = self.boundingRect;
        return info;
    }
    
    func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        self.boundingRect = info.boundingRect;
    }
}

#if TARGET_OS_SIMULATOR
extension FTAnnotation : FTAnnotationUndoRedo
{
    func undoInfo() -> FTUndoableInfo {
        let info = FTUndoableInfo();
        info.boundingRect = self.boundingRect;
        return info;
    }
    
    func updateWithUndoInfo(_ info: FTUndoableInfo)
    {
        self.boundingRect = info.boundingRect;
    }
}
#endif
