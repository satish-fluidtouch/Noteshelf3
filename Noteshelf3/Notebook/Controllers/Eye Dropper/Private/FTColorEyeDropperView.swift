//
//  FTEyeDropperVoew.swift
//  FTColorPicker
//
//  Created by Amar Udupa on 12/07/23.
//

import UIKit

protocol FTColorEyeDropperDelegate: NSObjectProtocol {
    func colorDropper(_ dropperView: FTColorEyeDropperView,didPickColor color: UIColor);
}

private let userSelfDraw = true;

class FTColorEyeDropperView: FTMagnifyingGlassView {
    private lazy var colorCircleLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer();
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 20;
        shapeLayer.addSublayer(innerCirleLayer);
        return shapeLayer;
    }()
    
    private lazy var innerCirleLayer:CAShapeLayer = {
        let shapeLayer = CAShapeLayer();
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.lightGray.cgColor;
        shapeLayer.lineWidth = 4;
        return shapeLayer;
    }();
    
    weak var delegate: FTColorEyeDropperDelegate?;
    
    override var showsCrosshair: Bool {
        didSet {
            self.colorCircleLayer.isHidden = !showsCrosshair;
        }
    }
    
    override var frame: CGRect {
        didSet {
            self.colorCircleLayer.frame = self.layer.bounds;
            self.colorCircleLayer.path = UIBezierPath(ovalIn: self.colorCircleLayer.bounds).cgPath;

            self.innerCirleLayer.frame = self.colorCircleLayer.bounds.insetBy(dx: 10, dy: 10);
            self.innerCirleLayer.path = UIBezierPath(ovalIn: self.innerCirleLayer.bounds).cgPath;
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame);
        self.layer.addSublayer(self.colorCircleLayer);
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var currentColor: UIColor = .clear {
        didSet{
            self.colorCircleLayer.strokeColor = currentColor.cgColor;
            self.delegate?.colorDropper(self, didPickColor: currentColor);
        }
    }
    
    override func magnify(at point: CGPoint) {
        super.magnify(at: point);
        self.currentColor = readColor();
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect);
    }
}

private extension FTColorEyeDropperView {
    private func readColor() -> UIColor {
        let width = 1;
        let height = 1;
        
        guard let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride) else {
            return UIColor.white;
        }
        defer {
            free(rawData);
        }
        
        let cref = CGColorSpaceCreateDeviceRGB();
        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext.init(data: rawData,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: 8,
                                           bytesPerRow: 4 * width,
                                           space: cref,
                                           bitmapInfo: options) else {
            return .clear
        }

        if(userSelfDraw) {
            self.showsCrosshair = false;
            context.translateBy(x: -self.bounds.midX, y: -self.bounds.midY);
            self.layer.render(in: context)
            self.showsCrosshair = true;
        }
        else {
            context.translateBy(x: -self.frame.midX, y: -self.frame.midY);
            magnifiedView?.layer.render(in: context)
        }
        return context.readPixelColorAt(x: 0, y: 0);
    }
}

private extension CGContext {
    func readPixelColorAt(x: Int, y: Int) -> UIColor {
        let width = self.width;
        let height = self.height;
        let capacity = width * height
        let widthMultiple = 8
        let rowOffset = ((width + widthMultiple - 1) / widthMultiple) * widthMultiple // Round up to multiple of 8
        guard let data = self.data?.bindMemory(to: UInt8.self, capacity: capacity) else {
            return UIColor.white
        }
        let offset = 4 * ((y * rowOffset) + x)
        
        let red = data[offset+2]
        let green = data[offset+1]
        let blue = data[offset]
        let alpha = data[offset+3]
        
        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha)/255.0)
    }
}
