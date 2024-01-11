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

private let offset: CGFloat = 8.0
@objcMembers class FTShortcutToolPresenter: NSObject {
    private var contentSize = CGSize.zero
    private weak var pensizeEditVc: FTPenSizeEditController?

    var toolbarVc: UIViewController!
    var screenMode: FTScreenMode = .normal
    var deskMode: RKDeskMode = .deskModePen

    weak var parentVC: UIViewController?
    weak var delegate: FTShortcutContainerDelegate?

    // Internal variables/functions for extension purpose, not intended for out world
    internal var isMoving: Bool = false
    internal var hasAddedSlots: Bool = false
    internal var animDuration: CGFloat = 0.3
    internal var shortcutZoomMode: FTZoomShortcutMode = .auto
    internal var toolbarOffset: CGFloat = FTToolbarConfig.Height.regular + offset

    var shortcutView: UIView {
        return self.toolbarVc.view
    }

    var rackType: FTRackType {
        self.deskMode.rackType
    }

    var shortcutViewPlacement: FTShortcutPlacement {
        let placement = FTShortcutPlacement.getSavedPlacement()
        return placement
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(showToast(_:)), name: NSNotification.Name.PresetColorUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitZoomModeNotified(_:)), name: NSNotification.Name(FTAppDidEXitZoomMode), object: nil)
    }

    func showToolbar(on viewController: UIViewController, for mode: RKDeskMode) {
        if !mode.canProceedToShowToolbar {
            return
        }
        self.deskMode = mode
        self.parentVC = viewController

        if mode != .deskModeFavorites {
            self.toolbarVc = FTToolTypeShortcutViewController()
        } else {
            self.toolbarVc = FTFavoriteShortcutViewController()
        }

        let reqSize = self.shortcutViewHorizantalSize()
        viewController.add(toolbarVc)
        self.shortcutView.frame.size = reqSize

        self.shortcutView.transform = .identity
        if !self.shortcutViewPlacement.isHorizantalPlacement() {
            self.shortcutView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        }
        self.updateMinOffsetIfNeeded()
        let reqCenter = self.shortcutViewCenter(for: shortcutViewPlacement)
        self.updateShortcutViewCenter(reqCenter)
        let userActivity = viewController.view.window?.windowScene?.userActivity
        if mode != .deskModeFavorites {
            let rackData = FTRackData(type: rackType, userActivity: userActivity)
            (toolbarVc as? FTToolTypeShortcutViewController)?.showShortcutViewWrto(rack: rackData)
            (toolbarVc as? FTToolTypeShortcutViewController)?.delegate = self
        } else {
            (toolbarVc as? FTFavoriteShortcutViewController)?.addFavoritesView(userActivity: userActivity)
        }
        self.configurePanGesture()
    }

    func updatePositionOnScreenSizeChange() {
        let curSize = self.parentVC?.view.frame.size ?? .zero;
        if(!curSize.equalTo(contentSize)) {
            contentSize = curSize
            self.updateMinOffsetIfNeeded()
            self.configureShortcutView(with: screenMode)
            if let parent = self.parentVC as? FTPDFRenderViewController, let zoomVc = parent.zoomOverlayController {
                self.handleZoomPanelFrameChange(zoomVc.view.frame, mode: zoomVc.shortcutModeZoom, completion: nil)
            }
        }
    }

    internal func updateShortcutViewCenter(_ center: CGPoint) {
        self.shortcutView.center = center
    }

    func removeFromParent() {
        self.shortcutView.removeFromSuperview()
        self.toolbarVc.removeFromParent()
    }
    
    func bringToFront() {
        self.shortcutView.superview?.bringSubviewToFront(shortcutView)
    }

    func configureShortcutView(with mode: FTScreenMode, animate: Bool = false) {
        self.screenMode = mode
        var reqCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement)

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
        let actualCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement)
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
            let actualCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement)
            self.updateShortcutViewCenter(actualCenter)
            if self.zoomModeInfo.overlayHeight == 0 {
                self.shortcutZoomMode = .auto
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
    @objc func showToast(_ notification: Notification) {
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

    func shortcutViewHorizantalSize() -> CGSize {
        var size: CGSize = .zero

        if self.deskMode == .deskModePen || self.deskMode == .deskModeMarker {
            size = penShortcutSize
        } else if self.deskMode == .deskModeShape {
            size = shapeShortcutSize
        } else if self.deskMode == .deskModeLaser {
            size = presenterShortcutSize
        } else if self.deskMode == .deskModeFavorites {
            size = favoriteShortcutSize
        }
        return size
    }

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

    func updateMinOffsetIfNeeded() {
        guard let frame = self.parentVC?.view.frame else {
            return
        }
#if targetEnvironment(macCatalyst)
        self.toolbarOffset = offset
#else
        if UIDevice.current.isIphone() || frame.width < FTToolbarConfig.compactModeThreshold {
            self.toolbarOffset = FTToolbarConfig.Height.compact + offset
        } else {
            self.toolbarOffset = FTToolbarConfig.Height.regular + offset
        }
#endif
    }

    func shortcutViewCenter(for placement: FTShortcutPlacement) -> CGPoint {
        return placement.placementCenter(forShortcutView: shortcutView, topOffset: toolbarOffset, zoomModeInfo: self.zoomModeInfo)
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

private extension RKDeskMode {
    var canProceedToShowToolbar: Bool {
        var status = false
        if self == .deskModePen || self == .deskModeMarker || self == .deskModeShape || self == .deskModeLaser || self == .deskModeFavorites {
            status = true
        }
        return status
    }

    var rackType: FTRackType {
        var type = FTRackType.pen
        switch self {
        case .deskModePen:
            type = .pen
        case .deskModeMarker:
            type = .highlighter
        case .deskModeLaser:
            type = .presenter
        case .deskModeShape:
            type = .shape
        default:
            break
        }
        return type
    }
}
