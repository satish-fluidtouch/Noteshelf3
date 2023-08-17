//
//  CropView.swift
//  EditImage
//
//  Created by Matra on 28/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

protocol CropRectViewDelegate: AnyObject {
    func cropRectViewDidBeginEditing(_ view: CropView)
    func cropRectViewDidChange(_ view: CropView)
    func cropRectViewDidEndEditing(_ view: CropView)
}

class CropView: UIView, ResizeControlDelegate {

    weak var delegate: CropRectViewDelegate?
    var dashedBorder:CAShapeLayer!
    
    var keepAspectRatio = false {
        didSet {
            if keepAspectRatio {
                let width = bounds.width
                let height = bounds.height
                fixedAspectRatio = min(width / height, height / width)
            }
        }
    }
    
    var cropWindowBounds: CGRect?
    
    fileprivate let topLeftCornerView = ResizeControl()
    fileprivate let topRightCornerView = ResizeControl()
    fileprivate let bottomLeftCornerView = ResizeControl()
    fileprivate let bottomRightCornerView = ResizeControl()
    fileprivate let topEdgeView = ResizeControl()
    fileprivate let leftEdgeView = ResizeControl()
    fileprivate let rightEdgeView = ResizeControl()
    fileprivate let bottomEdgeView = ResizeControl()
    fileprivate let topMidView = ResizeControl()
    fileprivate let bottomMidView = ResizeControl()
    fileprivate let leftMidView = ResizeControl()
    fileprivate let rightMidView = ResizeControl()

    fileprivate let centerView = ResizeControl()
    fileprivate var initialRect = CGRect.zero
    fileprivate var fixedAspectRatio: CGFloat = 0.0
    fileprivate let borderColor : UIColor = UIColor.appColor(.accent)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    fileprivate func initialize() {
        backgroundColor = UIColor.clear
        contentMode = .redraw
        self.dashedBorder = CAShapeLayer()
        self.dashedBorder.masksToBounds=true
        self.dashedBorder.strokeColor = UIColor(hexString: "#F2F2F6").cgColor
        self.dashedBorder.lineDashPattern = [2, 3]
        self.dashedBorder.lineWidth = 2.0
        self.dashedBorder.lineJoin=CAShapeLayerLineJoin.miter
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.fillColor = nil
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 0).cgPath
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.layer.allowsEdgeAntialiasing = true;
        self.layer.addSublayer(self.dashedBorder)
        topEdgeView.delegate = self
        addSubview(topEdgeView)
        leftEdgeView.delegate = self
        addSubview(leftEdgeView)
        rightEdgeView.delegate = self
        addSubview(rightEdgeView)
        bottomEdgeView.delegate = self
        addSubview(bottomEdgeView)
        
        topLeftCornerView.delegate = self
        addSubview(topLeftCornerView)
        topRightCornerView.delegate = self
        addSubview(topRightCornerView)
        bottomLeftCornerView.delegate = self
        addSubview(bottomLeftCornerView)
        bottomRightCornerView.delegate = self
        addSubview(bottomRightCornerView)
        
        topMidView.delegate = self
        addSubview(topMidView)
        bottomMidView.delegate = self
        addSubview(bottomMidView)
        leftMidView.delegate = self
        addSubview(leftMidView)
        rightMidView.delegate = self
        addSubview(rightMidView)
        
        centerView.delegate = self
        addSubview(centerView)
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in subviews where subview is ResizeControl {
            if subview.frame.contains(point) {
                return subview
            }
        }
        return nil
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.dashedBorder.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 0).cgPath
        self.dashedBorder.frame = self.bounds
        self.dashedBorder.allowsEdgeAntialiasing = true;
        self.dashedBorder.layoutIfNeeded()
        
        topLeftCornerView.frame.origin = CGPoint(x: (topLeftCornerView.bounds.width / -2.0) , y: topLeftCornerView.bounds.height / -2.0)
        topRightCornerView.frame.origin = CGPoint(x: bounds.width - topRightCornerView.bounds.width / 2.0 , y: topRightCornerView.bounds.height / -2.0)
        bottomLeftCornerView.frame.origin = CGPoint(x: bottomLeftCornerView.bounds.width / -2.0, y: bounds.height - bottomLeftCornerView.bounds.height / 2.0)
        bottomRightCornerView.frame.origin = CGPoint(x: bounds.width - bottomRightCornerView.bounds.width / 2.0, y: bounds.height - bottomRightCornerView.bounds.height / 2.0)
        
        topMidView.frame.origin = CGPoint(x: bounds.midX, y: bounds.origin.y - topMidView.frame.height / 2)
        bottomMidView.frame.origin = CGPoint(x: bounds.midX , y: bounds.maxY - topMidView.frame.height / 2)
        leftMidView.frame.origin = CGPoint(x: bounds.minX - topMidView.frame.width / 2, y: bounds.midY)
        rightMidView.frame.origin = CGPoint(x: bounds.maxX - topMidView.frame.height / 2, y: bounds.midY )
        
        topEdgeView.frame = CGRect(x: topLeftCornerView.frame.maxX, y: topEdgeView.frame.height / -2.0, width: topRightCornerView.frame.minX - topLeftCornerView.frame.maxX, height: topEdgeView.bounds.height)
        leftEdgeView.frame = CGRect(x: leftEdgeView.frame.width / -2.0, y: topLeftCornerView.frame.maxY, width: leftEdgeView.frame.width, height: bottomLeftCornerView.frame.minY - topLeftCornerView.frame.maxY)
        bottomEdgeView.frame = CGRect(x: bottomLeftCornerView.frame.maxX, y: bottomLeftCornerView.frame.minY, width: bottomRightCornerView.frame.minX - bottomLeftCornerView.frame.maxX, height: bottomEdgeView.frame.height)
        rightEdgeView.frame = CGRect(x: bounds.width - rightEdgeView.frame.width / 2.0, y: topRightCornerView.frame.maxY, width: rightEdgeView.frame.width, height: bottomRightCornerView.frame.minY - topRightCornerView.frame.maxY)
        
        centerView.frame = CGRect(x: topLeftCornerView.frame.maxX + 5, y: topLeftCornerView.frame.maxY + 5 , width: topEdgeView.bounds.width - 10, height: leftEdgeView.bounds.height - 10)
        
        topLeftCornerView.addImageView()
        topRightCornerView.addImageView()
        bottomLeftCornerView.addImageView()
        bottomRightCornerView.addImageView()
        topMidView.addImageView()
        bottomMidView.addImageView()
        leftMidView.addImageView()
        rightMidView.addImageView()
        self.delegate?.cropRectViewDidBeginEditing(self)
    }
    
    func drawDottedLine(start p0: CGPoint, end p1: CGPoint) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = borderColor.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [5, 5]
        
        let path = CGMutablePath()
        path.addLines(between: [p0, p1])
        shapeLayer.path = path
        self.layer.addSublayer(shapeLayer)
    }
    
    // MARK: - ResizeControl delegate methods
    func resizeControlDidBeginResizing(_ control: ResizeControl) {
        initialRect = frame
        delegate?.cropRectViewDidBeginEditing(self)
    }
    
    func resizeControlDidResize(_ control: ResizeControl) {
        frame = cropRectWithResizeControlView(control)
        delegate?.cropRectViewDidChange(self)
    }
    
    func resizeControlDidEndResizing(_ control: ResizeControl) {
        delegate?.cropRectViewDidEndEditing(self)
    }
    
    fileprivate func cropRectWithResizeControlView(_ resizeControl: ResizeControl) -> CGRect {
        var rect = frame
        
        if resizeControl == topEdgeView {
            rect = CGRect(x: initialRect.minX,
                          y: initialRect.minY + resizeControl.translation.y,
                          width: initialRect.width,
                          height: initialRect.height - resizeControl.translation.y)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfHeight(rect)
            }
        } else if resizeControl == leftEdgeView {
            rect = CGRect(x: initialRect.minX + resizeControl.translation.x,
                          y: initialRect.minY,
                          width: initialRect.width - resizeControl.translation.x,
                          height: initialRect.height)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfWidth(rect)
            }
        } else if resizeControl == bottomEdgeView {
            rect = CGRect(x: initialRect.minX,
                          y: initialRect.minY,
                          width: initialRect.width,
                          height: initialRect.height + resizeControl.translation.y)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfHeight(rect)
            }
        } else if resizeControl == rightEdgeView {
            rect = CGRect(x: initialRect.minX,
                          y: initialRect.minY,
                          width: initialRect.width + resizeControl.translation.x,
                          height: initialRect.height)
            
            if keepAspectRatio {
                rect = constrainedRectWithRectBasisOfWidth(rect)
            }
        } else if resizeControl == topLeftCornerView {
            rect = CGRect(x: initialRect.minX + resizeControl.translation.x,
                          y: initialRect.minY + resizeControl.translation.y,
                          width: initialRect.width - resizeControl.translation.x,
                          height: initialRect.height - resizeControl.translation.y)
            
            if keepAspectRatio {
                var constrainedFrame: CGRect
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    constrainedFrame = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    constrainedFrame = constrainedRectWithRectBasisOfWidth(rect)
                }
                constrainedFrame.origin.x -= constrainedFrame.width - rect.width
                constrainedFrame.origin.y -= constrainedFrame.height - rect.height
                rect = constrainedFrame
            }
        } else if resizeControl == topRightCornerView {
            rect = CGRect(x: initialRect.minX,
                          y: initialRect.minY + resizeControl.translation.y,
                          width: initialRect.width + resizeControl.translation.x,
                          height: initialRect.height - resizeControl.translation.y)
            
            if keepAspectRatio {
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    rect = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    rect = constrainedRectWithRectBasisOfWidth(rect)
                }
            }
        } else if resizeControl == bottomLeftCornerView {
            rect = CGRect(x: initialRect.minX + resizeControl.translation.x,
                          y: initialRect.minY,
                          width: initialRect.width - resizeControl.translation.x,
                          height: initialRect.height + resizeControl.translation.y)
            
            if keepAspectRatio {
                var constrainedFrame: CGRect
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    constrainedFrame = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    constrainedFrame = constrainedRectWithRectBasisOfWidth(rect)
                }
                constrainedFrame.origin.x -= constrainedFrame.width - rect.width
                rect = constrainedFrame
            }
        } else if resizeControl == bottomRightCornerView {
            rect = CGRect(x: initialRect.minX,
                          y: initialRect.minY,
                          width: initialRect.width + resizeControl.translation.x,
                          height: initialRect.height + resizeControl.translation.y)
            
            if keepAspectRatio {
                if abs(resizeControl.translation.x) < abs(resizeControl.translation.y) {
                    rect = constrainedRectWithRectBasisOfHeight(rect)
                } else {
                    rect = constrainedRectWithRectBasisOfWidth(rect)
                }
            }
        } else if resizeControl == centerView {
            rect = CGRect(x: initialRect.minX + resizeControl.translation.x,
                          y: initialRect.minY + resizeControl.translation.y,
                          width: initialRect.width ,
                          height: initialRect.height)
            #if DEBUG
            debugPrint("center view: rect: \(rect)")
            #endif
        }
        
//        let minWidth = leftEdgeView.bounds.width + rightEdgeView.bounds.width
        let minWidth : CGFloat = 100.0
        if rect.width < minWidth {
            rect.origin.x = frame.maxX - minWidth
            rect.size.width = minWidth
        }
        
        let minHeight : CGFloat = 100.0
//        let minHeight = topEdgeView.bounds.height + bottomEdgeView.bounds.height
        if rect.height < minHeight {
            rect.origin.y = frame.maxY - minHeight
            rect.size.height = minHeight
        }
        
        if fixedAspectRatio > 0 {
            var constraintedFrame = rect
            if rect.width < minWidth {
                constraintedFrame.size.width = rect.size.height * (minWidth / rect.size.width)
            }
            if rect.height < minHeight {
                constraintedFrame.size.height = rect.size.width * (minHeight / rect.size.height)
            }
            rect = constraintedFrame
        }
        
        return rect
    }
    
    
    
    fileprivate func constrainedRectWithRectBasisOfWidth(_ frame: CGRect) -> CGRect {
        var result = frame
        let width = frame.width
        var height = frame.height
        
        if width < height {
            height = width / fixedAspectRatio
        } else {
            height = width * fixedAspectRatio
        }
        result.size = CGSize(width: width, height: height)
        return result
    }
    
    fileprivate func constrainedRectWithRectBasisOfHeight(_ frame: CGRect) -> CGRect {
        var result = frame
        var width = frame.width
        let height = frame.height
        
        if width < height {
            width = height * fixedAspectRatio
        } else {
            width = height / fixedAspectRatio
        }
        result.size = CGSize(width: width, height: height)
        return result
    }

}
