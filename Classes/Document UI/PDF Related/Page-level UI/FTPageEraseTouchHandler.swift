//
//  FTPageEraseTouchHandler.swift
//  Noteshelf
//
//  Created by Amar on 15/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private enum FTEraserSizeValue : Int {
    case normal = 30
    case max = 46
    case min = 20
}

protocol FTPageEraseDataSource : AnyObject {
    var contentHolderView : UIView? {get};
    var writingView : FTWritingProtocol? {get};
    var pageContentScale : CGFloat {get};
}

class FTPageEraseTouchHandler: NSObject {
    private var previousEraserTimeStamp : TimeInterval = 0;
    private weak var eraserView : FTEraserView?;
    private var previousPoint : CGPoint = CGPoint.zero;
    private var currentPoint : CGPoint = CGPoint.zero;
    private weak var dataSource : FTPageEraseDataSource?;
    
    convenience init(dataSource : FTPageEraseDataSource) {
        self.init();
        self.dataSource = dataSource;
    };
    
    func eraserTouchesBegan(_ touch : FTTouch)
    {
        guard let contentView = self.dataSource?.contentHolderView else { return }
        let eraserPoint = contentView.convert(touch.currentPostion, from: (touch as FTTouchProcess).touchView());
        
        previousEraserTimeStamp = touch.timeStamp;
        
        if (nil == self.eraserView) {
            let _eraserView = FTEraserView();
            self.eraserView = _eraserView;
            contentView.addSubview(_eraserView);
        }
        
        if let _eraserView = self.eraserView {
            _eraserView.isHidden = false;
            contentView.bringSubviewToFront(_eraserView)
        }
        
        previousPoint = eraserPoint;
        currentPoint = eraserPoint;
        
        let eraserSize = self.updateEraserSize(touch: touch);
        self.dataSource?.writingView?.performEraseAction(eraserPoint,
                                                         eraserSize: eraserSize,
                                                         touchPhase: .began);
    }
    
    func eraserTouchesMoved(_ touch : FTTouch)
    {
        guard let contentView = self.dataSource?.contentHolderView else { return }
        let eraserSize = self.updateEraserSize(touch: touch);
        let eraserPoint = contentView.convert(touch.currentPostion, from: (touch as FTTouchProcess).touchView());
        self.dataSource?.writingView?.performEraseAction(eraserPoint,
                                                         eraserSize: eraserSize,
                                                         touchPhase: .moved);
    }
    
    func eraserTouchesEnded(_ touch : FTTouch)
    {
        guard let contentView = self.dataSource?.contentHolderView else { return }
        let eraserPoint = contentView.convert(touch.currentPostion, from: (touch as FTTouchProcess).touchView());
        
        let eraserSize = self.updateEraserSize(touch: touch);
        self.finalizeEraseAction();
        self.dataSource?.writingView?.performEraseAction(eraserPoint,
                                                         eraserSize: eraserSize,
                                                         touchPhase: .ended);
    }
    
    func eraserTouchesCancelled(_ touch : FTTouch)
    {
        self.finalizeEraseAction();
        self.dataSource?.writingView?.performEraseAction(CGPoint.zero,
                                             eraserSize: 0,
                                             touchPhase: .cancelled);
    }
    
    private func updateEraserSize(touch : FTTouch) -> Int {
        guard let contentView = self.dataSource?.contentHolderView else { return FTEraserSizeValue.normal.rawValue }
        var eraserSize = FTEraserSizeValue.normal.rawValue;
        let selectedSize = FTEraserRackViewController.eraserSize();
        
        let touchView = (touch as FTTouchProcess).touchView();
        
        if(selectedSize != FTEraseSize.auto) {
            eraserSize = Int(Double(selectedSize.rawValue) * 1.05);
        }
        else {
            let location = contentView.convert(touch.locationInView(), from: touchView);
            let prevLocation = contentView.convert(touch.previousLocationInView(), from: touchView);
            
            let distance = Double(location.distanceTo(p: prevLocation));
            let timeSincePrevious = touch.timeStamp - previousEraserTimeStamp;
            previousEraserTimeStamp = touch.timeStamp;
            
            var acceleration : Double = 0;
            if(timeSincePrevious > 0.001) {
                acceleration = distance/timeSincePrevious;
            }
            eraserSize = self.normalizedEraserSize(acceleration: acceleration);
        }
        
        let eraserPoint = contentView.convert(touch.currentPostion, from: touchView);
        if let _eraserView = self.eraserView {
            _eraserView.isHidden = false;
            var frame = _eraserView.frame;
            frame.size = CGSize.init(width: CGFloat(eraserSize), height: CGFloat(eraserSize));
            frame.origin = CGPoint.init(x: eraserPoint.x-frame.size.width/2,y: eraserPoint.y-frame.size.width/2);
            self.eraserView?.frame = frame;
            previousPoint = currentPoint;
            currentPoint = eraserPoint;
        }
        return eraserSize;
    }
    
    private func normalizedEraserSize(acceleration : Double) -> Int {
        let earserSize = FTEraserSizeValue.normal.rawValue;
        let accelerationVal = acceleration/2000;
        var size = Double(earserSize) * pow(M_E, accelerationVal);
        if size > Double(Int.max) {
            size = Double(FTEraserSizeValue.max.rawValue)
            FTLogError("ERASER_SIZE", attributes: ["size":size, "acc":acceleration])
        }

        let x = Int(size);
        let high = FTEraserSizeValue.max.rawValue;
        let low = FTEraserSizeValue.min.rawValue;
        return (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)));
    }

    func finalizeEraseAction()
    {
        self.eraserView?.isHidden = true;
    }
}
