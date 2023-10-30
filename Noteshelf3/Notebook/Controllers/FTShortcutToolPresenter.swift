//
//  FTShortcutToolPresenter.swift
//  Noteshelf3
//
//  Created by Narayana on 29/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

protocol FTShortcutContainerDelegate: AnyObject {
    func didTapPresentationOption(_ option: FTPresenterModeOption)
    func didChangeCurrentPenset(penset: FTPenSetProtocol)
    func didStartPlacementChange() 
}

private var offset: CGFloat = 8.0

@objcMembers class FTShortcutToolPresenter: NSObject {
    private(set) var toolbarOffset: CGFloat = FTToolbarConfig.Height.regular + offset;
    private(set) weak var parentVC: UIViewController?;
    private(set) var rackType: FTRackType = .pen
    var mode: FTScreenMode = .normal

    private(set) weak var toolbarVc: FTToolTypeShortcutViewController!
    private weak var pensizeEditVc: FTPenSizeEditController?

    weak var delegate: FTShortcutContainerDelegate?

    // Internal variables/functions for extension purpose, not intended for out world
    internal var isMoving: Bool = false
    internal var hasAddedSlots: Bool = false
    internal var shortcutZoomMode: FTZoomShortcutMode = .auto
    internal var animDuration: CGFloat = 0.3

    var shortcutViewPlacement: FTShortcutPlacement {
        if UIDevice.current.isIphone() {
            return .top
        }
        let placement = FTShortcutPlacement.getSavedPlacement()
        return placement
    }

    var shortcutView: UIView {
        return self.toolbarVc.view;
    }
            
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(showToast(_:)), name: NSNotification.Name.PresetColorUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitZoomModeNotified(_:)), name: NSNotification.Name(FTAppDidEXitZoomMode), object: nil)
    }

    func showToolbar(rackData: FTRackData
                     ,on viewController: UIViewController) {
        self.rackType = rackData.type
        self.parentVC = viewController
        let reqSize = self.shortcutViewSizeWrToVertcalPlacement()
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTToolTypeShortcutViewController.self))
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTToolTypeShortcutViewController") as? FTToolTypeShortcutViewController else {
            fatalError("Programmer error, couldnot find FTToolTypeShortcutViewController")
        }
        self.toolbarVc = controller
        self.toolbarVc.delegate = self
        viewController.addChild(controller)
        controller.didMove(toParent: viewController)

        self.shortcutView.frame.size = reqSize
        viewController.view.addSubview(controller.view)
        self.shortcutView.transform = .identity
        if self.shortcutViewPlacement == .top || self.shortcutViewPlacement == .bottom {
            self.shortcutView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
        self.updateMinOffsetIfNeeded()
        let reqCenter = self.shortcutViewPlacement.placementCenter(forShortcutView: shortcutView, topOffset: self.toolbarOffset, zoomModeInfo: self.zoomModeInfo)
        self.updateShortcutViewCenter(reqCenter)
        self.toolbarVc?.showShortcutViewWrto(rack: rackData)
        self.configurePanGesture()
    }

    private var contentSize = CGSize.zero
    func updatePositionOnScreenSizeChange() {
        let curSize = self.parentVC?.view.frame.size ?? .zero;
        if(!curSize.equalTo(contentSize)) {
            contentSize = curSize
            self.updateMinOffsetIfNeeded()
            self.configureShortcutView(with: mode)
            if let parent = self.parentVC as? FTPDFRenderViewController, let zoomVc = parent.zoomOverlayController {
                self.handleZoomPanelFrameChange(zoomVc.view.frame, mode: zoomVc.shortcutModeZoom, completion: nil)
            }
        }
    }

    func removeFromParent() {
        self.shortcutView.removeFromSuperview()
        self.toolbarVc.removeFromParent()
    }
    
    func bringToFront() {
        self.shortcutView.superview?.bringSubviewToFront(shortcutView)
    }

    func configureShortcutView(with mode: FTScreenMode, animate: Bool = false) {
        self.mode = mode
        let reqSize = self.shortcutViewSizeWrToVertcalPlacement()
        var reqCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)

        var options = UIView.AnimationOptions.curveEaseOut
        if mode == .focus {
            options = .curveEaseIn
        }
        UIView.animate(withDuration: animate ? animDuration : 0.0, delay: 0.0, options: options) { [weak self] in
            self?.updateShortcutViewCenter(reqCenter)
        }

        if mode == .focus {
            if self.shortcutViewPlacement.isLeftPlacement() {
                reqCenter.x -= 60.0
            } else if self.shortcutViewPlacement.isRightPlacement() {
                reqCenter.x += 60.0
            } else if self.shortcutViewPlacement == .top {
                reqCenter.y -= 200.0
            } else if self.shortcutViewPlacement == .bottom {
                reqCenter.y += 200.0
            }
            UIView.animate(withDuration: animate ? animDuration : 0.0, delay: 0.0, options: options) { [weak self] in
                self?.updateShortcutViewCenter(CGPoint(x: reqCenter.x, y: reqCenter.y))
            }
        }
    }

    @objc func handleEndDragOfZoomPanel(_ frame: CGRect, mode: FTZoomShortcutMode) {
        self.handleZoomPanelFrameChange(frame, mode: mode) {
            self.updateMinOffsetIfNeeded()
        }
    }

    @objc func exitZoomModeNotified(_ notification: Notification) {
        let reqSize = self.shortcutViewSizeWrToVertcalPlacement()
        let actualCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
        UIView.animate(withDuration: 0.2) {
            self.updateShortcutViewCenter(actualCenter)
        } completion: { _ in
            if !(self.zoomModeInfo.overlayHeight == 0 && self.shortcutZoomMode == .auto) {
                self.shortcutZoomMode = .auto
            }
        }
    }

    @objc func handleZoomPanelFrameChange(_ frame: CGRect, mode: FTZoomShortcutMode, animate: Bool = false, completion:(() -> Void)?) {
        if self.shortcutZoomMode == .manual && self.shortcutViewPlacement != .bottom {
            completion?()
            return
        }

        if animate {
            UIView.animate(withDuration: 0.2) {
                updateShortcutIfRequired()
            } completion: { _ in
                completion?()
            }
        } else {
            updateShortcutIfRequired()
            completion?()
        }

        func updateShortcutIfRequired() {
            let reqSize = self.shortcutViewSizeWrToVertcalPlacement()
            let actualCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
            self.updateShortcutViewCenter(actualCenter)
            if self.zoomModeInfo.overlayHeight == 0 {
                self.shortcutZoomMode = .auto
            }
        }
    }

    @objc private func showToast(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: String]
                ,let _parentVC = self.parentVC else {
            return
        }
        var toastMessage = "color.added".localized
        if info["type"] == FTColorToastType.delete.rawValue {
            toastMessage = "color.deleted".localized
        } else if info["type"] == FTColorToastType.edit.rawValue {
            toastMessage = "color.edited".localized
        }
        let config = FTToastConfiguration(title: toastMessage)
        FTToastHostController.showToast(from: _parentVC, toastConfig: config)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    internal func shortcutViewSizeWrToVertcalPlacement() -> CGSize {
        var size: CGSize = .zero
        if self.rackType == .pen || self.rackType == .highlighter {
            size = penShortcutSize
        } else if self.rackType == .shape {
            size = shapeShortcutSize
        } else if self.rackType == .presenter {
            size = presenterShortcutSize
        }
        return size
    }

    internal var zoomModeInfo: FTZoomModeInfo {
        var info = FTZoomModeInfo()
        if let pdfRender = self.parentVC as? FTPDFRenderViewController, pdfRender.isInZoomMode() {
            if let overlay = pdfRender.zoomOverlayController {
                info = FTZoomModeInfo(isEnabled: true, overlayHeight: overlay.view.frame.height)
            }
        }
        return info
    }
}

// Presentation of size edit screen
private extension FTShortcutToolPresenter {
    func getPenSizeEditViewCenter(at position: FavoriteSizePosition) -> CGPoint {
        let view = self.shortcutView
        var center: CGPoint = .zero

        if self.shortcutViewPlacement.isHorizantalPlacement() { // top or bottom
            center.x = view.frame.midX
            if self.shortcutViewPlacement == .top {
                center.y = view.frame.maxY + FTPenSizeEditController.viewSize.height/2.0
            } else {
                center.y = view.frame.minY - FTPenSizeEditController.viewSize.height/2.0
            }
        } else { // other placements
            let xOffset: CGFloat = 16.0
            if self.shortcutViewPlacement.isLeftPlacement() {
                center.x = view.frame.maxX + FTPenSizeEditController.viewSize.width/2.0 + xOffset
            } else if self.shortcutViewPlacement.isRightPlacement() {
                center.x = view.frame.minX - FTPenSizeEditController.viewSize.width/2.0 - xOffset
            }
            if self.rackType == .shape {
                center.y = view.center.y + 125.0
            } else {
                let step: CGFloat = 36.0
                center.y = view.center.y + step
                if position == .second {
                    center.y += step
                } else if position == .third {
                    center.y += (2 * step)
                }
            }
        }
        return center
    }
}

extension FTShortcutToolPresenter: FTShorctcutActionDelegate,FTPenSizeEditControllerDelegate {
    func didTapPresentationOption(_ option: FTPresenterModeOption) {
        self.delegate?.didTapPresentationOption(option)
    }

    func didChangeCurrentPenset(_ penset: FTPenSetProtocol) {
        let rackData = FTRackData(type: self.rackType, userActivity: self.parentVC?.view.window?.windowScene?.userActivity)
        if self.rackType == .presenter, let presenterSet = penset as? FTPresenterSetProtocol {
            rackData.currentPenset = presenterSet
            rackData.saveCurrentSelection()
            self.delegate?.didChangeCurrentPenset(penset: presenterSet)
        } else {
            rackData.currentPenset.color = penset.color
            rackData.currentPenset.size = penset.size
            rackData.currentPenset.preciseSize = penset.preciseSize
            rackData.saveCurrentSelection()
            self.delegate?.didChangeCurrentPenset(penset: rackData.currentPenset)
        }
    }
    
    func showSizeEditView(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel) {
        self.removeSizeEditViewController()
        let controller = FTPenSizeEditController(viewModel: viewModel, editPosition: position)
        controller.delegate = self;
        self.pensizeEditVc = controller
        self.parentVC?.addChild(controller)
        controller.view.backgroundColor = .clear
        controller.view.frame.size = FTPenSizeEditController.viewSize
        controller.view.center = self.getPenSizeEditViewCenter(at: position)
        self.parentVC?.view.addSubview(controller.view)
        controller.didMove(toParent: self.parentVC)
    }

    func removeSizeEditViewController() {
        if let sizeEditVc = self.pensizeEditVc {
            sizeEditVc.willMove(toParent: nil)
            sizeEditVc.removeFromParent()
            sizeEditVc.view.removeFromSuperview()
        }
    }
}

extension FTShortcutToolPresenter {
    internal func updateShortcutViewCenter(_ center: CGPoint) {
        self.shortcutView.center = center
    }

    func updateMinOffsetIfNeeded() {
        guard let frame = self.parentVC?.view.frame else {
            return
        }
#if targetEnvironment(macCatalyst)
        self.toolbarOffset = offset
#else
        if UIDevice().isIphone() || frame.width < FTToolbarConfig.compactModeThreshold {
            var extraOffset: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = self.parentVC?.fetchCurrentWindow() {
                    let topSafeAreaInset = window.safeAreaInsets.top
                    if topSafeAreaInset > 0 {
                        extraOffset = topSafeAreaInset
                    }
                }
            }
            self.toolbarOffset = FTToolbarConfig.Height.compact + offset + extraOffset
        } else {
            self.toolbarOffset = FTToolbarConfig.Height.regular + offset
        }
#endif
    }

    func shortcutViewCenter(for placement: FTShortcutPlacement, size: CGSize) -> CGPoint {
        return placement.placementCenter(forShortcutView: shortcutView, topOffset: toolbarOffset, zoomModeInfo: self.zoomModeInfo)
    }
}
