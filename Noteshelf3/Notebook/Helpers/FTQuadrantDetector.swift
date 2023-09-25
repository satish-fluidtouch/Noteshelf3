//
//  FTQuadrantDetector.swift
//  Noteshelf
//
//  Created by Narayana on 17/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if DEBUG
private let quadDebug = false
#endif

class FTQuadrantDetector: NSObject {
    
    private var centerQuadrantFrame: CGRect = .zero
    private var topLeftQuadrantFrame: CGRect! = .zero
    private var topQuadrantFrame: CGRect! = .zero
    private var topRightQuadrantFrame: CGRect! = .zero
    private var bottomLeftQuadrantFrame: CGRect! = .zero
    private var bottomQuadrantFrame: CGRect! = .zero
    private var bottomRightQuadrantFrame: CGRect! = .zero
    private var leftQuadrantFrame: CGRect! = .zero
    private var rightQuadrantFrame: CGRect! = .zero

    init(view: UIView, centerQuadrantInSet: CGFloat, topOffset: CGFloat) {
        let contentHolderRect = CGRect(x: view.bounds.origin.x,
                                               y: view.bounds.origin.y + topOffset,
                                               width: view.bounds.size.width,
                                               height: view.bounds.size.height - topOffset)

        let contentHolderXpos = contentHolderRect.origin.x
        let contentHolderYpos = contentHolderRect.origin.y
        let contentHolderWidth = contentHolderRect.width
        let contentHolderHeight = contentHolderRect.height

        let topOrBottomEdge = contentHolderRect.height * centerQuadrantInSet
        let leftOrRightEdge = contentHolderRect.width * centerQuadrantInSet
        self.centerQuadrantFrame = contentHolderRect.inset(by: UIEdgeInsets(top: topOrBottomEdge, left: leftOrRightEdge, bottom: topOrBottomEdge, right: leftOrRightEdge))

        let centerQuadrantXPos = self.centerQuadrantFrame.origin.x
        let centerQuadrantYPos = self.centerQuadrantFrame.origin.y
        let centerQuadrantWidth = self.centerQuadrantFrame.width
        let centerQuadrantHeight = self.centerQuadrantFrame.height

        self.topLeftQuadrantFrame = CGRect(x: contentHolderXpos, y: contentHolderYpos, width: centerQuadrantXPos, height: centerQuadrantYPos)
        self.topQuadrantFrame = CGRect(x: centerQuadrantXPos, y: contentHolderYpos, width: centerQuadrantWidth, height: centerQuadrantYPos)
        self.topRightQuadrantFrame = CGRect(x: centerQuadrantXPos + centerQuadrantWidth, y: contentHolderYpos, width: contentHolderWidth - centerQuadrantXPos - centerQuadrantWidth, height: centerQuadrantYPos)
        
        self.leftQuadrantFrame = CGRect(x: contentHolderXpos, y: centerQuadrantYPos, width: centerQuadrantXPos, height: centerQuadrantHeight)
        self.rightQuadrantFrame = CGRect(x: centerQuadrantXPos + centerQuadrantWidth, y: centerQuadrantYPos, width: contentHolderWidth - centerQuadrantXPos - centerQuadrantWidth, height: centerQuadrantHeight)
        
        self.bottomLeftQuadrantFrame = CGRect(x: contentHolderXpos, y: centerQuadrantYPos + centerQuadrantHeight, width: centerQuadrantXPos, height: contentHolderHeight - centerQuadrantYPos - centerQuadrantHeight)
        self.bottomQuadrantFrame = CGRect(x: centerQuadrantXPos, y: centerQuadrantYPos + centerQuadrantHeight, width: centerQuadrantWidth, height: contentHolderHeight - centerQuadrantYPos - centerQuadrantHeight)
        self.bottomRightQuadrantFrame = CGRect(x: centerQuadrantXPos + centerQuadrantWidth, y: centerQuadrantYPos + centerQuadrantHeight, width: contentHolderWidth - centerQuadrantXPos - centerQuadrantWidth, height: contentHolderHeight - centerQuadrantYPos - centerQuadrantHeight)

        super.init()

        #if DEBUG
        if quadDebug {
            addSubView(frame: topLeftQuadrantFrame)
            addSubView(frame: topQuadrantFrame)
            addSubView(frame: topRightQuadrantFrame)
            addSubView(frame: leftQuadrantFrame)
            addSubView(frame: centerQuadrantFrame)
            addSubView(frame: rightQuadrantFrame)
            addSubView(frame: bottomLeftQuadrantFrame)
            addSubView(frame: bottomQuadrantFrame)
            addSubView(frame: bottomRightQuadrantFrame)
        }

        func addSubView(frame: CGRect) {
            let colorView = UIView(frame: frame)
            colorView.backgroundColor = UIColor.random()
            view.addSubview(colorView)
            view.sendSubviewToBack(colorView)
        }
        #endif
    }

    func getQuadrant(for movingCenter: CGPoint) -> FTShortcutQuadrant {
        var quadrant: FTShortcutQuadrant = .center
        
        if self.topLeftQuadrantFrame.contains(movingCenter) {
            quadrant = .topLeft
        } else if self.topRightQuadrantFrame.contains(movingCenter) {
            quadrant = .topRight
        } else if self.bottomLeftQuadrantFrame.contains(movingCenter) {
            quadrant = .bottomLeft
        } else if self.bottomRightQuadrantFrame.contains(movingCenter) {
            quadrant = .bottomRight
        }  else if self.leftQuadrantFrame.contains(movingCenter) {
            quadrant = .left
        } else if self.rightQuadrantFrame.contains(movingCenter) {
            quadrant = .right
        } else if self.topQuadrantFrame.contains(movingCenter) {
            quadrant = .top
        } else if self.bottomQuadrantFrame.contains(movingCenter) {
            quadrant = .bottom
        }
        return quadrant
    }
}
