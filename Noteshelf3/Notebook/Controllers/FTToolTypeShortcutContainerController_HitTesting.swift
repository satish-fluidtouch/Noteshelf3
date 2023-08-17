//
//  FTToolTypeShortcutContainerController_HitTesting.swift
//  Noteshelf
//
//  Created by Narayana on 29/07/22.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

// MARK: - self.view is subclassed to implement hit testing
class FTShortcutContainerView: UIView {
    weak var toolbarContainerController: FTToolTypeShortcutContainerController?
    weak var pensizeEditVc: FTPenSizeEditController?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard event != nil, let contentHolderView = self.toolbarContainerController?.contentHolderView else {
            return nil
        }
        let newPoint = self.convert(point, to: contentHolderView)
        if  self.isPointInsideToolBar(point: newPoint) {
            return super.hitTest(point, with: event)
        } else {
            if let event = event, event.type != .hover {
                self.toolbarContainerController?.removeSizeEditViewIfNeeded()
            }
        }
        return nil
    }

    func isPointInsideToolBar(point: CGPoint) -> Bool {
        guard let shortcutView = self.toolbarContainerController?.shortcutView else {
            return false
        }
        var isPointInsideToolbarContent: Bool = false
        if shortcutView.frame.contains(point) {
            isPointInsideToolbarContent = true
        } else if let frame = self.pensizeEditVc?.view.frame, frame.contains(point) {
            isPointInsideToolbarContent = true
        }
        return isPointInsideToolbarContent
    }
}
