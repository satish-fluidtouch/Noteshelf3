//
//  FTImageAnnotation_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let imageInsertQuery = "INSERT INTO annotation (id,annotationType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,screenScale,txMatrix,imgTxMatrix,createdTime,modifiedTime,isReadonly,version,isLocked)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

extension FTImageAnnotation  {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        return db.executeUpdate(imageInsertQuery, withArgumentsIn: [
            self.uuid,
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
            NSNumber.init(value: self.isLocked)
            ]);
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        
        self.screenScale = set.CGFloatValue(forColumn: "screenScale");
        
        self.transformMatrix = set.affineTransform(forColumn: "txMatrix");
        self.imageTransformMatrix = set.affineTransform(forColumn: "imgTxMatrix");
    }
}
