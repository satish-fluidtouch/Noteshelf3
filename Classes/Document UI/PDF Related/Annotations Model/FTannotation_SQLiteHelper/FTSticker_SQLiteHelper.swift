//
//  FTSticker_SQLiteHelper.swift
//  Noteshelf3
//
//  Created by Sameer on 06/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTDocumentFramework

extension FTStickerAnnotation  {
    override func saveToDatabase(_ db : FMDatabase)  -> Bool {
        return super.saveToDatabase(db)
    }
    
    override func updateWith(set : FMResultSet) {
        super.updateWith(set: set);
    }
}
