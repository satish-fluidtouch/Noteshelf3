//
//  FTTooltipBubbleRight.swift
//  Noteshelf
//
//  Created by Naidu on 25/05/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTTooltipBubbleRight: FTTooltipBubbleView {
    
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
        let stemImage = UIImage.init(named: "stem-right")
//        self.bubbleStemImgView.contentMode = UIViewContentMode.scaleAspectFit
        self.bubbleStemImgView.image = stemImage//?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 37, left: 0, bottom: 37, right: 0))
        self.addSubview(self.bubbleStemImgView)

        self.messageLabel = UILabel.init(frame: CGRect.zero)
        self.messageLabel.backgroundColor = UIColor.clear
        self.messageLabel.text = tipModel.tooltipMessage
        self.messageLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        self.messageLabel.textAlignment = NSTextAlignment.right
        self.messageLabel.numberOfLines = 0
        self.addSubview(self.messageLabel)
        
        self.refreshTipBubble()
    }
    internal override func refreshTipBubble(){
        let tipMesaageFont:UIFont! = UIFont.appFont(for: .regular, with: 12)
        self.messageLabel.font = tipMesaageFont
        if let targetView  = self.targetView {
            var expectedRect = tipModel.tooltipMessage.boundingRect(with: CGSize(width: min(targetView.bounds.width-40-60, maxBubbleWidth), height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : tipMesaageFont], context: nil);
            expectedRect.origin.y = 0
            expectedRect.size.width += (50)
            expectedRect.size.height += (60)
            self.frame = expectedRect
            
            let leftFrame = CGRect.init(x: -15, y: -10, width: (expectedRect.width - 25), height: expectedRect.height)
//            let rightFrame = CGRect.init(x: leftFrame.maxX, y: -10, width: (expectedRect.width - 25)/2.0, height: expectedRect.height)
            let stemFrame = CGRect.init(x: leftFrame.maxX, y: -10-22+11 , width: 25+20, height: expectedRect.height+22)
            
            self.bubbleLeftImageView.frame = leftFrame
//            self.bubbleRightImageView.frame = rightFrame
            self.bubbleStemImgView.frame = stemFrame
            self.messageLabel.frame = CGRect.init(origin: CGPoint.init(x: 25-15, y: 20), size: CGSize.init(width: expectedRect.size.width-50, height: expectedRect.size.height - 60))
        }
    }

    override func refreshBubblePositions(){
        if let targetView  = self.targetView {
            self.frame.origin = CGPoint.init(x: targetView.frame.maxX - self.frame.width, y: targetView.frame.midY - self.frame.height/2)
            self.isHidden = !self.isRegularClass()
        }
    }
}
