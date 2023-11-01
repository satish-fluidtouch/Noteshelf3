//
//  FTPlayerVisualizer.swift
//  NS2Watch Extension
//
//  Created by Naidu on 21/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SpriteKit

class FTPlayerVisualizer: FTBaseVisualizerScene {
    
    let circleDiameter:CGFloat = screenWidth
    let DEFAULT_ALPHA: CGFloat = 0.3
    let innerCircleRadius:CGFloat = ((screenWidth > 150) ? 46.0 : 39.0)

    var highlightNode:SKSpriteNode!
    var childrenNodes:[SKSpriteNode]! = []
    var circleNode:SKSpriteNode?
    var progressRing: SKRingNode!
    var volumeRing: SKRingNode!
    var repeatRotationAction:SKAction!
    var shineNode:SKSpriteNode!
    
    convenience required init(withSceneSize size: CGSize) {
        self.init(size: size)
        self.backgroundColor = UIColor.clear
        
        self.visualizerType = FTVisualizerType.circularWave
        self.visualizerSettings = FTVisualizationSettings.circularVisualizerSettings()
        
        self.circleNode = SKSpriteNode(texture: SKTexture(imageNamed: "base-aqua"))
        self.circleNode?.color = UIColor.init(red: 136.0/255.0, green: 197.0/255.0, blue: 210.0/255.0, alpha: 1)
        self.circleNode?.colorBlendFactor = 1.0 
        self.circleNode?.size = size

//        self.circleNode = SKSpriteNode.init(color: UIColor.clear, size: size)
//        self.circleNode?.texture = SKTexture.init(imageNamed: "base-aqua")
        self.circleNode?.position = CGPoint.init(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.circleNode?.anchorPoint = CGPoint.init(x: 0.5, y: 0.5)
        self.addChild(self.circleNode!)
        
        self.progressRing = SKRingNode(diameter: innerCircleRadius * 2, thickness:0.07)
        self.progressRing.setCenterImage(withName: "stop", andSize: CGSize.init(width: 26, height: 26))
        self.progressRing.position = CGPoint.init(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.addChild(self.progressRing)
        
        self.volumeRing = SKRingNode(diameter: innerCircleRadius * 2, thickness:0.07)
        self.volumeRing.setCenterImage(withName: "volume", andSize: CGSize.init(width: 30, height: 29))
        self.volumeRing.position = CGPoint.init(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.volumeRing.color = UIColor.init(red: 136.0/255.0, green: 197.0/255.0, blue: 210.0/255.0, alpha: 0.6)
        self.addChild(self.volumeRing)
        self.volumeRing.isHidden = true

        shineNode = SKSpriteNode.init(color: UIColor.clear, size: CGSize.init(width: circleDiameter, height: circleDiameter))
        shineNode.blendMode = SKBlendMode.multiplyX2
        shineNode.texture = SKTexture.init(image: UIImage.init(named: "shine-aqua")!)
        shineNode.position = CGPoint(x: circleDiameter/2.0, y: circleDiameter/2.0)
        self.addChild(shineNode)

        self.renderDefaultNodes()
    }
    
    private func renderDefaultNodes(){
        self.circleNode?.removeAllChildren()
        self.childrenNodes.removeAll()
        let numOfBins = self.visualizerSettings.numOfBins
        let newRadius:CGFloat = (innerCircleRadius + 6.0)
        let newDiameter:CGFloat = 134
        for index in 0...numOfBins-1{
            
            let zRotation = CGFloat(Double(index) * (360.0 / Double(numOfBins)) * Double.pi) / 180.0
            let x:CGFloat = (CGFloat)(newRadius * cos(zRotation)) + (newDiameter / 2.0);
            let y:CGFloat = (CGFloat)(newRadius * sin(zRotation)) + (newDiameter / 2.0);
            
            self.highlightNode = SKSpriteNode.init(color: UIColor.init(red: 136/255.0, green: 197/255.0, blue: 210/255.0, alpha: 1.0), size: CGSize.init(width: 13, height: 1.0))
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
        if(isInForeground){
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
        //Roate
        self.circleNode?.removeAllActions()
        
        let someAction = SKAction.rotate(byAngle: -CGFloat(Double.pi), duration:10.0)
        self.repeatRotationAction = SKAction.repeatForever(someAction)
        self.circleNode?.run(self.repeatRotationAction)
    }
    override func didPauseProcessingData() {
        
    }
    override func didStopProcessingData() {
        self.circleNode?.removeAllActions()
        
        for index in 0...self.visualizerSettings.numOfBins-1{
            if(self.childrenNodes.count > 0){
                let spriteNode:SKSpriteNode = self.childrenNodes[Int(index)]
                spriteNode.run(SKAction.fadeAlpha(to: DEFAULT_ALPHA, duration: 0.2))
            }
        }
    }
    
    func startAudioProgress(withDuration duration:TimeInterval){
        self.progressRing.removeAllActions()
        self.progressRing.isHidden = false
        self.volumeRing.isHidden = true

        let pauseTime = max((recentPlayedAudio["currentTime"] as! Double)-1.0, 0.0)
        self.progressRing.arcEnd = CGFloat(pauseTime) / CGFloat(duration)
        let valueUpEffect = SKTRingValueEffect(for: self.progressRing, to: 1.0, duration: (duration - pauseTime))
        valueUpEffect.timingFunction = SKTTimingFunctionLinear
        let valueUpAction = SKAction.actionWithEffect(valueUpEffect)
        self.progressRing.run(SKAction.repeat(valueUpAction, count: 1))
    }
    func volumeDidChange(to volume:Float){
        self.progressRing.isHidden = true
        self.volumeRing.isHidden = false
        if(volume > 0.0){
            self.volumeRing.setCenterImage(withName: "volume", andSize: CGSize.init(width: 30, height: 29))
        }
        else
        {
            self.volumeRing.setCenterImage(withName: "volume-mute", andSize: CGSize.init(width: 26, height: 21))
        }

        let valueUpEffect = SKTRingValueEffect(for: self.volumeRing, to: CGFloat(volume), duration: 0.05)
        valueUpEffect.timingFunction = SKTTimingFunctionLinear
        let valueUpAction = SKAction.actionWithEffect(valueUpEffect)
        self.volumeRing.run(SKAction.repeat(valueUpAction, count: 1))
    }
    func didCrownBecomeIdle(){
        self.progressRing.isHidden = false
        self.volumeRing.isHidden = true
    }
}
