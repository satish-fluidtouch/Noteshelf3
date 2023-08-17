//
//  FTAudioAnnotationIconView.swift
//  Noteshelf
//
//  Created by Matra on 19/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAudioAnnotationView: UIView {

    var imageView: UIImageView?
    var scale : CGFloat = 1.0 {
        didSet{
            self.refreshImage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViews()
    }
    
    func setUpViews() {
        imageView = UIImageView(frame: bounds)
        imageView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        if let imageView = imageView {
            addSubview(imageView)
        }
        refreshImage()
    }
    
    func refreshImage() {
        imageView?.image =  UIImage(named: "audioIcon_sel")!
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
