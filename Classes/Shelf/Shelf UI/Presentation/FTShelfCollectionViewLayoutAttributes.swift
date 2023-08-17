//
//  FTShelfCollectionViewLayoutAttributes.swift
//  Noteshelf
//
//  Created by Siva on 23/02/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

final class FTShelfCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    private var showGroupingMode = false;
    var shouldUpdateDecoration = false;
    var isDraggingCell = false;
    var focusedUUID: String?;

    override func copy(with zone: NSZone?) -> Any {
        let copy: FTShelfCollectionViewLayoutAttributes = super.copy(with: zone) as! FTShelfCollectionViewLayoutAttributes
        copy.showGroupingMode = self.showGroupingMode
        copy.focusedUUID = self.focusedUUID
        copy.shouldUpdateDecoration = self.shouldUpdateDecoration
        copy.isDraggingCell = self.isDraggingCell
        
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard object is FTShelfCollectionViewLayoutAttributes else {
            return false
        }
        
        let otherObject: FTShelfCollectionViewLayoutAttributes = object as! FTShelfCollectionViewLayoutAttributes
        
        if (self.isDraggingCell != otherObject.isDraggingCell) {
            return false
        }
        if (self.showGroupingMode != otherObject.showGroupingMode) {
            return false
        }
           
        if (self.focusedUUID != otherObject.focusedUUID) {
            return false
        }

        if self.representedElementCategory == .decorationView
            && self.shouldUpdateDecoration != otherObject.shouldUpdateDecoration {
            return false
        }
        
        return super.isEqual(otherObject);
    }

}
