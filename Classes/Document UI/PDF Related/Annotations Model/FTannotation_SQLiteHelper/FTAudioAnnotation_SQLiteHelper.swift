//
//  FTAudioAnnotation_SQLiteHelper.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

private let audioInsertQuery = "INSERT INTO annotation (id,groupId,annotationType,boundingRect_x,boundingRect_y,boundingRect_w,boundingRect_h,screenScale,createdTime,modifiedTime,isReadonly,version)VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";

extension FTAudioAnnotation  {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        return db.executeUpdate(audioInsertQuery, withArgumentsIn: [
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
            NSNumber.init(value: self.isReadonly),
            NSNumber.init(value: self.version)
            ]);
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
        
        self.screenScale = set.FloatValue(forColumn: "screenScale");
        self.modifiedTimeInterval = set.double(forColumn: "modifiedTime");
        self.createdTimeInterval = set.double(forColumn: "createdTime");
    }
}
