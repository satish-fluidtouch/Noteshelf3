//
//  PDFLinkAnnotation_Extension.swift
//  Template Generator
//
//  Created by Amar on 26/11/19.
//  Copyright © 2019 Amar. All rights reserved.
//

import UIKit
import PDFKit

extension PDFPage {
    func addLinkAnnotation(bounds : CGRect,goToPage page: PDFPage, at : CGPoint)
    {
        let useDebug = false;
        var linkAnnotation : PDFAnnotation;
        if(!useDebug) {
            linkAnnotation = PDFAnnotation.init(bounds: bounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.link.rawValue), withProperties: nil)
        }
        else {
            linkAnnotation = PDFAnnotation.init(bounds: bounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
            linkAnnotation.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
            linkAnnotation.widgetControlType = .pushButtonControl
            
            linkAnnotation.alignment = .center
            
            linkAnnotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1);
            linkAnnotation.color = UIColor.blue
            
            linkAnnotation.startLineStyle = PDFLineStyle.none;
            linkAnnotation.endLineStyle = PDFLineStyle.none;
            linkAnnotation.buttonWidgetState = PDFWidgetCellState.offState;
        }
        
        let actionMonth = PDFActionGoTo(destination: PDFDestination.init(page: page,at: at))
        linkAnnotation.action = actionMonth
        self.addAnnotation(linkAnnotation);
    }
}
