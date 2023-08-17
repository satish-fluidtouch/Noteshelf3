//
//  FTSeparatorLineDrawHelper.swift
//  Noteshelf
//
//  Created by Siva on 28/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

@objc enum FTSeparatorStyle : Int {
    case topLeftToTopRight = 0
    case bottomLeftToBottomRight = 1
    case topLeftToBottomLeft = 2
    case topRightToBottomRight = 3
};

class FTSeparatorLineDrawHelper : NSObject
{
    let  path = UIBezierPath();

    func drawLine(onView view: UIView, lineStyle : FTSeparatorStyle, lineWidth: CGFloat, offsetLeading : CGFloat, offsetTrailing : CGFloat, color : UIColor?)
    {
        var lineColor = color;
        if(nil == lineColor)
        {
            lineColor = UIColor.separator;
        }
        let context = UIGraphicsGetCurrentContext()!;
        
        var startPoint = CGPoint.zero,endPoint = CGPoint.zero;
        switch lineStyle {
        case .bottomLeftToBottomRight:
            startPoint.y = view.frame.height-lineWidth;
            endPoint.y = startPoint.y;
            fallthrough;
        case .topLeftToTopRight:
            startPoint.x = offsetLeading;
            endPoint.x = view.frame.width - offsetTrailing;
        case .topRightToBottomRight:
            startPoint.x = view.frame.width-lineWidth;
            endPoint.x = startPoint.x;
            fallthrough;
        case .topLeftToBottomLeft:
            startPoint.y = offsetLeading;
            endPoint.y = view.frame.height - offsetTrailing;
        }
        
        context.saveGState();
        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor!.cgColor);
        context.move(to: CGPoint(x: startPoint.x, y: startPoint.y));
        context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y));
        context.strokePath();
        
        context.restoreGState();
    }
    
    func drawLine(onView view: UIView, lineStyle : FTSeparatorStyle, lineWidth: CGFloat, offset : CGFloat,color : UIColor?)
    {
        self.drawLine(onView: view, lineStyle: lineStyle, lineWidth: lineWidth, offsetLeading: offset, offsetTrailing: offset, color: color);
    }
    
    func drawLine(onView view: UIView,lineStyle : FTSeparatorStyle,offset : CGFloat,color : UIColor?)
    {
        self.drawLine(onView: view, lineStyle: lineStyle, lineWidth: 0.5, offset: offset, color: color);
    }
    
    
    func drawDashedLine(onView view: UIView, lineStyle : FTSeparatorStyle, offset : CGFloat,color : UIColor?)
    {
        self.drawDashedLine(onView: view, lineStyle: lineStyle, offsetLeading: offset, offsetTrailing: offset, color: color);
    }
    
    func drawDashedLine(onView view: UIView, lineStyle : FTSeparatorStyle, offsetLeading : CGFloat, offsetTrailing : CGFloat, color : UIColor?)
    {
        self.path.removeAllPoints();
        let  p0 = CGPoint(x: view.bounds.minX + offsetLeading,
                              y: view.bounds.maxY - 0.5)
        self.path.move(to: p0)
        
        let  p1 = CGPoint(x: view.bounds.maxX - offsetTrailing,
                              y: view.bounds.maxY - 0.5)
        self.path.addLine(to: p1)
        
        let  dashes: [ CGFloat ] = [ 1, 5 ]
        self.path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        
        self.path.lineWidth = 1.0
        self.path.lineCapStyle = .round
        if let color = color {
            color.set();
        }
        else {
            UIColor.appColor(.black50).set()
        }
        self.path.stroke()
    }
}
