//
//  FTKnobViews.swift
//  Noteshelf
//
//  Created by Sameer on 30/05/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTKnobView: UIImageView {
    var segmentIndex: Int = 0

    override init(image: UIImage? = UIImage(named: "resizeknob")) {
        super.init(image: image)
       // self.contentMode = .scaleToFill
        self.frame.size = CGSize(width: 15, height: 15)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

 class FTRotateKnobView: UIView {
    var imageView: UIImageView?

    convenience init(with point: CGPoint) {
        self.init()
        frame.size = CGSize(width: 28, height: 28)
        addImageView()
        center = point
    }
    var isKnobHidden : Bool = false {
        didSet {
            imageView?.isHidden = false
        }
    }

    private func addImageView() {
        imageView = UIImageView(image: UIImage(named: "shaperotate"))
        if let imageView = imageView {
          //  imageView.size = frame
            self.addSubview(imageView)
        }
    }
}

class FTKnobCircleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        var newRect = rect
        newRect = newRect.insetBy(dx: 1, dy:  1)
        let ovalPath = UIBezierPath(ovalIn: newRect)
        UIColor.black.setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }
    
    func point(onEllipse angle: CGFloat) -> CGPoint {
        var newPoint: CGPoint
        let boundingRectSize = frame
        let x: CGFloat = center.x + (boundingRectSize.width / 2) * cos(DEGREES_RADIANS(angle - 90))
        let y: CGFloat = center.y + (boundingRectSize.height / 2) * sin(DEGREES_RADIANS(angle - 90))
        newPoint = FTShapeUtility.rotatePoint(byAngle: center, andPoint: CGPoint(x: x, y: y), angle: 0)
        return newPoint
    }
    
    required init(coder aDecoder: NSCoder) {
      fatalError("Use init(fillColor:, strokeColor:)")
    }
}

class FTDragView: UIView {
    init(with point: CGPoint) {
        super.init(frame: CGRect(origin: point, size: CGSize(width: 20, height: 20)))
        self.layer.cornerRadius = frame.height / 2
        self.backgroundColor = UIColor.clear
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("Use init(fillColor:, strokeColor:)")
    }
}
