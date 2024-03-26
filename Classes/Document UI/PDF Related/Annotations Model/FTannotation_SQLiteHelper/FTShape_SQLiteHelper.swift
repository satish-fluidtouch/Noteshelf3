//
//  FTShape_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Akshay on 27/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework

private let shapeInsertQuery = """
INSERT INTO annotation (annotationType, strokeWidth, strokeColor, penType, boundingRect_x, boundingRect_y, boundingRect_w, boundingRect_h, txMatrix, segmentCount, shape_data, createdTime, modifiedTime, isReadonly, version, id, groupId)
VALUES
(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
""";

extension FTShapeAnnotation {
    override var shouldAddToPageTile : Bool {
        return true;
    }

    override func saveToDatabase(_ db : FMDatabase) -> Bool {
        guard !self.hasErasedSegments() else {
            return super.saveToDatabase(db)
        }
        do {
        try db.executeUpdate(shapeInsertQuery, values: [
            NSNumber.init(value: FTAnnotationType.shape.rawValue),
            NSNumber.init(value: Float(self.strokeWidth) as Float),
            NSNumber.init(value: self.strokeColor.rgbHex() as UInt32),
            NSNumber.init(value: self.penType.rawValue as Int),
            NSNumber.init(value: Float(self.boundingRect.origin.x) as Float),
            NSNumber.init(value: Float(self.boundingRect.origin.y) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.width) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.height) as Float),
            NSCoder.string(for: self.shapeTransformMatrix),
            NSNumber.init(value: Int32(self.getshapeControlPoints().count)),
            self.shapeData.data,
            NSNumber.init(value: self.createdTimeInterval as Double),
            NSNumber.init(value: self.modifiedTimeInterval as Double),
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version),
            self.uuid,
            self.groupId ?? NSNull(),
            ]);
            return true
        } catch {
            print("Error saving", error.localizedDescription)
            return false
        }

    }

    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        
        self.shapeTransformMatrix = set.affineTransform(forColumn: "txMatrix");
        
        if -1 != set.columnIndex(forName: "shape_data") {
            if let _shapeData = set.data(forColumn: "shape_data") {
                self.shapeData = FTShapeData(data: _shapeData)
                self.setControlPoints(shapeData.controlPoints)
            }
        }

        //for normal strokes segmentCount is the count of Total segments, but whereas in shape, this is the count of control points.
        let segCount = Int(set.int(forColumn: "segmentCount"));
    }

    override func finalizeToSaveToDB() -> [FTAnnotation] {
        return [self]
    }
}
