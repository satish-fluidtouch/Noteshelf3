//
//  FTLaserPointerViewController.swift
//  Noteshelf
//
//  Created by Akshay on 22/04/21.
//

import UIKit
import SpriteKit
import GameplayKit

class FTLaserPointerViewController: UIViewController {

    var laserColor: UIColor = UIColor.red {
        didSet {
            scene.laserColor = laserColor
        }
    }

    var pointerColor: UIColor = UIColor.white {
        didSet {
            scene.pointerColor = pointerColor
        }
    }

    private lazy var scene = FTLaserScene.scene()

    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = SKView(frame: self.view.bounds)
        skView.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true

        #if DEBUG
            skView.showsFPS = true
            skView.showsNodeCount = true
        #endif

        self.view.addSubview(skView)
        self.view.backgroundColor = .clear

        scene.laserColor = laserColor
        scene.pointerColor = pointerColor
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    static func present(on controller: UIViewController, laserColor: UIColor, pointerColor: UIColor) -> FTLaserPointerViewController {
        let laserVC = FTLaserPointerViewController()
        laserVC.laserColor = laserColor
        laserVC.pointerColor = pointerColor
        laserVC.view.frame = controller.view.bounds;
        laserVC.view.autoresizingMask = [.flexibleWidth,.flexibleHeight];
        controller.addChild(laserVC)
        controller.view.addSubview(laserVC.view)
        return laserVC
    }
}

//MARK: - Configuration and touch movement
extension FTLaserPointerViewController {
    func touchDown(atPoint pos : CGPoint) {
        scene.touchDown(atPoint: transform(point: pos))
    }

    func touchMoved(toPoint pos : CGPoint) {
        scene.touchMoved(toPoint: transform(point: pos))
    }

    func touchUp(atPoint pos : CGPoint) {
        scene.touchUp(atPoint: transform(point: pos))
    }

    private func transform(point: CGPoint) -> CGPoint {
        let converted = self.scene.convertPoint(fromView: point)
        return converted
    }
}
