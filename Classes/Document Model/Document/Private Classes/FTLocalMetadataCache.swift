//
//  FTLocalMetadataCache.swift
//  Noteshelf
//
//  Created by Amar on 26/4/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTLocalMetadataCache : NSObject,FTDocumentLocalMetadataCacheProtocol
{
    fileprivate var localMetadataCache : NSMutableDictionary!;
    fileprivate var documentUUID : String!;
    fileprivate var documentRect : CGRect!;
    
    convenience init(documentUUID : String,documentRect : CGRect) {
        self.init();
        self.documentUUID = documentUUID;
        self.documentRect = documentRect;
    }
    
    //MARK:- FTDocumentLocalMetadataCacheProtocol -
    var defaultBodyFont: UIFont {
        get {
            var font : UIFont?
            if let value = self.localMetadataCache[FTFontStorage.fontStyleKey] as? String,
               let fontSizeStr = self.localMetadataCache[FTFontStorage.fontSizeKey] as? NSString {
                font = UIFont(name: value, size: CGFloat(fontSizeStr.floatValue));
            }
            return font ?? UIFont.defaultTextFont()
        }
        set {
            self.localMetadataCache[FTFontStorage.fontStyleKey] = newValue.fontName;
            self.localMetadataCache[FTFontStorage.fontSizeKey] = String(format: "%.0f", newValue.pointSize)
        }
    }
    
    var defaultTextColor: UIColor {
        get {
            guard let value = self.localMetadataCache[FTFontStorage.textColorKey] as? String else {
                return UIColor.black
            }
            return UIColor(hexString: value)
        }
        set {
            self.localMetadataCache[FTFontStorage.textColorKey] = newValue.hexStringFromColor()
        }
    }

    var defaultIsUnderline: Bool {
        get {
            if let value = self.localMetadataCache[FTFontStorage.isUnderlinedKey] as? NSNumber {
                return value.boolValue
            }
            return false
        }
        set {
            self.localMetadataCache[FTFontStorage.isUnderlinedKey] = NSNumber.init(value: newValue)
        }
    }

    var defaultIsStrikeThrough: Bool {
        get {
            if let value = self.localMetadataCache[FTFontStorage.isStrikeThroughKey] as? NSNumber {
                return value.boolValue
            }
            return false
        }
        set {
            self.localMetadataCache[FTFontStorage.isStrikeThroughKey] = NSNumber.init(value: newValue)
        }
    }

    var defaultTextAlignment: Int {
        get {
            guard let value = self.localMetadataCache[FTFontStorage.textAlignmentKey] as? NSNumber else {
                return 0
            }
            return value.intValue
        } set {
            self.localMetadataCache[FTFontStorage.textAlignmentKey] = NSNumber(value: newValue as Int)
            self.saveMetadataCache()
        }
    }

    var defaultAutoLineSpace: Int {
        get {
            guard let value = self.localMetadataCache[FTFontStorage.lineSpaceKey] as? NSNumber else {
                return 0
            }
            return value.intValue
        } set {
            self.localMetadataCache[FTFontStorage.lineSpaceKey] = NSNumber(value: newValue as Int)
            self.saveMetadataCache()
        }
    }

    var defaultIsLineSpaceEnabled: Bool {
        get {
            if let value = self.localMetadataCache[FTFontStorage.isLineSpaceEnabledKey] as? NSNumber {
                return value.boolValue
            }
            return false
        } set {
            self.localMetadataCache[FTFontStorage.isLineSpaceEnabledKey] = NSNumber.init(value: newValue)
        }
    }

    var lastViewedPageIndex : Int {
        get {
            let value = self.localMetadataCache["lastViewedPageIndex"] as? NSNumber;
            return (value != nil) ? value!.intValue : 0;
        }
        set {
            self.localMetadataCache["lastViewedPageIndex"] = NSNumber.init(value: newValue as Int);
            self.saveMetadataCache();
        }
    }
    
    var currentDeskMode : RKDeskMode {
        get {
            let value = self.localMetadataCache["currentDeskMode"] as? NSNumber;
            return (value != nil) ? RKDeskMode.init(rawValue: value!.intValue)! : RKDeskMode.deskModePen;
        }
        set {
            self.localMetadataCache["currentDeskMode"] = NSNumber.init(value: newValue.rawValue as Int);
        }
    };

    var lastPenMode : RKDeskMode {
        get {
            let value = self.localMetadataCache["lastPenMode"] as? NSNumber;
            return (value != nil) ? RKDeskMode.init(rawValue: value!.intValue)! : RKDeskMode.deskModePen;
        }
        set {
            self.localMetadataCache["lastPenMode"] = NSNumber.init(value: newValue.rawValue as Int);
        }
    }
    
    var shapeDetectionEnabled : Bool {
        get {
            let value = self.localMetadataCache["shapeDetectionEnabled"] as? NSNumber;
            return (value != nil) ? value!.boolValue : false;
        }
        set{
            self.localMetadataCache["shapeDetectionEnabled"] = NSNumber.init(value: newValue as Bool);
        }
    };

    func zoomOrigin(for pageIndex: Int) -> CGPoint {
        if let val = self.localMetadataCache["ZoomInfo"] as? NSDictionary,
            let index = (val["index"] as? NSNumber)?.intValue,
            pageIndex == index,
            let originStr = val["Origin"] as? String {
            return NSCoder.cgPoint(for: originStr);
        }
        return CGPoint.zero;
    }
    
    func setZoomOrigin(_ point:CGPoint,for index: Int) {
        if CGPoint.zero != point {
            let dictionary = NSMutableDictionary();
            dictionary["Origin"] = NSCoder.string(for: point);
            dictionary["index"] = NSNumber(value: index);
            self.localMetadataCache["ZoomInfo"] = dictionary;
        }
        else {
            self.localMetadataCache.removeObject(forKey: "ZoomInfo");
        }
    }
    
    //MARK:- Load/Save -
    func loadMetadataCache()
    {
        var localInfo = NSMutableDictionary.init(contentsOf: self.localMetadataCachePath());
        if(nil == localInfo) {
            localInfo = NSMutableDictionary();
        }
        self.localMetadataCache = localInfo;
    }
    
    func saveMetadataCache()
    {
        self.localMetadataCache.write(to: self.localMetadataCachePath(), atomically: true);
    }
    
    //MARK:- Zoom Related -
    var zoomModeEnabled : Bool {
        get {
            let value = self.localMetadataCache["zoomModeEnabled"] as? NSNumber;
            return (value != nil) ? value!.boolValue : false;
        }
        set{
            self.localMetadataCache["zoomModeEnabled"] = NSNumber.init(value: newValue as Bool);
        }
    };
    
    var zoomFactor : CGFloat {
        get {
            let value = self.localMetadataCache["zoomFactor"] as? NSNumber;
            return (value != nil) ? CGFloat(value!.floatValue) : 3;
        }
        set{
            self.localMetadataCache["zoomFactor"] = NSNumber.init(value: Float(newValue) as Float);
        }
    };
    
    var zoomPalmRestHeight : CGFloat {
        get {
            let value = self.localMetadataCache["zoomPalmRestHeight"] as? NSNumber;
            return (value != nil) ? CGFloat(value!.floatValue) : 0;
        }
        set{
            self.localMetadataCache["zoomPalmRestHeight"] = NSNumber.init(value: Float(newValue) as Float);
        }
    };
    
    var zoomAutoscrollWidth : Int {
        get {
            let value = self.localMetadataCache["zoomAutoscrollWidth"] as? NSNumber;
            return (value != nil) ? value!.intValue : 100;
        }
        set{
            self.localMetadataCache["zoomAutoscrollWidth"] = NSNumber.init(value: newValue as Int);
        }
    };

    var zoomLeftMargin : CGFloat {
        get {
            let value = self.localMetadataCache["zoomLeftMargin"] as? NSNumber;
            return (value != nil) ? CGFloat(value!.floatValue) : (30/documentRect.size.width)*100;
        }
        set{
            self.localMetadataCache["zoomLeftMargin"] = NSNumber.init(value: Float(newValue) as Float);
        }
    };

    var zoomPanelButtonPositionIsLeft : Bool {
        get {
            let value = self.localMetadataCache["zoomPanelButtonPositionIsLeft"] as? NSNumber;
            return (value != nil) ? value!.boolValue : true;
        }
        set{
            self.localMetadataCache["zoomPanelButtonPositionIsLeft"] = NSNumber.init(value: newValue as Bool);
        }
    }
    
    var zoomPanelAutoAdvanceEnabled : Bool {
        get {
            let value = self.localMetadataCache["zoomPanelAutoAdvanceEnabled"] as? NSNumber;
            return (value != nil) ? value!.boolValue : true;
        }
        set{
            self.localMetadataCache["zoomPanelAutoAdvanceEnabled"] = NSNumber.init(value: newValue as Bool);
        }
    };
    
    var zoomPanelLineHeightGuideEnabled : Bool {
        get {
            let value = self.localMetadataCache["zoomPanelLineHeightGuideEnabled"] as? NSNumber;
            return (value != nil) ? value!.boolValue : false; 
        }
        set{
            self.localMetadataCache["zoomPanelLineHeightGuideEnabled"] = NSNumber.init(value: newValue as Bool);
        }
    };

    //MARK:- Cache path -
    fileprivate static var cachePath: URL {
        let cacheFolder = NSSearchPathForDirectoriesInDomains(.libraryDirectory,
                                                              .userDomainMask,
                                                              true).last;
        let cacheFolderURL = URL(fileURLWithPath: cacheFolder!);
        let localMetadataFolder = cacheFolderURL.appendingPathComponent("LocalMetaDataCache");
        return localMetadataFolder;
    }
    
    fileprivate func localMetadataCachePath() -> URL
    {
        FTLocalMetadataCache.migrateIfNeeded();
        
        let localMetadataFolder = FTLocalMetadataCache.cachePath;
        if(!FileManager.default.fileExists(atPath: localMetadataFolder.path)) {
            _ = try? FileManager.default.createDirectory(at: localMetadataFolder, withIntermediateDirectories: true, attributes: nil);
        }
        let fileName = self.documentUUID.appending(".plist");
        return localMetadataFolder.appendingPathComponent(fileName);
    }
    
    static func migrateIfNeeded() {
        if(UserDefaults.standard.bool(forKey: "cacheMigrated")) {
            return;
        }
        let defaultFileManager = FileManager.default;
        let cacheFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                              .userDomainMask,
                                                              true).last;
        let cacheFolderURL = URL(fileURLWithPath: cacheFolder!);
        let localMetadataFolder = cacheFolderURL.appendingPathComponent("LocalMetaDataCache");
        if(defaultFileManager.fileExists(atPath: localMetadataFolder.path)) {
            try? defaultFileManager.moveItem(at: localMetadataFolder, to: self.cachePath);
        }
        UserDefaults.standard.set(true, forKey: "cacheMigrated");
        UserDefaults.standard.synchronize();
    }
}
