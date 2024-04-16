//
//  FTPenSizeCollectionViewCell.swift
//  FTPenRack
//
//  Created by Siva on 08/04/17.
//  Copyright © 2017 Fluid Touch Pvt Ltd. All rights reserved.
//

import UIKit


class FTPenSizeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var sizeImageView: UIImageView!
    
    override var canBecomeFocused: Bool {
        return false
    }
}

extension UIView {
    
    private struct AnimationKey {
        static let Rotation = "rotation"
        static let Bounce = "bounce"
    }
    
    public func startWiggle(){
        
        let wiggleBounceY = 2.0
        let wiggleBounceDuration = 0.18
        let wiggleBounceDurationVariance = 0.025
        
        let wiggleRotateAngle = 0.02
        let wiggleRotateDuration = 0.14
        let wiggleRotateDurationVariance = 0.025
        
        if // If the view is already animating rotation or bounce, return
            let keys = layer.animationKeys(),
            keys.contains(AnimationKey.Rotation) == false,
            keys.contains(AnimationKey.Bounce) == false
        {
            return
        }
        
        //Create rotation animation
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.values = [-wiggleRotateAngle, wiggleRotateAngle]
        rotationAnimation.autoreverses = true
        rotationAnimation.duration = randomize(interval: wiggleRotateDuration, withVariance: wiggleRotateDurationVariance)
        rotationAnimation.repeatCount = .infinity
        
        //Create bounce animation
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounceAnimation.values = [wiggleBounceY, 0]
        bounceAnimation.autoreverses = true
        bounceAnimation.duration = randomize(interval: wiggleBounceDuration, withVariance: wiggleBounceDurationVariance)
        bounceAnimation.repeatCount = .infinity
        
        //Apply animations to view
        UIView.animate(withDuration: 0) {
            self.layer.add(rotationAnimation, forKey: AnimationKey.Rotation)
            self.layer.add(bounceAnimation, forKey: AnimationKey.Bounce)
            self.transform = .identity
        }
    }
    
    public func stopWiggle(){
        layer.removeAnimation(forKey: AnimationKey.Rotation)
        layer.removeAnimation(forKey: AnimationKey.Bounce)
    }
    
    // Utility
    
    private func randomize(interval: TimeInterval, withVariance variance: Double) -> Double{
        let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
        return interval + variance * random
    }
    
    public func popOnce() {
        let identityAnimation = CGAffineTransform.identity
        let scaleOfIdentity = identityAnimation.scaledBy(x: 0.001, y: 0.001)
        self.transform = scaleOfIdentity
        UIView.animate(withDuration: 0.3, animations: {
            let scaleOfIdentity = identityAnimation.scaledBy(x: 1.3, y: 1.3)
            self.transform = scaleOfIdentity
        }, completion: {finished in
            UIView.animate(withDuration: 0.2, animations: {
                let scaleOfIdentity = identityAnimation.scaledBy(x: 0.9, y: 0.9)
                self.transform = scaleOfIdentity
            }, completion: {finished in
                UIView.animate(withDuration: 0.2, animations: {
                    self.transform = identityAnimation
                })
            })
        })
    }
}
