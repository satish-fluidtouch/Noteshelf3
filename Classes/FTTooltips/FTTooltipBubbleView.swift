//
//  FTTooltipBubbleView.swift
//  Noteshelf
//
//  Created by Simhachalam on 01/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

let maxBubbleWidth:CGFloat = 500
let stemSize:CGSize = CGSize.init(width: 22, height: 74)

class FTTooltipBubbleView: UIView {
    
    var tipModel:FTTooltipModel!
    var messageLabel:UILabel!
    var bubbleLeftImageView:UIImageView!
    var bubbleRightImageView:UIImageView!
    var bubbleStemImgView:UIImageView!
    weak var targetView: UIView?
    
    var appKeyWindow : UIWindow? {
        return Application.keyWindow
    }
    
    convenience init(withModel tipModel:FTTooltipModel) {
        self.init()
        
        self.clipsToBounds = false
        self.backgroundColor = UIColor.clear//.withAlphaComponent(0.3)
        self.tipModel = tipModel

        self.bubbleLeftImageView = UIImageView.init(frame: CGRect.zero)
        self.bubbleLeftImageView.clipsToBounds = true
        let leftImage = UIImage.init(named: "pill-left")
        self.bubbleLeftImageView.image = leftImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 37, left: 25, bottom: 37, right: 0))
        self.addSubview(self.bubbleLeftImageView)
        
        self.bubbleStemImgView = UIImageView.init()
        let stemImage = UIImage.init(named: "pill-middleup")
        self.bubbleStemImgView.image = stemImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 34, left: 0, bottom: 34, right: 0))
        self.addSubview(self.bubbleStemImgView)
        
        self.bubbleRightImageView = UIImageView.init(frame: CGRect.zero)
        self.bubbleRightImageView.clipsToBounds = true
        let rightImage = UIImage.init(named: "pill-right")
        self.bubbleRightImageView.image = rightImage?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 37, left: 0, bottom: 37, right: 25))
        self.addSubview(self.bubbleRightImageView)
        
        self.messageLabel = UILabel.init(frame: CGRect.zero)
        self.messageLabel.backgroundColor = UIColor.clear
        self.messageLabel.text = tipModel.tooltipMessage
        self.messageLabel.textColor = UIColor.white
        self.messageLabel.textAlignment = NSTextAlignment.center
        self.messageLabel.numberOfLines = 0
        self.addSubview(self.messageLabel)
     
        self.refreshTipBubble()
    }
    internal func refreshTipBubble(){
        guard let window = self.appKeyWindow else {
            return;
        }
        let tipMesaageFont:UIFont! = UIFont.appFont(for: .regular, with: 12)
        self.messageLabel.font = tipMesaageFont

        var expectedRect = tipModel.tooltipMessage.boundingRect(with: CGSize(width: min(window.bounds.width-40, maxBubbleWidth), height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : tipMesaageFont], context: nil);
        expectedRect.origin.y = 0
        expectedRect.size.width += 50
        expectedRect.size.height += (60)
        self.frame = expectedRect

        let leftFrame = CGRect.init(x: 0, y: -10, width: (expectedRect.width / 2) - (stemSize.width / 2), height: expectedRect.height)
        let middleFrame = CGRect.init(x: leftFrame.maxX, y: -10, width: stemSize.width, height: expectedRect.height)
        let rightFrame = CGRect.init(x: middleFrame.maxX, y: -10, width: (expectedRect.width / 2) - (stemSize.width / 2), height: expectedRect.height)
        
        self.bubbleLeftImageView.frame = leftFrame
        self.bubbleStemImgView.frame = middleFrame
        self.bubbleRightImageView.frame = rightFrame
        self.messageLabel.frame = CGRect.init(origin: CGPoint.init(x: 25, y: 20), size: CGSize.init(width: expectedRect.size.width-50, height: expectedRect.size.height - 60))
    }
    func registerForLayoutChanges(_ targetView: Any){
        guard let window = self.appKeyWindow else {
            return;
        }
        self.targetView = targetView as! UIButton
    }

    func refreshBubblePositions(){
        guard let window = self.appKeyWindow else {
            return;
        }

        if let targetView  = self.targetView {
            let targetRectInWindow = window.convert(targetView.frame, from: targetView.superview)
            
            self.frame.origin = CGPoint.init(x: targetRectInWindow.midX - self.frame.width/2.0, y: targetRectInWindow.maxY - 7)
            if self.frame.origin.x < 0 {
                self.bubbleStemImgView.frame.origin.x += (self.frame.origin.x)
                self.frame.origin.x -= (self.frame.origin.x)
                
                self.bubbleLeftImageView.frame.size.width = self.bubbleStemImgView.frame.minX
                self.bubbleRightImageView.frame.origin.x = self.bubbleStemImgView.frame.maxX
                self.bubbleRightImageView.frame.size.width = self.frame.width - self.bubbleStemImgView.frame.maxX
            }
            if self.frame.maxX > window.frame.width {
                self.bubbleStemImgView.frame.origin.x += (self.frame.maxX - window.frame.width)
                self.frame.origin.x -= (self.frame.maxX - window.frame.width)
                
                self.bubbleLeftImageView.frame.size.width = self.bubbleStemImgView.frame.minX
                self.bubbleRightImageView.frame.origin.x = self.bubbleStemImgView.frame.maxX
                self.bubbleRightImageView.frame.size.width = self.frame.width - self.bubbleStemImgView.frame.maxX
            }
        }
    }
    deinit {

    }
}
