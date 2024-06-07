//
//  FTPDFRenderViewController+PencilPro.swift
//  Noteshelf3
//
//  Created by Narayana on 31/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let stylusTouchesBegan = Notification.Name(rawValue: "stylusTouchesBegan")
}

extension FTPDFRenderViewController {
    @objc func configurePencilProInteractionIfAvailable() {
        if #available(iOS 17.5, *) {
            let pencilInteraction = UIPencilInteraction(delegate: self)
            self.view.addInteraction(pencilInteraction)
        }
    }
    
    @objc func showPencilProMenuIfNeeded(using anchorPoint: CGPoint) {
        let isPencilProMenuExist = self.children.contains { child in
            return child is FTPencilProMenuController
        }
        var convertedAnchorPoint = anchorPoint
        if !isPencilProMenuExist {
            if let proMenu = UIStoryboard(name: "FTDocumentView", bundle: nil).instantiateViewController(withIdentifier: "FTPencilProMenuController") as? FTPencilProMenuController {
                convertedAnchorPoint = self.getSuitableAnchorPointForPrimaryMenu(with: anchorPoint)
                if let toolbar = self.parent as? FTToolbarElements,  !toolbar.isInFocusMode() {
                    NotificationCenter.default.post(name: NSNotification.Name(FTToggleToolbarModeNotificationName), object: nil)
                }
                self.add(proMenu, frame: CGRect(origin: convertedAnchorPoint, size: FTPenSliderConstants.primaryMenuSize))
                proMenu.delegate = self
                NotificationCenter.default.addObserver(self, selector: #selector(stylusTouchesBegan(_:)), name: .stylusTouchesBegan, object: nil)
            }
        } else {
            self.removePrimaryMenuIfExist()
        }
        showSecondaryMenuIfneeded(with: convertedAnchorPoint, mode: self.currentDeskMode)
    }
    
    func showSecondaryMenuIfneeded(with anchorPoint: CGPoint, mode: RKDeskMode) {
        let isSecondaryMenuExist = self.children.contains { child in
            return child is FTSliderHostingControllerProtocol
        }
        if !isSecondaryMenuExist && shouldShowSecondaryMenu(for: mode){
            let rect = CGRect(origin: anchorPoint, size: FTPenSliderConstants.secondaryMenuSize)
            self.addSecondaryMenu(with: mode, rect: rect)
        } else {
            self.removeSecondaryMenuIfExist()
        }
    }
    
    @objc private func stylusTouchesBegan(_ notification: Notification) {
        self.removePencilProMenuIfExist()
    }
    
    func getSuitableAnchorPointForPrimaryMenu(with anchorPoint: CGPoint) -> CGPoint {
        let offset: CGFloat = 125
        var point = anchorPoint
        if anchorPoint.x < offset {
            point.x = offset
        }
        if anchorPoint.y < offset {
            point.y = offset
        }
        if anchorPoint.x > self.view.frame.maxX - offset - 50 {
            point.x = self.view.frame.maxX - offset - 50
        }
        if anchorPoint.y > self.view.frame.maxY - offset - 50 {
            point.y = self.view.frame.maxY - offset - 50
        }
        point.x -= 150
        point.y -= 150
        return point
    }
    
    @objc func addSecondaryMenu(with mode: RKDeskMode, rect: CGRect) {
        var rackType = FTRackType.pen
        if mode == .deskModeMarker {
            rackType = .highlighter
        } else if mode == .deskModeShape {
            rackType = .shape
        } else if mode == .deskModeLaser {
            rackType = .presenter
        }
        let activity = self.view.window?.windowScene?.userActivity
        let rack = FTRackData(type: rackType, userActivity: activity)
        let _colorModel =
        FTFavoriteColorViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
        _colorModel.colorSourceOrigin = rect.origin
        let sizeModel =
        FTFavoriteSizeViewModel(rackData: rack, delegate: self, scene: self.view?.window?.windowScene)
        let transparentTouchView = TransparentTouchView(frame: rect)
        transparentTouchView.backgroundColor = .clear
        self.view.addSubview(transparentTouchView)
        var items = FTPenSliderConstants.penShortCutItems
        if rack.type == .pen || rack.type == .highlighter {
            let shortcutView = FTPenSliderShortcutView(colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTPenSliderShortcutHostingController(rootView: shortcutView)
            self.penSliderViewcontroller = hostingVc
            self.add(hostingVc, frame: transparentTouchView.bounds)
            transparentTouchView.addSubview(hostingVc.view)
        } else if rack.type == .shape {
            let _shapeModel = FTFavoriteShapeViewModel(rackData: rack, delegate: self)
            let shortcutView = FTShapeCurvedShortcutView(shapeModel: _shapeModel, colorModel: _colorModel, sizeModel: sizeModel)
            let hostingVc = FTShapeCurvedShortcutHostingController(rootView: shortcutView)
            self.penSliderViewcontroller = hostingVc
            self.add(hostingVc, frame: transparentTouchView.bounds)
            transparentTouchView.addSubview(hostingVc.view)
            items = FTPenSliderConstants.shapeShortcutItems
        } else if rack.type == .presenter {
            let shortcutView = FTPresenterSliderShortcutView(viewModel: FTPresenterShortcutViewModel(rackData: rack, delegate: self))
            let hostingVc = FTPresenterSliderShortcutHostingController(rootView: shortcutView)
            self.penSliderViewcontroller = hostingVc
            self.add(hostingVc, frame: transparentTouchView.bounds)
            transparentTouchView.addSubview(hostingVc.view)
            items = FTPenSliderConstants.presenterShortcutItems
        }
        self.colorModel = _colorModel
        self.drawCurvedBackground(transparentView: transparentTouchView, items: items)
    }
    
    func shouldShowSecondaryMenu(for mode: RKDeskMode) -> Bool {
        if mode == .deskModePen || mode == .deskModeMarker || mode == .deskModeShape || mode == .deskModeLaser {
            return true
        }
        return false
    }
    
    func getEndAngle(with startAngle: CGFloat, with items: Int) -> CGFloat {
        let endAngle = 2 * .pi - (startAngle + (CGFloat(items - 1) * FTPenSliderConstants.spacingAngle.degreesToRadians) + 3.degreesToRadians)
        return endAngle
    }

    func drawCurvedBackground(transparentView: TransparentTouchView, items: Int) {
        let menuLayer = FTPencilProMenuLayer(strokeColor: UIColor.init(hexString: "#F2F2F2"))
        let startAngle: CGFloat =  .pi + .pi/12
        let endAngle = self.getEndAngle(with: startAngle, with: items)
        let rect = transparentView.bounds
        let center = CGPoint(x: rect.midX, y: rect.midY)
        menuLayer.setPath(with: center, radius: FTPenSliderConstants.sliderRadius, startAngle: startAngle, endAngle: -endAngle)
        let borderLayer = FTPencilProBorderLayer(strokeColor: UIColor.init(hexString: "#E5E5E5"))
        borderLayer.setPath(with: center, radius: FTPenSliderConstants.sliderRadius, startAngle: startAngle, endAngle: -endAngle)

        let hitTestLayer = FTPencilProMenuLayer(strokeColor: .clear, lineWidth: 50)
        hitTestLayer.setPath(with: center, radius: FTPenSliderConstants.sliderRadius, startAngle: startAngle, endAngle: -endAngle)
        transparentView.layer.insertSublayer(hitTestLayer, at: 0)
        transparentView.layer.insertSublayer(borderLayer, at: 1)
        transparentView.layer.insertSublayer(menuLayer, at: 2)
        transparentView.hitTestLayer = hitTestLayer
    }

    @objc func removePencilProMenuIfExist() {
        NotificationCenter.default.removeObserver(self, name: .stylusTouchesBegan, object: nil)
        self.removePrimaryMenuIfExist()
        self.removeSecondaryMenuIfExist()
    }
    
    @objc func removePrimaryMenuIfExist() {
        self.children.compactMap { $0 as? FTPencilProMenuController }.forEach { $0.remove() }
        self.view.subviews.forEach { subView in
            if (subView is FTPencilProUndoButton || subView is FTPencilProRedoButton) {
                subView.removeFromSuperview()
            }
        }
    }
    
    @objc func removeSecondaryMenuIfExist() {
        self.children.compactMap { $0 as? FTSliderHostingControllerProtocol}.forEach { $0.removeHost() }
        self.view.subviews.compactMap { $0 as? TransparentTouchView }.forEach { $0.removeFromSuperview() }
    }
}

@available(iOS 17.5, *)
extension FTPDFRenderViewController: UIPencilInteractionDelegate {
    public func pencilInteraction(_ interaction: UIPencilInteraction,
                           didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        let preferredAction = UIPencilInteraction.preferredSqueezeAction
        guard preferredAction != .ignore else { return }
        if squeeze.phase == .ended {
            if let anchorPoint = squeeze.hoverPose?.location {
                self.showPencilProMenuIfNeeded(using: anchorPoint)
            }
        }
    }
}

extension FTPDFRenderViewController: FTPencilProMenuDelegate {
    func canPerformUndo() -> Bool {
        return self.canUndo()
    }
    
    func performUndo() {
        self.undoButtonAction()
    }
    
    func canPerformRedo() -> Bool {
        return self.canRedo()
    }
    
    func performRedo() {
        self.redoButtonAction()
    }
}
