//
//  FTToolTypeShortcutContainerController.swift
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

private let minYOffset: CGFloat = 80.0

class FTToolTypeShortcutContainerController: UIViewController {
    @IBOutlet weak var contentHolderView: FTShortcutContentHolderView!
    var rackType: FTRackType = .pen
    var mode: FTScreenMode = .normal

    private weak var toolbarVc: FTToolTypeShortcutViewController?
    private weak var pensizeEditVc: FTPenSizeEditController?

    private var rack: FTRackData = FTRackData(type: .pen, userActivity: nil)
    weak var delegate: FTShortcutContainerDelegate?

    // Internal variables/functions for extension purpose, not intended for out world
    internal var isMoving: Bool = false
    internal var panTouchPoint: CGPoint = .zero
    internal var quadrantDetector: FTQuadrantDetector!
    internal var shortCutQuadrant: FTShortcutQuadrant = .topLeft
    internal var shortcutViewPlacement: FTShortcutPlacement = .centerLeft

    internal var shortcutView: UIView {
        guard let shortcutview = self.contentHolderView.shortcutView else {
            fatalError("shortcutView is nil")
        }
        return shortcutview;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shortcutViewPlacement = self.fetchShortcutViewPlacement()
        NotificationCenter.default.addObserver(self, selector: #selector(showToast(_:)), name: NSNotification.Name.PresetColorUpdate, object: nil)
        self.configurePanGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.rack = FTRackData(type: rackType, userActivity: self.view.window?.windowScene?.userActivity)
        let reqSize = self.getShortcutViewSize()
        self.shortcutView.frame.size = reqSize
        let reqCenter = self.contentHolderView.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
        self.updateShortcutViewCenter(reqCenter)
        self.toolbarVc?.showShortcutViewWrto(rack: rack)
        self.configureHitTesting()
    }

    private func configureHitTesting() {
        (self.view as? FTShortcutContainerView)?.toolbarContainerController = self
    }

    private var contentSize = CGSize.zero
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let curSize = self.view.frame.size
        if(!curSize.equalTo(contentSize)) {
            contentSize = curSize;
            self.prepareQuadrants()
            self.contentHolderView?.updateMinOffsetIfNeeded()
            self.configureShortcutView(with: mode)
            if let parent = self.parent as? FTPDFRenderViewController, let zoomVc = parent.zoomOverlayController {
                self.handleZoomPanelFrameChange(zoomVc.view.frame, mode: zoomVc.shortcutModeZoom, completion: nil)
            }
        }
    }

    func configureShortcutView(with mode: FTScreenMode, animate: Bool = false) {
        self.mode = mode
        let reqSize = self.getShortcutViewSize()
        var reqCenter = self.contentHolderView.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)

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
            let center = self.shortcutView.center
            //TODO: prepareQuadrants() - will be done in isViewAppearing(after ios17 release), so that below condition can be removed. Right now before quadrants are ready, this method is getting called, so added.
            if nil == self.quadrantDetector {
                self.prepareQuadrants()
            }
            self.updateQuadrant(quadrant: self.quadrantDetector.getQuadrant(for: center))
            let reqSize = self.getShortcutViewSize()
            let placement = self.contentHolderView.fetchNearstPlacement(from: center, quadrant: self.shortCutQuadrant, size: reqSize)
            placement.save()
        }
    }

    @objc func handleZoomPanelFrameChange(_ frame: CGRect, mode: FTZoomShortcutMode, animate: Bool = false, completion:(() -> Void)?) {
        if mode == .manual {
            completion?()
            return
        }
        let shortCutYpos = self.shortcutView.frame.origin.y

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
            if shortCutYpos >= minYOffset {
                if self.shortcutView.frame.maxY > frame.origin.y {
                    let offSetToMove = self.shortcutView.frame.maxY - frame.origin.y
                    let reqPos = shortCutYpos - offSetToMove
                    if reqPos > minYOffset {
                        self.shortcutView.frame.origin.y = reqPos
                    } else {
                        self.shortcutView.frame.origin.y = minYOffset
                    }
                } else {
                    let offSetToMove = frame.origin.y - self.shortcutView.frame.maxY
                    let reqPos = shortCutYpos + offSetToMove
                    let reqSize = self.getShortcutViewSize()
                    let actualCenter = self.contentHolderView.shortcutViewCenter(for: self.shortcutViewPlacement, size: reqSize)
                    let actualYPos = actualCenter.y - self.shortcutView.frame.height/2.0
                    if reqPos < actualYPos {
                        self.shortcutView.frame.origin.y = reqPos
                    } else {
                        self.updateShortcutViewCenter(actualCenter)
                    }
                }
            }
        }
    }

    @objc private func showToast(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: String] else {
            return
        }
        var toastMessage = "color.added".localized
        if info["type"] == FTColorToastType.delete.rawValue {
            toastMessage = "color.deleted".localized
        } else if info["type"] == FTColorToastType.edit.rawValue {
            toastMessage = "color.edited".localized
        }
        let config = FTToastConfiguration(title: toastMessage)
        FTToastHostController.showToast(from: self, toastConfig: config)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Segue, delegate handlers
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FTToolTypeShortcutViewController", let controller = segue.destination as? FTToolTypeShortcutViewController {
            self.toolbarVc = controller
            controller.delegate = self
        }
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
extension FTToolTypeShortcutContainerController {
    func showSizeEditView(position: FavoriteSizePosition, viewModel: FTFavoriteSizeViewModel) {
        self.removeSizeEditViewIfNeeded()
        let controller = FTPenSizeEditController(viewModel: viewModel, editPosition: position)
        self.pensizeEditVc = controller
        self.addChild(controller)
        controller.view.backgroundColor = .clear
        controller.view.center = self.getPenSizeEditViewCenter(at: position)
        controller.view.frame.size = FTPenSizeEditController.editViewSize
        self.view.addSubview(controller.view)
        controller.didMove(toParent: self)
        (self.view as? FTShortcutContainerView)?.pensizeEditVc = controller
    }

    private func getPenSizeEditViewCenter(at position: FavoriteSizePosition) -> CGPoint {
        var center: CGPoint = .zero
        let xOffset: CGFloat = 40.0

        if self.rackType == .shape {
            let yOffset: CGFloat = 75.0 // for shape we have single size only
            if self.shortcutViewPlacement.isLeftPlacement() {
                center.x = self.shortcutView.frame.maxX + xOffset
            } else {
                center.x = self.shortcutView.frame.minX - FTPenSizeEditController.editViewSize.width - xOffset
            }
            center.y = self.shortcutView.center.y + yOffset
        } else {
            let step: CGFloat = 36.0
            if self.shortcutViewPlacement.isLeftPlacement() {
                center.x = self.shortcutView.frame.maxX + xOffset
            } else {
                center.x = self.shortcutView.frame.minX - FTPenSizeEditController.editViewSize.width - xOffset
            }
            center.y = self.shortcutView.center.y - 15.0
            if position == .second {
                center.y += step
            } else if position == .third {
                center.y += (2 * step)
            }
        }
        return center
    }

    func removeSizeEditViewIfNeeded() {
        (self.view as? FTShortcutContainerView)?.pensizeEditVc = nil
        if let sizeEditVc = self.pensizeEditVc {
            sizeEditVc.willMove(toParent: nil)
            sizeEditVc.removeFromParent()
            sizeEditVc.view.removeFromSuperview()
        }
    }
}

extension FTToolTypeShortcutContainerController: FTShorctcutActionDelegate {
    func didTapPresentationOption(_ option: FTPresenterModeOption) {
        self.delegate?.didTapPresentationOption(option)
    }

    func didChangeCurrentPenset(_ penset: FTPenSetProtocol) {
        self.rack = FTRackData(type: self.rackType, userActivity: self.view.window?.userActivity)
        if self.rackType == .presenter, let presenterSet = penset as? FTPresenterSetProtocol {
            self.rack.currentPenset = presenterSet
            self.rack.saveCurrentSelection()
            self.delegate?.didChangeCurrentPenset(penset: presenterSet)
        } else {
            self.rack.currentPenset.color = penset.color
            self.rack.currentPenset.size = penset.size
            self.rack.currentPenset.preciseSize = penset.preciseSize
            self.rack.saveCurrentSelection()
            self.delegate?.didChangeCurrentPenset(penset: self.rack.currentPenset)
        }
    }
}

// MARK: - Helper methods
extension FTToolTypeShortcutContainerController {
    private func prepareQuadrants() {
        self.quadrantDetector = FTQuadrantDetector(view: contentHolderView, centerQuadrantInSet: 0.33)
    }

    private func fetchShortcutViewPlacement() -> FTShortcutPlacement {
        let placement = FTShortcutPlacement.getSavedPlacement()
        return placement
    }

    internal func updateQuadrant(quadrant: FTShortcutQuadrant) {
        self.shortCutQuadrant = quadrant
    }

    internal func updateShortcutViewCenter(_ center: CGPoint) {
        self.shortcutView.center = center
    }
}
