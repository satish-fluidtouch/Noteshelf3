//
//  FTPrintPageRenderer.swift
//  FTFileConverter
//
//  Created by Akshay on 23/04/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension UIPrintPageRenderer {
    func getPDFData() -> NSData {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData( pdfData, self.paperRect, nil )
        self.prepare(forDrawingPages: NSMakeRange(0, self.numberOfPages))

        let bounds = UIGraphicsGetPDFContextBounds();
        for i in 0..<self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: i, in: bounds)
        }
        UIGraphicsEndPDFContext();
        return pdfData;
    }
}

typealias FTPrintPaper = CGSize

enum FTPageSizeHelper {
    case size(width:CGFloat, height:CGFloat)

    var standardized: FTPrintPaper {
        switch self {
        case .size(let width, let height):
            //TODO: add logic to find the proper page size
            return CGSize(width:width, height: height)
        }
    }
}
