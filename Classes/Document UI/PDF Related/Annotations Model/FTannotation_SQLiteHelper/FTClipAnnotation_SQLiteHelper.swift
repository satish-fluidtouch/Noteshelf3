//
//  FTClipAnnotation_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Mahesh on 03/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let imageInsertQuery = "INSERT INTO annotation (id,groupId,annotationType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,screenScale,txMatrix,imgTxMatrix,createdTime,modifiedTime,isReadonly,version,isLocked,clipString)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

extension FTWebClipAnnotation  {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        return db.executeUpdate(imageInsertQuery, withArgumentsIn: [
            self.uuid,
            self.groupId ?? NSNull(),
            NSNumber.init(value: self.annotationType.rawValue),
            NSNumber.init(value: Float(self.boundingRect.origin.x) as Float),
            NSNumber.init(value: Float(self.boundingRect.origin.y) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.width) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.height) as Float),
            NSNumber.init(value: Float(self.screenScale) as Float),
            NSCoder.string(for: self.transformMatrix),
            NSCoder.string(for: self.imageTransformMatrix),
            NSNumber.init(value: self.createdTimeInterval as Double),
            NSNumber.init(value: self.modifiedTimeInterval as Double),
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version),
            NSNumber.init(value: self.isLocked),
            self.clipString
            ]);
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        self.clipString = set.string(forColumn: "clipString") ?? ""
    }
}
