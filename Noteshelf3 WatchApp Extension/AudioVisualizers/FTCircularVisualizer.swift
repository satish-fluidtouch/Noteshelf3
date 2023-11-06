//
//  FTCircularVisualizer.swift
//  NS2Watch Extension
//
//  Created by Simhachalam on 12/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SpriteKit

class FTCircularVisualizer: FTBaseVisualizerScene {

    let circleDiameter:CGFloat = screenWidth
    let DEFAULT_ALPHA: CGFloat = 0.3
    let innerCircleRadius:CGFloat = ((screenWidth > 150) ? 46.0 : 39.0)

    var highlightNode:SKSpriteNode!
    var childrenNodes:[SKSpriteNode]! = []
    var circleNode:SKSpriteNode?
    var backgroundNode:SKSpriteNode?
    var repeatRotationAction:SKAction!
    var shineNode:SKSpriteNode!

    convenience required init(withSceneSize size: CGSize) {
        self.init(size: size)
        self.backgroundColor = UIColor.clear

        self.visualizerType = FTVisualizerType.circularWave
        self.visualizerSettings = FTVisualizationSettings.circularVisualizerSettings()

        self.circleNode = SKSpriteNode.init(color: UIColor.clear, size: size)
        self.circleNode?.position = CGPoint.init(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.circleNode?.texture = SKTexture.init(imageNamed: "base")
        self.circleNode?.anchorPoint = CGPoint.init(x: 0.5, y: 0.5)
        self.addChild(self.circleNode!)

        let Circle = SKShapeNode(circleOfRadius: innerCircleRadius) // Create circle
        Circle.position = CGPoint(x: circleDiameter/2.0, y: circleDiameter/2.0)  // Center (given scene anchor point is 0.5 for x&y)
        Circle.strokeColor = SKColor.init(red: 248/255.0, green: 113/255.0, blue: 58/255.0, alpha: 1.0)
        Circle.glowWidth = 0.0
        Circle.fillColor = SKColor.clear
        Circle.lineWidth = 2.0
        self.addChild(Circle)

        shineNode = SKSpriteNode.init(color: UIColor.clear, size: CGSize.init(width: circleDiameter, height: circleDiameter))
        shineNode.texture = SKTexture.init(image: UIImage.init(named: "shine")!)
        shineNode.blendMode = SKBlendMode.multiplyX2
        shineNode.alpha = 0.0
        shineNode.position = CGPoint(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.addChild(shineNode)

        self.renderDefaultNodes()

        //Initially rorate anticlock-wise slowly
        let someAction = SKAction.rotate(byAngle: CGFloat(-Double.pi), duration:30.0)
        self.repeatRotationAction = SKAction.repeatForever(someAction)
        self.circleNode?.run(self.repeatRotationAction)
    }
    private func renderDefaultNodes(){
        self.circleNode?.removeAllChildren()
        self.childrenNodes.removeAll()
        let numOfBins = self.visualizerSettings.numOfBins
        let newRadius:CGFloat = (innerCircleRadius + 6.0)
        let newDiameter:CGFloat = ((screenWidth > 150) ? 134.0 : 104.0)

        for index in 0...numOfBins-1{

            let zRotation = CGFloat(Double(index) * (360.0 / Double(numOfBins)) * Double.pi) / 180.0
            let x:CGFloat = (CGFloat)(newRadius * cos(zRotation)) + (newDiameter / 2.0);
            let y:CGFloat = (CGFloat)(newRadius * sin(zRotation)) + (newDiameter / 2.0);

            self.highlightNode = SKSpriteNode.init(color: UIColor.init(red: 210/255.0, green: 100/255.0, blue: 52/255.0, alpha: 1.0), size: CGSize.init(width: 13, height: 1.0))
            self.highlightNode.colorBlendFactor = 1.0
            self.highlightNode.zRotation = zRotation
            self.highlightNode.alpha = DEFAULT_ALPHA
            self.highlightNode.position = CGPoint.init(x: x - (newDiameter / 2.0), y: y - (newDiameter / 2.0))
            self.highlightNode.anchorPoint = CGPoint.init(x: 0.0, y: self.highlightNode.anchorPoint.y)
            self.circleNode?.addChild(self.highlightNode)

            self.childrenNodes.append(self.highlightNode)
        }
    }

    //MARK:- FTVisualizationTarget
    override func currentVizualizerSettings() -> FTVisualizationSettings {
        return self.visualizerSettings
    }
    override func updateVisualizerWithData(_ visualizationData:FTVisualizationDataProtocol) {
        if(isInForeground && audioServiceCurrentState == FTAudioServiceStatus.recording){
            for index in 0...self.visualizerSettings.numOfBins-1{
                if(self.childrenNodes.count > 0){
                    let spriteNode:SKSpriteNode = self.childrenNodes[Int(index)]
                    let newAlpha = CGFloat((visualizationData as! FTAudioDataProcessor).frequencyHeights()[Int(index)]) / self.visualizerSettings.maxBinHeight

                    let value:CGFloat = DEFAULT_ALPHA + ((newAlpha*(1.0-DEFAULT_ALPHA))/1.0)
                    spriteNode.alpha = value
                }
            }
        }
    }
    override func didStartProcessingData() {
        shineNode.alpha = 1.0
        self.circleNode?.removeAllActions()

        //Roate
        let someAction = SKAction.rotate(byAngle: -CGFloat(Double.pi), duration:10.0)
        self.repeatRotationAction = SKAction.repeatForever(someAction)
        self.circleNode?.run(self.repeatRotationAction)
    }
    override func didPauseProcessingData() {
        self.circleNode?.removeAllActions()
        let someAction = SKAction.rotate(byAngle: CGFloat(-Double.pi), duration:30.0)
        self.repeatRotationAction = SKAction.repeatForever(someAction)
        self.circleNode?.run(self.repeatRotationAction)

        for index in 0...self.visualizerSettings.numOfBins-1{
            if(self.childrenNodes.count > 0){
                let spriteNode:SKSpriteNode = self.childrenNodes[Int(index)]
                spriteNode.run(SKAction.fadeAlpha(to: DEFAULT_ALPHA, duration: 0.2))
            }
        }
    }

    override func didStopProcessingData() {
        self.circleNode?.removeAllActions()
        shineNode.alpha = 0.0
        let someAction = SKAction.rotate(byAngle: CGFloat(-Double.pi), duration:30.0)
        self.repeatRotationAction = SKAction.repeatForever(someAction)
        self.circleNode?.run(self.repeatRotationAction)

        for index in 0...self.visualizerSettings.numOfBins-1{
            if(self.childrenNodes.count > 0){
                let spriteNode:SKSpriteNode = self.childrenNodes[Int(index)]
                spriteNode.run(SKAction.fadeAlpha(to: DEFAULT_ALPHA, duration: 0.2))
            }
        }
    }
}

public extension Double {
    static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
    static func random(min: Double, max: Double) -> Double {
        return Double.random * (max - min) + min
    }
}

