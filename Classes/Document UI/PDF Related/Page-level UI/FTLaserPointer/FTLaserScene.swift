//
//  LaserScene.swift
//  Noteshelf
//
//  Created by Akshay on 22/04/21.
//
import UIKit
import SpriteKit
import GameplayKit

private let glowRadius: CGFloat = 4
private let glowLineWidth: CGFloat = glowRadius/2
private let glowWidth: CGFloat = glowLineWidth
private let glowColorAlpha: CGFloat = 1

struct FTLaserAnimationValues {
    static var scale: CGFloat = 0.7
    static var scaleDuration: TimeInterval = 0.025
    static var fadeOutDuration: TimeInterval = 0.01

    static func reset() {
        scale = 0.7
        scaleDuration = 0.025
        fadeOutDuration = 0.01
    }
}

class FTLaserScene: SKScene {
    private var lastRenderedPan: CGPoint?
    private var pointStep: CGFloat = 1

    struct FTLine {
        let from: CGPoint
        let to: CGPoint

        let pointStep: CGFloat = 1

        var length: CGFloat {
            return from.distance(to: to)
        }
    }

    private var bezierGenerator = FTBezierGenerator()

    //Configurable
    var laserColor: UIColor = UIColor.red {
        didSet {
            tailNode?.strokeColor = laserColor.withAlphaComponent(glowColorAlpha)
            tailNode?.fillColor = laserColor.withAlphaComponent(glowColorAlpha)
            pointerNode?.strokeColor = laserColor.withAlphaComponent(glowColorAlpha)
        }
    }

    var pointerColor: UIColor = UIColor.white {
        didSet {            
            pointerNode?.fillColor = pointerColor
        }
    }

    //Nodes
    private var tailNode: SKShapeNode?
    private var pointerNode: SKShapeNode?

    static func scene() -> FTLaserScene {
        guard let scene = SKScene(fileNamed: "FTLaserScene") as? FTLaserScene else {
            fatalError("FTLaserScene not found")
        }
        return scene
    }

    override func didMove(to view: SKView) {
        configureLaserNodes()
    }

    private func configureLaserNodes() {
        //Setup pointer node
        let pointer = SKShapeNode(circleOfRadius: glowRadius)
        pointer.strokeColor = laserColor.withAlphaComponent(glowColorAlpha)
        pointer.fillColor = pointerColor
        pointer.lineWidth = glowLineWidth
        pointer.glowWidth = glowWidth
        pointer.zPosition = 0

        pointerNode = pointer

        //Set up Tailing nodes
        let glowNode = SKShapeNode(circleOfRadius: glowRadius/2)
        glowNode.strokeColor = laserColor.withAlphaComponent(glowColorAlpha)
        glowNode.fillColor = laserColor.withAlphaComponent(glowColorAlpha)
        glowNode.lineWidth = glowRadius
        glowNode.glowWidth = 1
        glowNode.zPosition = -1

        glowNode.run(SKAction.sequence([SKAction.scale(by: FTLaserAnimationValues.scale, duration: FTLaserAnimationValues.scaleDuration),
                                        SKAction.fadeOut(withDuration: FTLaserAnimationValues.fadeOutDuration),
                                        SKAction.removeFromParent()]))
        self.tailNode = glowNode
    }

    //MARK:- Touch Handling
    /*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchDown(atPoint: t.location(in: self))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if let coleasced = event?.coalescedTouches(for: t) {
                for ct in coleasced {
                    self.touchMoved(toPoint: ct.location(in: self))
                }
            } else {
                self.touchMoved(toPoint: t.location(in: self))
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchUp(atPoint: t.location(in: self))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchUp(atPoint: t.location(in: self))
        }
    }
 */

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

}

//MARK:- Node Movement
extension FTLaserScene {

    func touchDown(atPoint pos : CGPoint) {
        addPointer(at: pos)
        bezierGenerator.begin(with: pos)
        pushPoint(pos, to: bezierGenerator)
    }

    func touchMoved(toPoint pos : CGPoint) {
        guard !bezierGenerator.points.isEmpty else { return }
        guard pos != lastRenderedPan else { return }
        movePointer(to: pos)
        pushPoint(pos, to: bezierGenerator)
    }

    func touchUp(atPoint pos : CGPoint) {
        defer {
            removePointer(at: pos)
            bezierGenerator.finish()
            lastRenderedPan = nil
        }

        movePointer(to: pos)

        if bezierGenerator.points.count >= 3 {
            pushPoint(pos, to: bezierGenerator, isEnd: true)
        } else if bezierGenerator.points.count == 2 {
            let start = bezierGenerator.points[0]
            let end = bezierGenerator.points[1]
            let line = FTLine(from: start, to: end)
            renderLine(line)
        }
    }
}

//MARK: - Bezier Geeneration
extension FTLaserScene {
    private func pushPoint(_ point: CGPoint, to bezier: FTBezierGenerator, isEnd: Bool = false) {
        let vertices = bezier.pushPoint(point)
        guard vertices.count >= 2 else {
            return
        }
        var lastPan = lastRenderedPan ?? vertices[0]
        for i in 1 ..< vertices.count {
            let p = vertices[i]
            if  // end point of line
                (isEnd && i == vertices.count - 1) ||
                    // ignore step
                    pointStep <= 1 ||
                    // distance larger than step
                    (pointStep > 1 && lastPan.distance(to: p) >= pointStep)
            {
                let pan = p
                let line = FTLine(from: lastPan, to: pan)
                renderLine(line)
                lastPan = pan
                lastRenderedPan = pan
            }
        }
        //Join the last bezier point with the current point as a line.
        let line = FTLine(from: lastPan, to: point)
        renderLine(line)
    }

    private func renderLine(_ line: FTLine) {
        let count = max(line.length / line.pointStep, 1)
        for i in 0 ..< Int(count) {
            let index = CGFloat(i)
            let x = line.from.x + (line.to.x - line.from.x) * (index / count)
            let y = line.from.y + (line.to.y - line.from.y) * (index / count)
            let linePoint = CGPoint(x: x, y: y)
            addTailNode(at: linePoint)
        }
    }
}

//MARK: - Node movement
extension FTLaserScene {
    private func addTailNode(at point: CGPoint) {
        if let n = self.tailNode?.copy() as? SKShapeNode {
            n.position = point
            self.addChild(n)
        }
    }

    private func addPointer(at pos: CGPoint) {
        pointerNode?.position = pos
        pointerNode?.zPosition = 0
        if let node = pointerNode, node.parent == nil {
            self.addChild(node)
        }
    }

    private func movePointer(to pos: CGPoint) {
        pointerNode?.position = pos
    }

    private func removePointer(at pos: CGPoint) {
        pointerNode?.position = pos
        self.removeAllChildren()
    }
}

// MARK:  distance calculation is extended here
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
