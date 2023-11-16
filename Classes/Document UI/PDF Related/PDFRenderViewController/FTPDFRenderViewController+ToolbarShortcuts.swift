//
//  FTPDFRenderViewController+ToolbarShortcuts.swift
//  Noteshelf3
//
//  Created by Narayana on 29/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

// Its an extension to handle tool shortcut views
extension FTPDFRenderViewController {
    @objc func showToolbarShortcutControllerIfNeeded(mode: RKDeskMode) {
       self.removeShortcutContainerIfExists()
        if mode == .deskModePen || mode == .deskModeMarker || mode == .deskModeShape || mode == .deskModeLaser || mode == .deskModeFavorites {
            self.addShortcutContainer(mode: mode)
        }
    }

    private func addShortcutContainer(mode: RKDeskMode) {
        let toolbarContainer = FTShortcutToolPresenter()
        if let toolbar = self.parent as? FTToolbarElements {
            toolbarContainer.screenMode =  toolbar.isInFocusMode() ? .focus : .normal
        }
        toolbarContainer.delegate = self
        self.toolTypeContainerVc = toolbarContainer
        toolbarContainer.showToolbar(on: self, for: mode)
    }

    func showOrHideShortcutViewIfNeeded(_ mode: FTScreenMode) {
        if let container = self.toolTypeContainerVc {
            container.configureShortcutView(with: mode, animate: true)
            if let zoomVc = self.zoomOverlayController {
                container.handleZoomPanelFrameChange(zoomVc.view.frame, mode: zoomVc.shortcutModeZoom, completion: nil)
            }
        }
    }

   private func removeShortcutContainerIfExists() {
       if let controller = self.toolTypeContainerVc {
           controller.removeFromParent()
           self.toolTypeContainerVc = nil
       }
    }
}

extension FTPDFRenderViewController: FTShortcutContainerDelegate {
    func didTapPresentationOption(_ option: FTPresenterModeOption) {
        if option == .clearAnnotations {
            let alertVc = UIAlertController(title: "presentation.clearAnnotationsAlert".localized, message: "", preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: "Clear All".localized, style: .destructive, handler: { _ in
                self.clearLaserAnnotationsAction()
            }))
            alertVc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alertVc, animated: false, completion: nil)
        } else {
            var reqMode = self.previousDeskMode
            if reqMode.rawValue == -1 || reqMode == .deskModeLaser {
                reqMode = .deskModePen
            }
            let reqTool = FTDeskModeHelper.getEquivalentTool(for: reqMode)
#if !targetEnvironment(macCatalyst)
            if let source = self.centerPanelToolbarSource(for: reqTool) {
                self.switch(reqMode, sourceView: source)
            }
#else // Mac
            self.switch(reqMode, sourceView: nil)
#endif
        }
    }

    func didChangeCurrentPenset(penset: FTPenSetProtocol) {
        self.validateMenuItems()
    }

    func didStartPlacementChange() {
        if let zoomVc = self.zoomOverlayController {
            zoomVc.updateZoomShortcutMode(.manual)
        }
    }
}
