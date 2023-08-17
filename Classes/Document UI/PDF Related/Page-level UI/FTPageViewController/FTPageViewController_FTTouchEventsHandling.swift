//
//  FTPageViewController_FTTouchEventsHandling.swift
//  Noteshelf
//
//  Created by Amar on 15/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTPageViewController : FTTouchEventsHandling {
    
    @objc func startAcceptingTouches(_ accept : Bool) {
        if(self.isInZoomMode() || self.currentDeskMode() == .deskModeView) {
            self.contentHolderView?.isUserInteractionEnabled = true;
        }
        else {
            self.contentHolderView?.isUserInteractionEnabled = accept;
            if(!accept) {
                self.writingView?.cancelCurrentStroke();
            }
        }
    }

    func processTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDeskMode() == .deskModeClipboard {
            self.lassoSelectionView?.processTouchesBegan(touches, with: event);
            return;
        }
        NotificationCenter.default.post(name: Notification.Name(FTDismissToolBarAccessoryNotificationName), object: nil);
    }
    
    func processTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDeskMode() == .deskModeClipboard {
            self.lassoSelectionView?.processTouchesMoved(touches, with: event);
            return;
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidMoveTouches"),
                                        object: self.view.window,
                                        userInfo: ["Touches" : touches]);
    }
    
    func processTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDeskMode() == .deskModeClipboard {
            self.lassoSelectionView?.processTouchesEnded(touches, with: event);
            return;
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidEndTouches"),
                                        object: self.view.window);
    }
    
    func processTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.currentDeskMode() == .deskModeClipboard {
            self.lassoSelectionView?.processTouchesCancelled(touches, with: event);
            return;
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidEndTouches"),
                                        object: self.view.window);
    }
}
