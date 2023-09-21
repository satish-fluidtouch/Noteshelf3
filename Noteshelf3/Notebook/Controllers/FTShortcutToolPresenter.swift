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

private var offset: CGFloat = 8.0;

@objcMembers class FTShortcutToolPresenter: NSObject {
    private(set) var toolbarOffset: CGFloat = FTToolbarConfig.Height.regular + offset;
    private(set) weak var parentVC: UIViewController?;
    private(set) var rackType: FTRackType = .pen
    var mode: FTScreenMode = .normal

    private(set) weak var toolbarVc: FTToolTypeShortcutViewController?
    private weak var pensizeEditVc: FTPenSizeEditController?

    weak var delegate: FTShortcutContainerDelegate?

    // Internal variables/functions for extension purpose, not intended for out world
    internal var isMoving: Bool = false
    internal var quadrantDetector: FTQuadrantDetector!
    internal var shortCutQuadrant: FTShortcutQuadrant = .topLeft
    var shortcutViewPlacement: FTShortcutPlacement {
        let placement = FTShortcutPlacement.getSavedPlacement()
        return placement
    }

    var shortcutView: UIView? {
        return self.toolbarVc?.view;
    }
            
    override init() {
        super.init();
        NotificationCenter.default.addObserver(self, selector: #selector(showToast(_:)), name: NSNotification.Name.PresetColorUpdate, object: nil)
    }

    func showToolbar(rackData: FTRackData
                     ,on viewController: UIViewController) {
        self.rackType = rackData.type;
        self.parentVC = viewController;
        let reqSize = self.getShortcutViewSize()
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTToolTypeShortcutViewController.self));
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTToolTypeShortcutViewController") as? FTToolTypeShortcutViewController else {
            fatalError("check");
        }
        self.toolbarVc = controller;
        self.toolbarVc?.delegate = self;
        viewController.addChild(controller);
        controller.didMove(toParent: viewController);
        
        self.shortcutView?.frame.size = reqSize
        viewController.view.addSubview(controller.view);
        let reqCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
        self.updateShortcutViewCenter(reqCenter)
        self.toolbarVc?.showShortcutViewWrto(rack: rackData)
        self.configurePanGesture()
    }

    private var contentSize = CGSize.zero
    func updatePositionOnScreenSizeChange() {
        let curSize = self.parentVC?.view.frame.size ?? .zero;
        if(!curSize.equalTo(contentSize)) {
            contentSize = curSize;
            self.prepareQuadrants()
            self.updateMinOffsetIfNeeded()
            self.configureShortcutView(with: mode)
            if let parent = self.parentVC as? FTPDFRenderViewController, let zoomVc = parent.zoomOverlayController {
                self.handleZoomPanelFrameChange(zoomVc.view.frame, mode: zoomVc.shortcutModeZoom, completion: nil)
            }
        }
    }

    func removeFromParent() {
        self.shortcutView?.removeFromSuperview();
        self.toolbarVc?.removeFromParent();
    }
    
    func bringToFront() {
        if let shortcutView = self.shortcutView {
            shortcutView.superview?.bringSubviewToFront(shortcutView);
        }
    }

    func configureShortcutView(with mode: FTScreenMode, animate: Bool = false) {
        self.mode = mode
        let reqSize = self.getShortcutViewSize()
        var reqCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)

        var options = UIView.AnimationOptions.curveEaseOut
        if mode == .focus {
            options = .curveEaseIn
        }
        UIView.animate(withDuration: animate ? 0.3 : 0.0, delay: 0.0, options: options) { [weak self] in
            self?.updateShortcutViewCenter(reqCenter)
        }

        if mode == .focus {
            if self.shortcutViewPlacement.isLeftPlacement() {
                reqCenter.x -= 60.0
            } else {
                reqCenter.x += 60.0
            }
            UIView.animate(withDuration: animate ? 0.3 : 0.0, delay: 0.0, options: options) { [weak self] in
                self?.updateShortcutViewCenter(CGPoint(x: reqCenter.x, y: reqCenter.y))
            }
        }
    }

    @objc func handleEndDragOfZoomPanel(_ frame: CGRect, mode: FTZoomShortcutMode) {
        self.handleZoomPanelFrameChange(frame, mode: mode) {
            let center = self.shortcutView?.center ?? .zero
            //TODO: prepareQuadrants() - will be done in isViewAppearing(after ios17 release), so that below condition can be removed. Right now before quadrants are ready, this method is getting called, so added.
            if nil == self.quadrantDetector {
                self.prepareQuadrants()
            }
            self.updateQuadrant(quadrant: self.quadrantDetector.getQuadrant(for: center))
            if let shortcutView = self.shortcutView {
                let placement = self.shortCutQuadrant.nearestPlacement(for: shortcutView, topOffset: self.toolbarOffset);
                placement.save()
            }
        }
    }

    @objc func handleZoomPanelFrameChange(_ frame: CGRect, mode: FTZoomShortcutMode, animate: Bool = false, completion:(() -> Void)?) {
        if mode == .manual {
            completion?()
            return
        }
        let shortCutYpos = self.shortcutView?.frame.origin.y ?? 0

        if animate {
            UIView.animate(withDuration: 0.1) {
                updateShortcutIfRequired()
            } completion: { _ in
                completion?()
            }
        } else {
            updateShortcutIfRequired()
            completion?()
        }

        func updateShortcutIfRequired() {
            guard let shortcutView = self.shortcutView else {
                return;
            }
            let minYOffset = self.toolbarOffset
            if shortCutYpos >= minYOffset {
                if shortcutView.frame.maxY > frame.origin.y {
                    let offSetToMove = shortcutView.frame.maxY - frame.origin.y
                    let reqPos = shortCutYpos - offSetToMove
                    if reqPos > minYOffset {
                        shortcutView.frame.origin.y = reqPos
                    } else {
                        shortcutView.frame.origin.y = minYOffset
                    }
                } else {
                    let offSetToMove = frame.origin.y - shortcutView.frame.maxY
                    let reqPos = shortCutYpos + offSetToMove
                    let reqSize = self.getShortcutViewSize()
                    let actualCenter = self.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
                    let actualYPos = actualCenter.y - shortcutView.frame.height/2.0
                    if reqPos < actualYPos {
                        shortcutView.frame.origin.y = reqPos
                    } else {
                        self.updateShortcutViewCenter(actualCenter)
                    }
                }
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

    internal func getShortcutViewSize() -> CGSize {
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
}

// Presentation of size edit screen
private extension FTShortcutToolPresenter {
    func getPenSizeEditViewCenter(at position: FavoriteSizePosition) -> CGPoint {
        guard let view = self.shortcutView else {
            return .zero;
        }
        var center: CGPoint = .zero
        let xOffset: CGFloat = 16.0

        if self.rackType == .shape {
            let yOffset: CGFloat = 75.0 // for shape we have single size only
            if self.shortcutViewPlacement.isLeftPlacement() {
                center.x = view.frame.maxX + xOffset
            } else {
                center.x = view.frame.minX - FTPenSizeEditController.viewSize.width - xOffset
            }
            center.y = view.center.y + yOffset
        } else {
            let step: CGFloat = 36.0
            if self.shortcutViewPlacement.isLeftPlacement() {
                center.x = view.frame.maxX + xOffset
            } else {
                center.x = view.frame.minX - FTPenSizeEditController.viewSize.width - xOffset
            }
            center.y = view.center.y - 15.0
            if position == .second {
                center.y += step
            } else if position == .third {
                center.y += (2 * step)
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
        controller.view.center = self.getPenSizeEditViewCenter(at: position)
        controller.view.frame.size = FTPenSizeEditController.viewSize
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

// MARK: - Helper methods
extension FTShortcutToolPresenter {
    private func prepareQuadrants() {
        guard let parentView = self.parentVC?.view else {
            return;
        }
        self.quadrantDetector = FTQuadrantDetector(view: parentView, centerQuadrantInSet: 0.33)
    }
    
    internal func updateQuadrant(quadrant: FTShortcutQuadrant) {
        self.shortCutQuadrant = quadrant
    }
    
    internal func updateShortcutViewCenter(_ center: CGPoint) {
        self.shortcutView?.center = center
    }
}

extension FTShortcutToolPresenter {
     func updateMinOffsetIfNeeded() {
         guard let frame = self.parentVC?.view.frame else {
             return;
         }
        if UIDevice().isIphone() || frame.width < FTToolbarConfig.compactModeThreshold {
            var extraOffset: CGFloat = 0.0
            if UIDevice.current.isPhone() {
                if let window = self.parentVC?.view.window {
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
    }

    func shortcutViewCenter(for placement: FTShortcutPlacement, size: CGSize) -> CGPoint {
        guard let shortcutView = self.shortcutView else {
            return .zero;
        }
        return placement.shortcutViewCenter(fotShortcutView: shortcutView, topOffset: toolbarOffset);
    }
}
