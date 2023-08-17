//
//  PDFPage_Extension.swift
//  Noteshelf
//
//  Created by Amar on 01/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import AVFoundation

extension PDFPage  {
    func convertPoint(_ point : CGPoint,
                      fromView view : UIView,
                      rotationAngle: Int) -> CGPoint
    {
        var pageRect = self.bounds(for: PDFDisplayBox.cropBox);
        let transform = self.transform(for: PDFDisplayBox.cropBox);
        pageRect = pageRect.applying(transform);

        let rotateTransform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle) * .pi/180).inverted()
        let viewBounds = view.bounds.applying(rotateTransform);
        let aspectRect = AVMakeRect(aspectRatio: pageRect.size, insideRect: viewBounds);
        var convertedPoint = point.applying(rotateTransform);
        convertedPoint.x -= aspectRect.origin.x;
        convertedPoint.y -= aspectRect.origin.y;
        
        let scalex = pageRect.width/aspectRect.width;
        let scaley = pageRect.height/aspectRect.height;
        let scale = max(scalex, scaley);
        
        var newPont = CGPoint.init(x: convertedPoint.x*scale, y: convertedPoint.y*scale);
        newPont.y = pageRect.size.height - newPont.y;
        newPont = newPont.applying(transform.inverted());
        return newPont;
    }

    func convertRect(_ rect : CGRect,
                     toViewBounds refRect : CGRect,
                     rotationAngle: Int) -> CGRect {
        var rectToConvert = rect;
        var pageRect = self.bounds(for: PDFDisplayBox.cropBox);
        
        let rotateTransform = CGAffineTransform(rotationAngle: CGFloat(-rotationAngle) * .pi/180)
        let transform = self.transform(for: PDFDisplayBox.cropBox).concatenating(rotateTransform);
        pageRect = pageRect.applying(transform);
        rectToConvert = rectToConvert.applying(transform)
        rectToConvert.origin.x -= pageRect.origin.x;
        rectToConvert.origin.y -= pageRect.origin.y;
        
        let aspectRect = AVMakeRect(aspectRatio: pageRect.size, insideRect: refRect);
        var convertedPoint = rectToConvert.origin;
        convertedPoint.x -= aspectRect.origin.x;
        convertedPoint.y -= aspectRect.origin.y;
        
        let scalex = pageRect.width/aspectRect.width;
        let scaley = pageRect.height/aspectRect.height;
        let scale = max(scalex, scaley);
        
        let newPont = CGPoint.init(x: convertedPoint.x/scale, y: convertedPoint.y/scale);
        var rectToReturn = CGRect.zero;
        rectToReturn.origin = newPont;
        
        rectToReturn.size.width = rectToConvert.size.width/scale;
        rectToReturn.size.height = rectToConvert.size.height/scale;

        //TODO: Brute-force: Possibly convert it into View Coordinate space.
        rectToReturn.origin.y = refRect.size.height - (rectToReturn.origin.y+rectToReturn.size.height);

        return rectToReturn;
    }

}
