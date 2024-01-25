//
//  FTAnnotationBaseView.swift
//  Noteshelf
//
//  Created by Amar on 30/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc protocol FTTouchEventProtocol : NSObjectProtocol {
    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?);
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?);
}

 protocol FTTextMenuActionProtocol: NSObjectProtocol {
    func canPerformAction(view: FTAnnotationBaseView, action: Selector, withSender sender: Any!) -> Bool
    func textMenuAction(action: FTTextMenuAction, sender: Any?)
}

enum FTTextMenuAction: String {
    case edit
    case cut
    case copy
    case lock
    case bringToFront
    case sendToBack
    case delete
    case linkTo
    case editLink
    case removeLink
    case converToStroke
}

class FTAnnotationBaseView: UIView
{
    private weak var touchEventHandler : FTTouchEventProtocol?
    private weak var menuHandler: FTTextMenuActionProtocol!
    
    convenience init(frame: CGRect,touchEventHandler : FTTouchEventProtocol, menuHandler: FTTextMenuActionProtocol) {
        self.init(frame: frame)
        self.touchEventHandler = touchEventHandler
        self.menuHandler = menuHandler
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        self.touchEventHandler?.processTouchesBegan(touches, with: event);
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        self.touchEventHandler?.processTouchesEnded(touches, with: event);
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        self.touchEventHandler?.processTouchesMoved(touches, with: event);
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event);
        self.touchEventHandler?.processTouchesCancelled(touches, with: event);
    }
    
    override var canBecomeFirstResponder: Bool {
            return true
    }
    
    @objc func editMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .edit, sender: sender)
    }

    @objc func cutMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .cut, sender: sender)
    }

    @objc func copyMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .copy, sender: sender)
    }

    @objc func lockMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .lock, sender: sender)
    }

    @objc func convertToStroke(_ sender:Any?) {
        self.menuHandler.textMenuAction(action: .converToStroke, sender: sender)
    }

    @objc func bringToFrontMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .bringToFront, sender: sender)
    }

    @objc func sendToBackMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .sendToBack, sender: sender)
    }

    @objc func deleteMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .delete, sender: sender)
    }

    @objc func linkToMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .linkTo, sender: sender)
    }

    @objc func editLinkMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .editLink, sender: sender)
    }

    @objc func removeLinkMenuItemAction(_ sender: Any?) {
        self.menuHandler.textMenuAction(action: .removeLink, sender: sender)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any!) -> Bool {
        return self.menuHandler.canPerformAction(view: self, action: action, withSender: sender)
    }

}
