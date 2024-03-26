//
//  FTStickyAnnotation_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

let stickyInsertQuery = "INSERT INTO annotation (id,groupId,annotationType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,screenScale,createdTime,modifiedTime,emojiName,isReadonly,version)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)";

extension FTStickyAnnotation {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        return db.executeUpdate(stickyInsertQuery, withArgumentsIn: [
            self.uuid,
            self.groupId ?? NSNull(),
            NSNumber.init(value: self.annotationType.rawValue),
            NSNumber.init(value: Float(self.boundingRect.origin.x) as Float),
            NSNumber.init(value: Float(self.boundingRect.origin.y) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.width) as Float),
            NSNumber.init(value: Float(self.boundingRect.size.height) as Float),
            NSNumber.init(value: Float(self.screenScale) as Float),
            NSNumber.init(value: self.createdTimeInterval as Double),
            NSNumber.init(value: self.modifiedTimeInterval as Double),
            self.emojiName!,
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version)
            ]);
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        self.emojiName = set.string(forColumn: "emojiName");
    }
}
