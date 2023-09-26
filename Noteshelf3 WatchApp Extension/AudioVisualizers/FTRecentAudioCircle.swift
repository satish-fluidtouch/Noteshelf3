//
//  FTRecentAudioCircle.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 19/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SpriteKit
import WatchKit

protocol FTRecentAudioCircleDelegate: NSObjectProtocol{
    func recentAudioCircleDidChange(withIndex audioIndex:Int)
    func recentAudioCircleDidCrossMaxLimit()
    func recentAudioCircleDidCrossMinLimit()
}

let SINGLE_PART_ANGLE:Double = 36.0 // (360 / SUPPORTED_TOTAL_COUNT)
let SUPPORTED_TOTAL_COUNT:Int = 10

class FTRecentAudioCircle: SKScene {
    
    weak var circleDelegate:FTRecentAudioCircleDelegate?
    
    let circleDiameter:CGFloat = screenWidth
    let DEFAULT_ALPHA: CGFloat = 0.3
    let INTERMEDIATE_LIGHT_ALPHA: CGFloat = 0.5
    let INTERMEDIATE_ALPHA: CGFloat = 0.02
    var shineNode:SKSpriteNode!

    let innerCircleRadius:CGFloat = ((screenWidth > 150) ? 46.0 : 39.0)
    var highlightNode:SKSpriteNode!
    var childrenNodes:[SKSpriteNode]! = []
    var circleNode:SKSpriteNode?
    var rotationDegrees:Double = 0.0
    var currentIndex:Int = 0
    var recentStickIndex:Int = 0
    var totalRecordCount:Double = 0
    
    var isCrownLocked = false
    var ignoreAttemptCount:Int = 20
    
    convenience required init(withSceneSize size: CGSize) {
        self.init(size: size)
        self.backgroundColor = UIColor.clear
        
        self.circleNode = SKSpriteNode.init(color: UIColor.clear, size: size)
        self.circleNode?.texture = SKTexture.init(imageNamed: "base-aqua-60")
            self.circleNode?.position = CGPoint.init(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.circleNode?.anchorPoint = CGPoint.init(x: 0.5, y: 0.5)
        self.addChild(self.circleNode!)
        
        shineNode = SKSpriteNode.init(color: UIColor.clear, size: CGSize.init(width: circleDiameter, height: circleDiameter))
        shineNode.blendMode = SKBlendMode.multiplyX2
        shineNode.texture = SKTexture.init(image: UIImage.init(named: "shine-new")!)
        shineNode.position = CGPoint(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.addChild(shineNode)

        self.renderDefaultNodes()
    }
    
    private func renderDefaultNodes(){
        self.circleNode?.removeAllChildren()
        self.childrenNodes.removeAll()
        
        let Circle = SKShapeNode(circleOfRadius: innerCircleRadius) // Create circle
        Circle.position = CGPoint(x: 0, y: 0)
        Circle.strokeColor = SKColor.init(red: 26/255.0, green: 37/255.0, blue: 41/255.0, alpha: 1.0)
        Circle.fillColor = SKColor.clear
        Circle.lineWidth = 3.22
        self.circleNode?.addChild(Circle)

        let numOfBins = FTVisualizationSettings.circularVisualizerSettings().numOfBins
        let newRadius:CGFloat = (innerCircleRadius + 6.0)
        let newDiameter:CGFloat = 134
        for index in 0...numOfBins-1{
            
            let zRotation = CGFloat(Double(index) * (360.0 / Double(numOfBins)) * Double.pi) / 180.0
            let x:CGFloat = (CGFloat)(newRadius * cos(zRotation)) + (newDiameter / 2.0);
            let y:CGFloat = (CGFloat)(newRadius * sin(zRotation)) + (newDiameter / 2.0);
            
            self.highlightNode = SKSpriteNode.init(color: UIColor.init(red: 138/255.0, green: 204/255.0, blue: 234/255.0, alpha: 1.0), size: CGSize.init(width: 13, height: (index % 12 == 0) ? 2.0 : 1.0))
            self.highlightNode.zRotation = zRotation
            self.highlightNode.colorBlendFactor = 1.0
            self.highlightNode.alpha = (index % 12 == 0) ? DEFAULT_ALPHA : INTERMEDIATE_ALPHA
            self.highlightNode.position = CGPoint.init(x: x - (newDiameter / 2.0), y: y - (newDiameter / 2.0))
            self.highlightNode.anchorPoint = CGPoint.init(x: 0.0, y: self.highlightNode.anchorPoint.y)
            self.circleNode?.addChild(self.highlightNode)
            
            self.childrenNodes.append(self.highlightNode)
        }
        self.circleNode?.zRotation = CGFloat(90 * Float.pi / 180)
    }
    
    func refreshNodesWithCount(_ totalCount:Int){
        self.totalRecordCount = min(Double(SUPPORTED_TOTAL_COUNT), Double(totalCount))
        self.currentIndex = 0
        self.rotationDegrees = 0.0
        self.manageRecordingsListDisplay()

        self.updateCrownPosition()
    }
    
    //MARK:- Crown Sequencer Updates
    func didChangeCrownDelta(_ crownDelta:Double){
        if(self.totalRecordCount == 0 || audioServiceCurrentState == .recording){
            return
        }
        if(self.isCrownLocked){
            self.ignoreAttemptCount -= 1
            if(self.ignoreAttemptCount == 0){
                self.ignoreAttemptCount = 20
                self.isCrownLocked = false
            }
            else
            {
                return
            }
        }
        
        var newCrownDelta = (crownDelta * 1.0)
        if(crownDelta > 1.0){
            newCrownDelta = 1.0
        }
        else if(crownDelta < -1.0)
        {
            newCrownDelta = -1.0
        }
        if(newCrownDelta < 0.0){
            self.rotationDegrees += max(-3.0, (newCrownDelta * SINGLE_PART_ANGLE * 5.0))
        }
        else
        {
            self.rotationDegrees += min(3.0, (newCrownDelta * SINGLE_PART_ANGLE * 5.0))
        }
        
        if(self.rotationDegrees < 0.0){
            self.rotationDegrees = 0.0
            self.circleDelegate?.recentAudioCircleDidCrossMinLimit()
        }
        if(self.rotationDegrees > ((self.totalRecordCount-1) * SINGLE_PART_ANGLE)){
            if(Int(self.totalRecordCount) < SUPPORTED_TOTAL_COUNT){
                self.circleDelegate?.recentAudioCircleDidCrossMaxLimit()
            }
        }
        if(self.rotationDegrees > (((self.totalRecordCount-1) * SINGLE_PART_ANGLE) + 21)){
            self.rotationDegrees = ((self.totalRecordCount-1)*SINGLE_PART_ANGLE)
            self.currentIndex = Int(self.totalRecordCount-1)
        }
        if(newCrownDelta >= 0){
            if self.rotationDegrees.truncatingRemainder(dividingBy: SINGLE_PART_ANGLE) >= (SINGLE_PART_ANGLE * 8 / 12){
                self.rotationDegrees = (Double(min(self.totalRecordCount-1, Double(self.currentIndex + 1))) * SINGLE_PART_ANGLE)
                self.updateCurrentIndex(Int(self.rotationDegrees / SINGLE_PART_ANGLE))
                self.isCrownLocked = true
            }
        }
        else
        {
            if self.rotationDegrees.truncatingRemainder(dividingBy: SINGLE_PART_ANGLE) < (SINGLE_PART_ANGLE * 4 / 12){
                self.rotationDegrees = (Double(max(0, self.currentIndex-1)) * SINGLE_PART_ANGLE)
                self.updateCurrentIndex(Int(self.rotationDegrees / SINGLE_PART_ANGLE))
                self.isCrownLocked = true
            }
        }
        self.updateCrownPosition()
    }
    func didCrownBecomeIdle(){
        if(self.totalRecordCount == 0 || audioServiceCurrentState == .recording){
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isCrownLocked = false
            self.ignoreAttemptCount = 20
        }
        //WKInterfaceDevice.current().play(.click)
        self.rotationDegrees = Double(self.currentIndex) * SINGLE_PART_ANGLE
        self.updateCrownPosition()
        self.manageRecordingsListDisplay()
    }

    private func updateCurrentIndex(_ newIndex:Int){
        if(self.currentIndex != newIndex){
            WKInterfaceDevice.current().play(.click)
            self.circleDelegate?.recentAudioCircleDidChange(withIndex: newIndex)
            self.manageRecordingsListDisplay()
            
            var newStickIndex = ((SUPPORTED_TOTAL_COUNT - newIndex) % 10) * 12
            if(newStickIndex == 0){
                newStickIndex = 119
            }
            self.childrenNodes[newStickIndex].alpha = 1.0
            if(newStickIndex < self.recentStickIndex){
                for index in newStickIndex...self.recentStickIndex{
                    if(index > ((SUPPORTED_TOTAL_COUNT - (self.currentIndex + 1)) * 12)){
                        self.childrenNodes[index].alpha = INTERMEDIATE_LIGHT_ALPHA
                    }
                    if(index % 12 != 0){
                        self.childrenNodes[index].run(SKAction.fadeAlpha(to: INTERMEDIATE_ALPHA, duration: 0.5))
                    }
                }
            }
            else
            {
                for index in self.recentStickIndex...newStickIndex{
                    if(index > ((SUPPORTED_TOTAL_COUNT - (self.currentIndex + 1)) * 12)){
                        self.childrenNodes[index].alpha = INTERMEDIATE_LIGHT_ALPHA
                    }
                    if(index % 12 != 0){
                        self.childrenNodes[index].run(SKAction.fadeAlpha(to: INTERMEDIATE_ALPHA, duration: 0.5))
                    }
                }
            }
            self.recentStickIndex = newIndex * 12
        }
        self.currentIndex = newIndex
    }
    private func updateCrownPosition(){
        if(self.isCrownLocked == true){
            return;
        }
        var index:Int  = min(119, (119 - (Int(self.rotationDegrees) / 3)) % 120)
        index = max(0, index)
        #if DEBUG
        debugPrint("self.rotationDegrees: \(self.rotationDegrees)")
        debugPrint(index)
        #endif
        if(index > ((SUPPORTED_TOTAL_COUNT - (self.currentIndex + 1)) * 12)){
            self.recentStickIndex = index
            self.childrenNodes[index].alpha = INTERMEDIATE_LIGHT_ALPHA
        }
        if(index % 12 != 0){
            self.childrenNodes[index].run(SKAction.fadeAlpha(to: INTERMEDIATE_ALPHA, duration: 0.5))
        }
        self.childrenNodes[((SUPPORTED_TOTAL_COUNT - self.currentIndex) % 10) * 12].alpha = 1.0
    }
    //Public methods
    func setSelectedIndex(_ newIndex:Int){
        if(self.currentIndex != newIndex){
            for stickIndex in 0...SUPPORTED_TOTAL_COUNT-1 {
                self.childrenNodes[stickIndex*12].alpha = DEFAULT_ALPHA
            }
            self.currentIndex = newIndex
            self.manageRecordingsListDisplay()

            self.rotationDegrees = Double(self.currentIndex)*SINGLE_PART_ANGLE
            self.updateCrownPosition()
        }
    }
    internal func manageRecordingsListDisplay(){
        for stickIndex in 0...SUPPORTED_TOTAL_COUNT-1 {
            if((SUPPORTED_TOTAL_COUNT - stickIndex)%SUPPORTED_TOTAL_COUNT < Int(self.totalRecordCount)){
                self.childrenNodes[stickIndex*12].color = UIColor.init(red: 138/255.0, green: 204/255.0, blue: 234/255.0, alpha: 1.0)
                self.childrenNodes[stickIndex*12].alpha = DEFAULT_ALPHA
            }
            else
            {
                self.childrenNodes[stickIndex*12].color = UIColor.darkGray
                self.childrenNodes[stickIndex*12].alpha = DEFAULT_ALPHA
            }
            self.childrenNodes[((SUPPORTED_TOTAL_COUNT - self.currentIndex) % 10) * 12].alpha = 1.0
        }
    }
}
