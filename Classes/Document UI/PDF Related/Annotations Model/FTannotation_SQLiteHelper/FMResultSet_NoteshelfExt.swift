//
//  FMResultSet_NoteshelfExt.swift
//  Noteshelf
//
//  Created by Amar on 18/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

extension FMResultSet {
    func CGFloatValue(forColumn column : String) -> CGFloat {
        let value = self.double(forColumn: column);
        return CGFloat(value);
    }
    
    func FloatValue(forColumn column : String) -> Float {
        let value = self.double(forColumn: column);
        return Float(value);
    }
    
    func affineTransform(forColumn column : String) -> CGAffineTransform {
        var txTransform = CGAffineTransform.identity;
        if let txMatrixStr = self.string(forColumn: column) {
            txTransform = NSCoder.cgAffineTransform(for: txMatrixStr);
        }
        return txTransform;
    }
}

//MARK:- App Specific
extension FMResultSet
{
    func annotationType() -> FTAnnotationType {
        let intValue = Int(self.int(forColumn: "annotationType"));
        return FTAnnotationType(rawValue: intValue) ?? FTAnnotationType.none;
    }
    
    func boundingRect() -> CGRect {
        var boundingRect = CGRect.zero;
        
        boundingRect.origin.x = self.CGFloatValue(forColumn: "boundingRect_x");
        boundingRect.origin.y = self.CGFloatValue(forColumn: "boundingRect_y");
        boundingRect.size.width = self.CGFloatValue(forColumn: "boundingRect_w");
        boundingRect.size.height = self.CGFloatValue(forColumn: "boundingRect_h");
        
        return boundingRect;
    }
}
