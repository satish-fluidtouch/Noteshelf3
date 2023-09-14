//
//  FTNoteshelfPage_PDFExportHelper.swift
//  Noteshelf
//
//  Created by Amar on 22/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTPageProtocolPDFExport : NSObjectProtocol
{
    func anntationsForPDFExport() -> [String : [FTAnnotation]];
}

extension FTNoteshelfPage : FTPageProtocolPDFExport {
    func anntationsForPDFExport() -> [String : [FTAnnotation]] {
        let annotations = self.annotations();

        var strokes = [FTAnnotation]();
        var shapeAnnotations = [FTAnnotation]();
        var imageAnnotations = [FTAnnotation]();
        var textAnnotations = [FTAnnotation]();
        
        annotations.forEach { (eachAnnotation) in
            switch(eachAnnotation.annotationType) {
            case .stroke:
                strokes.append(eachAnnotation)
            case .image, .sticky, .sticker, .webclip:
                imageAnnotations.append(eachAnnotation)
            case .text:
                textAnnotations.append(eachAnnotation)
            case .shape:
                shapeAnnotations.append(eachAnnotation)
            default:
                break;
            }
        }
        
        return["images" : imageAnnotations,
               "strokes" : strokes,
               "texts" : textAnnotations,
               "shapes" : shapeAnnotations];
    }
}
