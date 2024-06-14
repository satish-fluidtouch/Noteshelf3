//
//  FTPDFRenderViewController+PencilPro.swift
//  Noteshelf3
//
//  Created by Narayana on 31/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension FTPDFRenderViewController {
    @objc func configurePencilProInteractionIfAvailable() {
        if #available(iOS 17.5, *) {
            let pencilInteraction = UIPencilInteraction(delegate: self)
            self.view.addInteraction(pencilInteraction)
        }
    }
    
    func checkIfPencilProMenuExist() -> Bool {
        let isPencilProMenuExist = self.children.contains { child in
            return child is FTPencilProMenuController
        }
        return isPencilProMenuExist
    }
    
    @objc func showPencilProMenuIfNeeded(using anchorPoint: CGPoint) {
        var convertedAnchorPoint = anchorPoint
        if !self.checkIfPencilProMenuExist() {
            if let proMenu = UIStoryboard(name: "FTDocumentView", bundle: nil).instantiateViewController(withIdentifier: "FTPencilProMenuController") as? FTPencilProMenuController {
                convertedAnchorPoint = self.validAnchorPointForPencilProMenu(with: anchorPoint)
                if let toolbar = self.parent as? FTToolbarElements,  !toolbar.isInFocusMode() {
                    NotificationCenter.default.post(name: NSNotification.Name(FTToggleToolbarModeNotificationName), object: nil)
                }
                proMenu.delegate = self
                self.add(proMenu, frame: CGRect(origin: convertedAnchorPoint, size: FTPenSliderConstants.primaryMenuSize))
            }
        } else {
            self.removePencilProMenuIfExist()
        }
    }
    
    func validAnchorPointForPencilProMenu(with anchorPoint: CGPoint) -> CGPoint {
        var point = anchorPoint
        point.x = max(200, anchorPoint.x)
        point.y = max(240, anchorPoint.y)
        
        let offset: CGFloat = 175
        if anchorPoint.x > self.view.frame.maxX - offset {
            point.x = self.view.frame.maxX - offset
        }
        if anchorPoint.y > self.view.frame.maxY - offset {
            point.y = self.view.frame.maxY - offset
        }
        point.x -= 150
        point.y -= 150
        return point
    }
    
    @objc func removePencilProMenuIfExist() {
        self.children.compactMap { $0 as? FTPencilProMenuController }.forEach { $0.remove() }
    }
}

@available(iOS 17.5, *)
extension FTPDFRenderViewController: UIPencilInteractionDelegate {
    public func pencilInteraction(_ interaction: UIPencilInteraction,
                           didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        let preferredAction = UIPencilInteraction.preferredSqueezeAction
        guard preferredAction != .ignore else { return }
        // TODO: // show rool palette
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
    
    func getCurrentDeskMode() -> RKDeskMode {
        return self.currentDeskMode
    }
    
    func updateShapeModel(_ model: FTFavoriteShapeViewModel) {
        self.shapeModel = model
    }
    
    func updateColorModel(_ model: FTFavoriteColorViewModel) {
        self.colorModel = model
    }
}
