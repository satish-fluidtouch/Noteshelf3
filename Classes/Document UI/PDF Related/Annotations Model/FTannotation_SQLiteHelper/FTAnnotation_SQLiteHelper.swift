//
//  FTAnnotation_SqliteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let annotationCreateQuery = """
    CREATE TABLE IF NOT EXISTS annotation (
            id TEXT DEFAULT null,
            annotationType INTEGER DEFAULT 0,
            strokeWidth NUMERIC DEFAULT 0,
            strokeColor INTEGER DEFAULT 0,
            penType INTEGER DEFAULT 0,
            boundingRect_x NUMERIC DEFAULT 0,
            boundingRect_y NUMERIC DEFAULT 0,
            boundingRect_w NUMERIC DEFAULT 0,
            boundingRect_h NUMERIC DEFAULT 0,
            screenScale NUMERIC DEFAULT 1,
            txMatrix TEXT DEFAULT null,
            imgTxMatrix TEXT DEFAULT null,
            attrText BLOB DEFAULT null,
            nonAttrText TEXT DEFAULT null,
            segmentCount INTEGER DEFAULT 0,
            stroke_segments_v3 BLOB DEFAULT null,
            shape_data BLOB DEFAULT null,
            createdTime REAL DEFAULT 0,
            modifiedTime REAL DEFAULT 0,
            emojiName TEXT DEFAULT null,
            isReadonly NUMERIC DEFAULT 0,
            version INTEGER DEFAULT 2,
            transformScale NUMERIC DEFAULT 1,
            rotationAngle NUMERIC DEFAULT 0,
            isLocked NUMERIC DEFAULT 0,
            clipString TEXT DEFAULT null
)
""";

extension FTAnnotation {
    
    static var annotationQuery : String {
        return annotationCreateQuery;
    }
    
    var shouldAddToPageTile : Bool {
        return false;
    }

    func saveToDatabase(_ db : FMDatabase) -> Bool {
        return false;
    }
    
    func annotationTosaveInProtoBuffer() -> Any{
        return ProtoBuffAnnotation()
    }
    
    func updateWithProtoBuffer(with annotation: Any) {
        
    }
    
    static func annotation(forSet set : FMResultSet) -> FTAnnotation? {
        var annotation : FTAnnotation?
        let annotationType = set.annotationType()
        switch(annotationType) {
        case .stroke:
            annotation = FTStroke();
        case .image:
            annotation = FTImageAnnotation();
        case .sticky:
            annotation = FTStickyAnnotation();
        case .text:
            annotation = FTTextAnnotation();
        case .audio:
            annotation = FTAudioAnnotation();
        case .shape:
            annotation = FTShapeAnnotation();
        case .fancyTitle:
            debugPrint("Implement this")
        case .sticker:
            annotation = FTStickerAnnotation();
        case .webclip:
            annotation = FTWebClipAnnotation();
        case .none:
            break;
        default:
            fatalError("Should not enter here");
        }
        annotation?.updateWith(set: set);
        return annotation;
    }
    
    static func annotation(for protoBuff : ProtoBuffAnnotation) -> FTAnnotation? {
        var annotation : FTAnnotation?
        let annotationType = protoBuff.annotationType
        switch protoBuff.extendedAttributes {
        case .stroke(let stroke):
            annotation = FTStroke()
        case .none:
            print("Hello")
        case .some(.image(_)):
            print("Hello")
        case .some(.text(_)):
            print("Hello")
        }
        annotation?.updateWithProtoBuffer(with: protoBuff)
        return annotation;
    }
    
    func updateWith(set : FMResultSet) {
        self.uuid = set.string(forColumn: "id") ?? UUID().uuidString;
        self.boundingRect = set.boundingRect();
        self.isReadonly = set.bool(forColumn: "isReadonly") ;
        self.version = Int(set.int(forColumn: "version")) ;
        self.isLocked = set.bool(forColumn: "isLocked") ;
    }
    
    private static func belongsToClipAnnotation(_ set: FMResultSet) -> Bool {
        if set.string(forColumn: "clipString") != nil {
            return true
        }
        return false
    }
    
    func finalizeToSaveToDB() -> [FTAnnotation] {
        return [self];
    }
}
