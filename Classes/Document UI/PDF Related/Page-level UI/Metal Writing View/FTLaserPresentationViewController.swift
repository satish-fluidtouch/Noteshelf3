//
//  FTLaserPresentationViewController.swift
//  Noteshelf
//
//  Created by Amar on 16/04/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

private extension Notification.Name {
    static let cancelCurrentLaserStroke = Notification.Name(rawValue:"didCancelCurrentLaserStroke");
}
protocol FTLaserPresentationDelegate: NSObjectProtocol {
    var visibleRect: CGRect {get};
    var scale: CGFloat {get};
    var page: FTPageProtocol? {get};
    var contentSize: CGSize {get};
    func lasserAnnotations() -> [FTAnnotation];
    func addLaserAnnotation(_ annotation: FTAnnotation);
}

@objcMembers class FTLaserPresentationViewController: UIViewController {

    private var currentStroke : FTLaserStroke?;
    private var displayLink: CADisplayLink?;
    private var currentExecutingID : String?;

    var isWhiteboardMode = false;
    var previousRenderedRect: CGRect = .null;
    
    weak var delegate: FTLaserPresentationDelegate?;
    var enableAutoDisplay = false {
        didSet {
            if self.enableAutoDisplay {
                self.displayLink = CADisplayLink.init(target: self, selector: #selector(self.renderMetalView(_:)));
                self.displayLink?.isPaused = true;
                self.displayLink?.preferredFramesPerSecond = 60;
                self.displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.default);
            }
            else {
                self.displayLink?.invalidate();
                self.displayLink = nil;
            }
        }
    }
    
    deinit {
        self.displayLink?.invalidate();
        self.displayLink = nil;
    }
    
    private var scale: CGFloat {
        return self.delegate?.scale ?? 1;
    }
    
    override func loadView() {
        let view = FTMetalView(frame: UIScreen.main.bounds);
        view.isUserInteractionEnabled = false;
        view.layer.isOpaque = false;
        #if DEBUG
//        view.layer.backgroundColor = UIColor.red.withAlphaComponent(0.4).cgColor;
        view.layer.backgroundColor = UIColor.clear.cgColor;
        #else
        view.layer.backgroundColor = UIColor.clear.cgColor;
        #endif
        self.view = view;
    }
    
    private var _presentationRender: FTOnScreenRenderer?;
    private var presentationRender: FTOnScreenRenderer? {
        if nil == self._presentationRender {
            let screen = self.view.window?.screen;
            self._presentationRender = FTRendererFactory.createPresenterRender(screen: screen);
        }
        (self.view as? FTMetalView)?.viewFrame = self.visibleRect;
        _presentationRender?.bind(view:self.view as! FTMetalView)
        return self._presentationRender;
    }
    
    var visibleRect: CGRect {
        return self.delegate?.visibleRect ?? self.view.frame;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.addObservers();
    }
    
    func cancelCurrentStroke() {
        self._cancelCurrentStroke()
        var userInfo = [String:Any]();
        if let window = self.view.window {
            userInfo[FTRefreshWindowKey] = window;
        }
        NotificationCenter.default.post(name: .cancelCurrentLaserStroke,
                                        object: self.delegate?.page,
                                        userInfo: userInfo);
    }
    
    private func _cancelCurrentStroke() {
        if let currentStroke = self.currentStroke {
            currentStroke.didCancelCurrentStroke();
            self.currentStroke = nil;
        }
        self.displayLink?.isPaused = true;
    }
        
    func reloadTiles(in rect:CGRect,properties: FTRenderingProperties) {
        guard self.previousRenderedRect != rect || properties.forcibly else {
            return;
        }
        self.previousRenderedRect = rect;
//        self.view.isHidden = true;
        let renderRequest = FTOnScreenRenderRequest(with: self.view.window?.hash);
        renderRequest.annotations = self.delegate?.lasserAnnotations() ?? [FTAnnotation]();
        renderRequest.areaToRefresh = rect;
        renderRequest.contentSize = self.delegate?.contentSize ?? self.view.frame.size;
        renderRequest.visibleArea = self.visibleRect;
        renderRequest.scale = self.scale;
        renderRequest.renderingProperties.synchronously = properties.synchronously;
        
        let execID = self.presentationRender?.render(request: renderRequest)
        self.currentExecutingID = execID;
        renderRequest.completionBlock = { [weak self] (success) in
            runInMainThread {
                if success,
                   self?.currentExecutingID == execID {
//                    self?.view.isHidden = false;
                    self?.currentExecutingID = nil;
                }
            }
        }
        
    }
    
    func publishChanges() {
        self.renderMetalView(self.displayLink);
    }
    
    func processs(_ point: CGPoint,
                  vertexType: FTVertexType,
                  pressure: CGFloat = -1,
                  penSet inset: FTPenSetProtocol?) {
        switch vertexType {
        case .FirstVertex:
            if self.presentationRender != nil {
                self.displayLink?.isPaused = false
                let penSet: FTPenSetProtocol = inset ?? self.currentSelectedPenSet()
                let laserColor =  penSet.color
                let stroke = FTStroke();
                stroke.strokeWidth = FTLaserPenThickness.primary.rawValue;
                stroke.strokeColor = UIColor(hexString: laserColor);
                stroke.penType = penSet.type.penType();

                let properties = FTBrushBuilder.penAttributesFor(penType: penSet.type,
                                                                 brushWidth: stroke.strokeWidth,
                                                                 isShapeTool: false,
                                                                 version: FTStroke.defaultAnnotationVersion());
                let strokeAttributes = properties.asStrokeAttributes()
                
                let lasterStroke =  FTLaserStroke(withScale: self.scale,
                                                  stroke: stroke,
                                                  attributes:strokeAttributes,
                                                  renderDelegate: self)
                lasterStroke.laserStrokeType = penSet.type == .laser ? .stroke : .pointerOnly
                self.currentStroke = lasterStroke
            }

            self.currentStroke?.processPoint(point, vertexType: vertexType, pressure: pressure);
        case .InterimVertex:
            self.currentStroke?.processPoint(point, vertexType: vertexType, pressure: pressure);
        case .LastVertex:
            self.currentStroke?.processPoint(point, vertexType: vertexType, pressure: pressure);
            self.displayLink?.isPaused = true;
            guard let curStroke = self.currentStroke?.stroke as? FTStroke else { return }
            if curStroke.penType == .laser {
                self.delegate?.addLaserAnnotation(curStroke);
            }
            self.currentStroke = nil;
        }
    }

    func processs(_ touch: FTTouch, vertexType: FTVertexType) {
        let notification: Notification.Name;
        let point = touch.activeUItouch.location(in: self.view.superview);
        let point1x = CGPoint.scale(point, 1/self.scale);
        var userInfo: [String:Any] = ["touch" : point1x];
        if let window = self.view.window {
            userInfo[FTRefreshWindowKey] = window;
        }
        let penSet = self.currentSelectedPenSet();
        userInfo["penSet"] = penSet;
        self.processs(point,
                      vertexType: vertexType,
                      pressure: touch.pressure,
                      penSet: penSet);
        switch vertexType {
        case .FirstVertex:
            notification = .didBeginStroke;
        case .InterimVertex:
            notification = .didMoveStroke
        case .LastVertex:
            notification = .didEndStroke
        }
        NotificationCenter.default.post(name: notification, object: nil, userInfo: userInfo);
    }
}

private extension FTLaserPresentationViewController
{
    @objc func renderMetalView(_ displayLink : CADisplayLink?) {
        if let currentRenderStroke = self.currentStroke {
            currentRenderStroke.encode(clipRect: CGRect.scale(currentRenderStroke.stroke.boundingRect, self.scale));
        }
        self.presentationRender?.publishChanges(mode: .laser, onCompletion: nil)
    }
    
    func currentSelectedPenSet() -> FTPenSetProtocol
    {
        var userActivity : NSUserActivity?;
        if #available(iOS 13.0, *) {
            userActivity = self.view.window?.windowScene?.userActivity
        }
        return FTRackData(type: FTRackType.presenter, userActivity: userActivity).getCurrentPenSet()
    }
}

extension FTLaserPresentationViewController: FTRendererDelegate {
    func renderer(inRect rect : CGRect) -> [FTOnScreenRenderer] {
        if let renderer = self.presentationRender {
            return [renderer]
        }
        return []
    }
}

private extension FTLaserPresentationViewController {
    
    func addObservers() {
        self.registerUndoObserver();
        self.registerClearAnnotationObserver();
        self.registerResetAnnotationObserver();
        self.registerrForCurrentStrokeCancellation();
    }
    
    func registerrForCurrentStrokeCancellation() {
        NotificationCenter.default.addObserver(forName: .cancelCurrentLaserStroke,
                                               object: nil,
                                               queue: nil) {[weak self]  (notification) in
            guard let strongSelf = self,
                  let userInfo = notification.userInfo,
                  let window = userInfo[FTRefreshWindowKey] as? UIWindow,
                  let page = notification.object as? FTPageProtocol,
                  self?.delegate?.page?.uuid == page.uuid else {
                return;
            }
            
            var shouldRefresh = false;
            if window == strongSelf.view.window {
                shouldRefresh = true;
            }
            else if strongSelf.isWhiteboardMode, FTWhiteboardDisplayManager.shared.isKeyWindow(window) {
                shouldRefresh = true;
            }
            if shouldRefresh {
                strongSelf._cancelCurrentStroke()
            }
        }
    }
    
    func registerResetAnnotationObserver() {
        NotificationCenter.default.addObserver(forName: .didResetLaserAnnotations,
                                               object: nil,
                                               queue: nil) {[weak self]  (notification) in
            guard let strongSelf = self,
                  let userInfo = notification.userInfo,
                  let window = userInfo[FTRefreshWindowKey] as? UIWindow else {
                return;
            }
            
            var shouldRefresh = false;
            if window == strongSelf.view.window {
                shouldRefresh = true;
            }
            else if strongSelf.isWhiteboardMode, FTWhiteboardDisplayManager.shared.isKeyWindow(window) {
                shouldRefresh = true;
            }
            if shouldRefresh {
                let properties = FTRenderingProperties();
                properties.forcibly = true;
                self?.reloadTiles(in: strongSelf.visibleRect, properties: properties);
            }
        }
    }

    func registerClearAnnotationObserver() {
        NotificationCenter.default.addObserver(forName: .didClearLaserAnnotations,
                                               object: nil,
                                               queue: nil) {[weak self]  (notification) in
            guard let strongSelf = self,
                  let userInfo = notification.userInfo,
                  let window = userInfo[FTRefreshWindowKey] as? UIWindow,
                  let page = notification.object as? FTPageProtocol,
                  self?.delegate?.page?.uuid == page.uuid else {
                return;
            }
            
            var shouldRefresh = false;
            if window == strongSelf.view.window {
                shouldRefresh = true;
            }
            else if strongSelf.isWhiteboardMode, FTWhiteboardDisplayManager.shared.isKeyWindow(window) {
                shouldRefresh = true;
            }
            if shouldRefresh {
                let properties = FTRenderingProperties();
                properties.forcibly = true;
                self?.reloadTiles(in: strongSelf.visibleRect, properties: properties);
            }
        }
    }
    
    func registerUndoObserver() {
        NotificationCenter.default.addObserver(forName: .refreshPresentation, object: nil, queue: nil) { [weak self ](notification) in
            guard let userInfo = notification.userInfo,
                  let strongSelf = self,
                  let window = userInfo[FTRefreshWindowKey] as? UIWindow,
                  let pageID = userInfo[FTRefreshPageIDKey] as? String,
                  self?.delegate?.page?.uuid == pageID else {
                return;
            };
            
            var shouldRefresh = false;
            if window == strongSelf.view.window {
                shouldRefresh = true;
            }
            else if strongSelf.isWhiteboardMode, FTWhiteboardDisplayManager.shared.isKeyWindow(window) {
                shouldRefresh = true;
            }
            if shouldRefresh {
                var rect = CGRect.null;
                if let refreshRect = notification.userInfo?[FTRefreshRectKey] as? CGRect {
                    rect = CGRect.scale(refreshRect,strongSelf.scale);
                }
                else {
                    rect = strongSelf.visibleRect;
                }
                let properties = FTRenderingProperties();
                properties.forcibly = true;
                strongSelf.reloadTiles(in: rect, properties: properties);
            }
        }
    }
}
