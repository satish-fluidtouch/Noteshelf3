//
//  FTTextAnnotation_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let textInsertQuery = "INSERT INTO annotation (id,groupId,annotationType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,attrText,nonAttrText,createdTime,modifiedTime,isReadonly,version,transformScale,rotationAngle,isLocked)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

extension FTTextAnnotation  {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        let ids = identifiers()

        return db.executeUpdate(textInsertQuery, withArgumentsIn:[
            ids.uuid,
            ids.groupId,
            NSNumber.init(value: self.annotationType.rawValue),
            NSNumber.init(value: Float(self.boundingRect.origin.x) as Float),
            NSNumber.init(value: Float(self.boundingRect.origin.y) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.width) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.height) as Float),
            self.dataValue ?? NSNull(),
            self.attributedString?.string ?? NSNull(),
            NSNumber.init(value: self.createdTimeInterval as Double),
            NSNumber.init(value: self.modifiedTimeInterval as Double),
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version),
            NSNumber.init(value: Float(self.transformScale)),
            NSNumber.init(value: Float(self.rotationAngle)),
            NSNumber.init(value: self.isLocked)
            ]);
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        self.transformScale = Float(set.FloatValue(forColumn: "transformScale"));
        if(self.transformScale <= 0) {
            self.transformScale = 1;
        }
        self.rotationAngle = CGFloat(set.FloatValue(forColumn: "rotationAngle"))
        self.dataValue = set.data(forColumn: "attrText");
    }
}
