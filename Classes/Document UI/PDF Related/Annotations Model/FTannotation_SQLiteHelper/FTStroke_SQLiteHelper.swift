//
//  FTStroke_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let strokeInsertQuery = """
INSERT INTO annotation (annotationType,strokeWidth,strokeColor,penType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,segmentCount,stroke_segments_v3,createdTime,modifiedTime,isReadonly,version, id, groupId)
VALUES
(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
""";

extension FTStroke {
    override var shouldAddToPageTile : Bool {
        return true;
    }
    
    override func saveToDatabase(_ db : FMDatabase) -> Bool {
        let ids = identifiers()

        return db.executeUpdate(strokeInsertQuery, withArgumentsIn: [
            NSNumber.init(value: FTAnnotationType.stroke.rawValue), //Changed to stroke, as we're subclssing this to FTShape and saving intermediately.
            NSNumber.init(value: Float(self.strokeWidth) as Float),
            NSNumber.init(value: self.strokeColor.rgbHex() as UInt32),
            NSNumber.init(value: self.penType.rawValue as Int),
            NSNumber.init(value: Float(self.boundingRect.origin.x) as Float),
            NSNumber.init(value: Float(self.boundingRect.origin.y) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.width) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.height) as Float),
            NSNumber.init(value: Int32(self.segmentCount)),
            self.segmentData(),
            NSNumber.init(value: self.createdTimeInterval as Double),
            NSNumber.init(value: self.modifiedTimeInterval as Double),
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version),
            ids.uuid,
            ids.groupId
            ]);
        
    }

    /// v1: `segments` - segment data with `bounds`.
    /// v2: `stroke_segments` - segment data without `bounds`.
    /// v3: `stroke_segments_v3` - segment data without `bounds` and with `isErased`.
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        
        self.penType = FTPenType(rawValue: Int(set.int(forColumn: "penType"))) ?? FTPenType.pen;
        
        self.strokeWidth = set.CGFloatValue(forColumn: "strokeWidth");
        if let color = UIColor.color(withRGBHex: UInt32(set.int(forColumn: "strokeColor"))) {
            self.strokeColor = color
        }
        let segCount = Int(set.int(forColumn: "segmentCount"));

        if -1 != set.columnIndex(forName: "stroke_segments_v3") {
            if let data = set.data(forColumn: "stroke_segments_v3") {
                self.setSegmentsData(data, segmentCount: segCount);
            }
        } else if -1 != set.columnIndex(forName: "stroke_segments") {
            if let data = set.data(forColumn: "stroke_segments") {
                let migratedData = FTStrokeMigrationV2.migrated(data, segmentCount: segCount);
                self.setSegmentsData(migratedData, segmentCount: segCount);
            }
        } else if -1 != set.columnIndex(forName: "segments") {
            //We'll be treating the data inside `segments` column as v1.
            if let data = set.data(forColumn: "segments") {
                let migratedData = FTStrokeMigrationV1.migrated(data, segmentCount: segCount);
                self.setSegmentsData(migratedData, segmentCount: segCount);
            }
        }
    }
    
    override func finalizeToSaveToDB() -> [FTAnnotation] {
        let count = self.segmentArray.filter{ $0.isErased }.count
        if count == self.segmentArray.count {
            return []
        } else {
            return [self]
        }
    }
}
