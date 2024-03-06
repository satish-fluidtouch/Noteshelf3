//
//  FTCachedSqliteFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTCachedSqliteFileItem: FTFileItemSqlite {
    private var cachedNonStrokeFileItem: FTNonStrokeAnnotationFileItem?;
    
    override init!(url: URL!, isDirectory isDir: Bool) {
        super.init(url: url, isDirectory: isDir);
    }
    
    func generateNonStrokeCache() {
        
    }
}
