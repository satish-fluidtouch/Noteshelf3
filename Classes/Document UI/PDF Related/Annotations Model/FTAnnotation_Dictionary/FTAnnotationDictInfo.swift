//
//  FTAnnotationDictInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias FTAnnotationDictInfo = [String:Any];

extension FTAnnotationDictInfo {
    var annotationType: FTAnnotationType {
        guard let typeValue: Int = self.value(for: "annotationType") else {
            fatalError("annotation Type missing")
        }
        
        return FTAnnotationType(rawValue: typeValue) ?? .none;
    }
    
    var boundingRect: CGRect {
        guard let xValue: CGFloat = self.value(for: "boundingRect_x")
                ,let yValue: CGFloat = self.value(for: "boundingRect_y")
                ,let wValue: CGFloat = self.value(for: "boundingRect_w")
                ,let hValue: CGFloat = self.value(for: "boundingRect_h")
        else {
            fatalError("rect info missing")
        }
        
        return CGRect(x: xValue, y: yValue, width: wValue, height: hValue);
    }
    
    func value<T>(for key: String) -> T? {
        if let value = self[key] as? T {
            return value;
        }
        return nil;
    }
    
    func trasnform(for key: String) -> CGAffineTransform {
        var txTransform = CGAffineTransform.identity;
        if let txMatrixStr = self[key] as? String {
            txTransform = NSCoder.cgAffineTransform(for: txMatrixStr);
        }
        return txTransform;
    }
}
