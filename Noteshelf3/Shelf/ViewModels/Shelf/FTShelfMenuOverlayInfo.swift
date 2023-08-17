//
//  FTShelfMenuDisplay.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import FTCommon

class FTShelfMenuOverlayInfo: ObservableObject {
    weak var splitController: FTShelfSplitViewController?;
    private weak var menuTouchReceiverView: FTShelfMenuOverlayView?;
    
    @Published var isMenuShown: Bool = false {
        didSet {
            if(isMenuShown != oldValue) {
                if(isMenuShown) {
                    self.addMenuTouchHandlerView();
                }
                else {
                    self.removeMenuTouchHandlerView();
                }
            }
        }
    }
    
    private func addMenuTouchHandlerView() {
        if nil == menuTouchReceiverView, let keywindp = self.splitController?.view {
            let view = FTShelfMenuOverlayView(frame: keywindp.bounds);
            view.shelfMenuOverlayInfo = self;
            view.backgroundColor = UIColor.clear;//UIColor.blue.withAlphaComponent(0.4);
            keywindp.addSubview(view);
            self.menuTouchReceiverView = view;
        }
    }
    
    private  func removeMenuTouchHandlerView() {
        self.menuTouchReceiverView?.removeFromSuperview();
    }
}

private class FTShelfMenuOverlayView: UIView {
    weak var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo?;
    var receivedtouch = false;
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event);
        receivedtouch = true;
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event);
        self.shelfMenuOverlayInfo?.isMenuShown = false;
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event);
        self.shelfMenuOverlayInfo?.isMenuShown = false;
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view =  super.hitTest(point, with: event);
        if view == self, shelfMenuOverlayInfo?.isMenuShown ?? false {
            runInMainThread(0.3) { [weak self] in
                if !(self?.receivedtouch ?? false) {
                    self?.shelfMenuOverlayInfo?.isMenuShown = false;
                }
            }
        }
        return view;
    }
}
