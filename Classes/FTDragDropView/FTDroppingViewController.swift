//
//  FTDroppingViewController.swift
//  Whink
//
//  Created by Naidu on 28/8/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc class FTDroppingViewController: UIViewController {
//    @IBOutlet var dropBorderView:DropBorderView! // Not using border now, if needs then refer this class name and connect in xib
    @IBOutlet var infoLabel:UILabel!
    @IBOutlet var imageIcon:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isUserInteractionEnabled = false;
        self.view.translatesAutoresizingMaskIntoConstraints = false;
    }

    @objc func updateInformativeMessage(_ message:String)
    {
        self.infoLabel.text=message
    }
    @objc func updateInformativeMessage(_ message:String, andImage imageName:String)
    {
        self.infoLabel.text=message
        self.imageIcon.image=UIImage.init(named: imageName)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
class DropBorderView:UIView{
    var dashedBorder:CAShapeLayer!
    var radius: CGFloat = 0.0;
    var photoMode = FTPhotoMode.normal {
        didSet {
            if photoMode == .normal {
                self.layer.borderColor = UIColor(hexString: "#305EF7").cgColor
                self.layer.borderWidth = 1
            } else {
                self.layer.addSublayer(self.dashedBorder)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dashedBorder = CAShapeLayer()
        self.dashedBorder.strokeColor = UIColor.appColor(.accent).cgColor
        self.dashedBorder.lineDashPattern = [4, 4]
        self.dashedBorder.lineWidth = 2.0
        self.dashedBorder.lineJoin=CAShapeLayerLineJoin.miter
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.fillColor = nil
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius).cgPath
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.layer.allowsEdgeAntialiasing = true;
    }
    
    override func layoutSubviews() { //To refresh border layer when changed to various split modes
        super.layoutSubviews()
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius).cgPath
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.dashedBorder.layoutIfNeeded()
    }
}
