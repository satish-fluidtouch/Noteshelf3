//
//  UIView+Rotation.swift
//  Noteshelf
//
//  Created by Naidu on 10/03/20.
//
//

import Foundation
import UIKit

class FTBookOpeningSpinner: UIView {
    @IBOutlet weak var spinImageView: UIImageView?
    
    //Start Rotating view
    func startRotating(duration: Double = 1) {
        self.isHidden = false
        let kAnimationKey = "rotation"
        if self.spinImageView?.layer.animation(forKey: kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity

            animate.fromValue = 0.0
            animate.toValue = Float(Double.pi * 2.0)
            self.spinImageView?.layer.add(animate, forKey: kAnimationKey)
        }
    }
    
    //Stop rotating view
    func stopRotating() {
        let kAnimationKey = "rotation"
        
        if self.spinImageView?.layer.animation(forKey: kAnimationKey) != nil {
            self.spinImageView?.layer.removeAnimation(forKey: kAnimationKey)
        }
        self.isHidden = true
    }
    
}
