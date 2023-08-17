//
//  FTZoomManagerView.swift
//  Noteshelf
//
//  Created by Amar on 15/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTZoomManagerViewDelegate: NSObjectProtocol {
    func zoomManagerRectMoved(_ managerView:FTZoomManagerView,point:CGPoint);
    func zoomManagerRectSized(_ managerView:FTZoomManagerView);
    func zoomManagerDidFinishSizing(_ managerView:FTZoomManagerView);
    func zoomManagerDidFinishMoving(_ managerView:FTZoomManagerView);
    
    func zoomManager(_ managerView:FTZoomManagerView,didTapAt point:CGPoint);
}

private class FTClippingLayer: CALayer {
    private lazy var maskZoomAreaLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd;
        return layer;
    }();
    
    var clipRect: CGRect = CGRect.zero {
        didSet{
            let path = CGMutablePath();
            path.addRect(self.clipRect);
            path.addRect(self.bounds);
            self.maskZoomAreaLayer.path = path;
        }
    }
    
    override init(layer: Any) {
        super.init(layer: layer);
        if let _layer = layer as? FTClippingLayer {
            _layer.clipRect = self.clipRect;
        }
    }
    
    override init() {
        super.init();
        self.mask = self.maskZoomAreaLayer;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class FTClippingHolderView: UIView {
    private lazy var maskZoomAreaLayer: FTClippingLayer = FTClippingLayer();
    private lazy var marginIndicatorLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor(hexString: "8accea").cgColor;
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [3.0, 2.0]
        return shapeLayer;
    }();

    override init(frame: CGRect) {
        super.init(frame: frame);
        self.layer.addSublayer(self.maskZoomAreaLayer);

        self.layer.addSublayer(self.marginIndicatorLayer);
        self.isUserInteractionEnabled = false;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setClipRect(_ rect: CGRect,wrtView inView:UIView) {
        self.maskZoomAreaLayer.frame = self.bounds;

        let area = inView.convert(rect, to: self);
        self.maskZoomAreaLayer.clipRect = area;
    }
    
    func updateMargin(_ leftMargin: CGFloat) {
        var bounds = self.bounds;
        bounds.size.width = 1;
        bounds.origin.x = leftMargin-1;
        self.marginIndicatorLayer.frame = bounds;
        
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: 0, y: 0),
                                CGPoint(x: 0, y: bounds.height)])
        self.marginIndicatorLayer.path = path;
    }
}

class FTZoomManagerView: UIView {
    
    var targetRect: CGRect {
        get {
            return zoomAreaView?.targetRect ?? CGRect.zero;
        }
        set {
            self.setTargetRect(newValue, refresh: true);
        }
    };
    
    weak var delegate: FTZoomManagerViewDelegate?;
    var lineHeight: CGFloat = 0 {
        didSet {
            zoomAreaView?.lineHeight = self.lineHeight;
            if let _zoomAreaView = zoomAreaView {
                if (lineHeight > _zoomAreaView.targetRect.size.height) {
                    var frame = _zoomAreaView.targetRect;
                    frame.size.height = lineHeight;
                    _zoomAreaView.frame = frame;
                }else{
                    _zoomAreaView.frame = _zoomAreaView.targetRect;
                }
                _zoomAreaView.setNeedsDisplay();
            }
        }
    };
    
    var leftZoomMargin: CGFloat = 0 {
        didSet {
            self.refreshSubLayers();
        }
    }
    
    private(set) var rightZoomMargin: CGFloat = 10;
    
    private(set)var isMoving: Bool = false;
    private(set) var isSizing: Bool = false;
    
    private weak var zoomAreaView: FTZoomAreaView?;
    private weak var panGestureRecognizer: UIPanGestureRecognizer?;
    private weak var tapGestureRecognizer: UITapGestureRecognizer?;
    
    private weak var scrollView: UIScrollView?;
    private weak var clippingAndMarginView: FTClippingHolderView?;
    
    private var observer: NSKeyValueObservation?

    private lazy var marginIndicatorLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor(hexString: "8accea").cgColor;
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [3.0, 2.0]
        return shapeLayer;
    }();
    
    func setScrollView(_ inScrollView: UIScrollView) {
        self.scrollView = inScrollView;
        self.refreshSubLayers();
        
        self.observer?.invalidate();
        self.observer = nil;
        
        self.observer = inScrollView.observe(\.contentOffset) { [weak self] (scrollVIew, _) in
            self?.refreshSubLayers();
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        
        self.isExclusiveTouch = true;
        self.layer.zPosition=100;
        self.backgroundColor = UIColor.clear;
        
        self.autoresizingMask = [.flexibleWidth,.flexibleHeight];
                
        let clipView = FTClippingHolderView(frame: CGRect.zero);
        self.addSubview(clipView);
        self.clippingAndMarginView = clipView;

        let zoomArea = FTZoomAreaView(frame: CGRect.zero);
        self.addSubview(zoomArea);
        self.zoomAreaView = zoomArea;
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapGestureRecognizer(_:)));
        tapGesture.delaysTouchesEnded = false;
        tapGesture.numberOfTouchesRequired = 1;
        tapGesture.delegate = self;
        self.tapGestureRecognizer = tapGesture;
        self.addGestureRecognizer(tapGesture);
        
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanGestureRecognizer(_:)));
        panGesture.delaysTouchesEnded = false;
        panGesture.delegate = self;
        self.panGestureRecognizer = panGesture;
        self.addGestureRecognizer(panGesture);
        
        self.refreshSubLayers();
    }
        
    deinit {
        self.observer?.invalidate();
        self.observer = nil;
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTargetRect(_ rect: CGRect,refresh:Bool) {
        guard let _zoomAreaView = self.zoomAreaView else {
            return;
        }
        if(rect.origin.x.isNaN || rect.origin.y.isNaN) {
            return;
        }
        _zoomAreaView.targetRect = rect;
        if (self.lineHeight > rect.size.height) {
            var newFrame = rect;
            newFrame.size.height = self.lineHeight;
            _zoomAreaView.frame = newFrame.integral;
        }else{
            _zoomAreaView.frame = rect;
        }
        _zoomAreaView.setNeedsDisplay();
        self.refreshSubLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        self.refreshSubLayers();
    }
}

private extension FTZoomManagerView {
    
    func resetState() {
        isMoving = false;
        isSizing = false;
    }
    
    @objc func didTapGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: self);
        var newPosition  = self.targetRect;
        newPosition.origin.x = clamp(touchPoint.x-newPosition.width*0.5,0,self.bounds.width - newPosition.width);
        newPosition.origin.y = clamp(touchPoint.y-newPosition.height*0.5,0,self.bounds.height - newPosition.height);
        self.targetRect = newPosition;
        self.isMoving = true;
        self.delegate?.zoomManagerRectMoved(self, point: touchPoint);
        self.isMoving = false;
        self.delegate?.zoomManagerDidFinishMoving(self);
    }
    
    @objc func didPanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let _zoomAreaView = self.zoomAreaView else {
            return;
        }
        switch gestureRecognizer.state {
        case .began:
            self.resetState();
            let sizingTargetRect = _zoomAreaView.sizingRect;
            if sizingTargetRect.contains(gestureRecognizer.location(in: _zoomAreaView)) {
                isSizing = true
            } else if _zoomAreaView.frame.insetBy(dx: -10, dy: -10).contains(gestureRecognizer.location(in: self)) {
                isMoving = true
            }
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
            
        case .changed:
            let translate = gestureRecognizer.translation(in: self)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
            
            if isMoving {
                let newX = targetRect.origin.x + translate.x
                let newY = targetRect.origin.y + translate.y

                let newOrigin = CGPoint(x: newX, y: newY);
                self.setTargetRect(CGRect(origin: newOrigin,
                                          size: self.targetRect.size), refresh: false);
                self.delegate?.zoomManagerRectMoved(self,point: gestureRecognizer.location(in: self));
            }
            else if (isSizing) {
                var newWidth = min(self.bounds.size.width - self.targetRect.origin.x, self.targetRect.size.width + translate.x);
                
                var newHeight = min(self.bounds.size.height - self.targetRect.origin.y + lineHeight, self.targetRect.size.height + translate.y);
                
                let currentAspect = self.targetRect.size.width/self.targetRect.size.height;
                let newAspect = newWidth/newHeight;
                
                if (currentAspect > newAspect) {
                    newHeight = newWidth * self.targetRect.size.height/self.targetRect.size.width;
                }else {
                    newWidth = newHeight * self.targetRect.size.width/self.targetRect.size.height;
                }
                
                let newSize = CGSize(width: newWidth, height: newHeight);
                self.targetRect = CGRect(origin: self.targetRect.origin, size: newSize);
                self.delegate?.zoomManagerRectSized(self);
            }
        case .cancelled,.ended:
            NotificationCenter.default.post(name: Notification.Name(rawValue: FTPDFEnableGestures),
                                            object: self.window);
            if(isSizing) {
                isSizing = false;
                self.delegate?.zoomManagerDidFinishSizing(self);
            }
            if(isMoving) {
                isMoving = false;
                self.delegate?.zoomManagerDidFinishMoving(self);
            }
            self.resetState();
        default:
            break;
        }
    }
}

extension FTZoomManagerView: UIGestureRecognizerDelegate
{
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldAccept = false;
        let point = gestureRecognizer.location(in: self);
        if(gestureRecognizer == self.panGestureRecognizer) {
            guard let _zoomAreaView = self.zoomAreaView else {
                return false;
            }
            let sizingTargetRect = _zoomAreaView.sizingRect;
            let zoomAreaViewFrame = _zoomAreaView.frame.insetBy(dx: -10, dy: -10);
            
            if(sizingTargetRect.contains(point)) {
                shouldAccept = true;
            }
            else if(zoomAreaViewFrame.contains(point)) {
                shouldAccept = true;
            }
        } else if(gestureRecognizer == self.tapGestureRecognizer) {
            if !self.targetRect.contains(point) {
                shouldAccept = true;
            }
        }
        else {
            shouldAccept = true;
        }
        return shouldAccept;
    }
}

private extension FTZoomManagerView {
    func refreshSubLayers() {
        self.updateClippingViewFrame();
        self.clippingAndMarginView?.updateMargin(leftZoomMargin);
        if let zoomArea = self.zoomAreaView {
            self.clippingAndMarginView?.setClipRect(zoomArea.frame, wrtView: self);
        }
    }
    
    func updateClippingViewFrame() {
        if let _scrollView = self.scrollView {
            var rect = _scrollView.visibleRect;
            if(rect.size.height == _scrollView.contentSize.height) {
                rect.origin.y = 0;
            }
            self.clippingAndMarginView?.frame = rect;
        }
        else {
            self.clippingAndMarginView?.frame = self.bounds;
        }
    }
}
