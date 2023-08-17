//
//  PDFDocument+Extension.swift
//  FTCommon
//
//  Created by Sameer on 04/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit
import FTCommon

extension PDFDocument {
    func drawImagefromPdf(with angle: CGFloat = 0) -> UIImage? {
        guard  let page = self.page(at: 1) else { return nil }
        var pageRect = page.bounds(for: .cropBox)
        let pdfBox = PDFDisplayBox.mediaBox;
        var rotatedAngle = 360 - angle;
        if(rotatedAngle >= 360) {
            rotatedAngle = 360 - rotatedAngle
        }
        let trasnform = page.transform(for: pdfBox);
        pageRect = pageRect.applying(trasnform)
        let rotate = CGAffineTransform(rotationAngle: rotatedAngle.degreesToRadians);
        pageRect = pageRect.applying(rotate);
        pageRect.origin = CGPoint.zero;
        let maxSize = CGSize(width: 259, height: 399) // This is taken from shelf gallery style
        let aspectPageSize = CGSize.aspectFittedSize(pageRect.size, max: maxSize);
        pageRect.size = aspectPageSize;

        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { context in
            UIColor.clear.set()
            context.fill(pageRect);
            context.cgContext.interpolationQuality = .high
            context.cgContext.translateBy(x: 0, y: pageRect.height);
            context.cgContext.scaleBy(x: 1, y: -1);
            let midx = CGFloat(pageRect.width)*0.5;
            let midy = CGFloat(pageRect.height)*0.5;

            context.cgContext.translateBy(x: midx, y: midy);
            context.cgContext.rotate(by: rotatedAngle.degreesToRadians);
            if(rotatedAngle == 0 || rotatedAngle == 180) {
                context.cgContext.translateBy(x: -midx, y: -midy);
            }
            else {
                context.cgContext.translateBy(x: -midy, y: -midx);
            }
            context.cgContext.concatenate(drawingTransform(page,
                                                 pageRect,
                                                           0.5,
                                                 pdfBox,
                                                 Int32(rotatedAngle),
                                                           DOC_VERSION));
            page.draw(with: pdfBox, to: context.cgContext);
        }
        return img
    }
}
