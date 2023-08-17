//
//  FTZoomAreaView.swift
//  Noteshelf
//
//  Created by Amar on 15/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTZoomAreaView: UIView {

    var lineHeight: CGFloat = 0
    var targetRect: CGRect = CGRect.zero
    private var knobHandlerImage: UIImageView!

    private let ZOOM_TOP_KNOB_WIDTH: CGFloat = 24
    private let ZOOM_TOP_KNOB_HEIGHT: CGFloat = 8
    private let ZOOM_TOP_KNOB_TAG = 1001
    private let borderWidth: CGFloat = 2
    private var knobYPos: CGFloat = 0

    var sizingRect: CGRect {
        let sizingTargetRect = self.resizeView?.frame ?? CGRect.zero
        return sizingTargetRect.insetBy(dx: -10, dy: -10)
    }
    
    private var borderColor: UIColor = UIColor.appColor(.ftBlue)
    private var lineColor: UIColor = UIColor.appColor(.ftBlue)

    private weak var resizeView: UIImageView?
    private var borderView: UIView?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        
        let brView = UIView(frame: CGRect.zero)
        brView.isUserInteractionEnabled = false
        brView.layer.borderColor = self.borderColor.cgColor
        brView.layer.borderWidth = borderWidth
        self.borderView = brView
        self.addSubview(brView)

        let view = UIImageView(image: UIImage(named: "zoom_resize_indicator"))
        self.resizeView = view
        self.addSubview(view)

        self.knobYPos = -(ZOOM_TOP_KNOB_HEIGHT/2 - borderWidth/2)
        self.knobHandlerImage = UIImageView.init(frame: CGRect(x: 0,
                                                               y: knobYPos,
                                                               width: ZOOM_TOP_KNOB_WIDTH,
                                                               height: ZOOM_TOP_KNOB_HEIGHT))
        self.knobHandlerImage.image = UIImage(named: "zoom_panel_knob")
        self.knobHandlerImage.tag = ZOOM_TOP_KNOB_TAG
        self.knobHandlerImage.backgroundColor = .clear
        self.knobHandlerImage.isHidden = false
        self.addSubview(self.knobHandlerImage)
        self.bringSubviewToFront(self.knobHandlerImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let rectToDraw = CGRect(origin: CGPoint.zero, size: self.targetRect.size)
        self.resizeView?.frame = CGRect(x: rectToDraw.maxX - 20, y: rectToDraw.maxY-20, width: 20, height: 20)
        
        self.borderView?.frame = rectToDraw

        if knobHandlerImage != nil {
            var frame = knobHandlerImage.frame
            let completeframe = self.bounds
            frame.origin.x = completeframe.width/2 - CGFloat(ZOOM_TOP_KNOB_WIDTH/2)
            frame.origin.y = knobYPos
            knobHandlerImage.frame = frame
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let rectToDraw = CGRect(origin: CGPoint.zero, size: self.targetRect.size)

        //Draw the line height indicators
        self.lineColor.setStroke()
        context?.setLineWidth(1)
        context?.setLineDash(phase: 0, lengths: [3,1])
        
        context?.move(to: CGPoint(x:rectToDraw.origin.x,
                                  y:rectToDraw.origin.y+self.lineHeight))
        
        context?.addLine(to: CGPoint(x:rectToDraw.maxX,
                                     y:rectToDraw.origin.y+self.lineHeight))

        if (lineHeight > rectToDraw.height) {
            context?.move(to: CGPoint(x:rectToDraw.origin.x+0.5,
                                      y:rectToDraw.maxY))
            context?.addLine(to: CGPoint(x:rectToDraw.origin.x+0.5,
                                         y:rectToDraw.origin.y+self.lineHeight))

            context?.move(to: CGPoint(x:rectToDraw.maxX-0.5,
                                      y:rectToDraw.maxY))
            context?.addLine(to: CGPoint(x:rectToDraw.maxX-0.5,
                                         y:rectToDraw.origin.y+self.lineHeight))
        }
        context?.strokePath()
        context?.restoreGState()
    }
}
