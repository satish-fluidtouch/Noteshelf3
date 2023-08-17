//
//  UIWindow+VisibleViewController.swift
//  Noteshelf
//
//  Created by Akshay on 10/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private extension NSNotification.Name {
    static let popoverDismissal = NSNotification.Name(rawValue: "PopverDismissNotification")
}

///Custom Dismissal
private class FTDismissalGesture: UIGestureRecognizer {

    weak var controller: UIViewController?
    private var touchTime = DispatchTime.now()
    convenience init(target: Any?, action: Selector?, controller: UIViewController) {
        self.init(target: target, action: action)
        self.controller = controller
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        touchTime = DispatchTime.now()
        var shouldRecognize = false

        //Here changing the check of point in the presented controller to visible controller, as we're facing the issue, when we push to another controller in the popover controller and it's content size is bigger than the original presented controller.
        //Hence, this way we can fix this issue
        if let vc = (self.view as? UIWindow)?.visibleViewController,
           let view = vc.view,
           vc.popoverPresentationController != nil,
           let touch = touches.first {
            let point = touch.location(in: view)
            if !view.bounds.contains(point) {
                shouldRecognize = true
            }
        }
        if shouldRecognize && isBottomEdgePan(touches) == false {
            super.touchesBegan(touches, with: event)
            self.perform(#selector(scheduleRecognition), with: self, afterDelay: 0.1)
        } else {
            self.state = .cancelled
            super.touchesBegan(touches, with: event)
        }
    }

    @objc func scheduleRecognition() {
        self.state = .recognized
    }

    func cancelRecognition() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scheduleRecognition), object: nil)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event);
        self.state = .ended;
        //By random multiple taps, decided to keep `150`, in future, if we get any issue, we may need to tweak this value.
        if DispatchTime.now() - touchTime < 150 {
            NotificationCenter.default.post(name: .popoverDismissal, object: self.view, userInfo: nil)
        }
    }

    private func isBottomEdgePan(_ touches: Set<UITouch>) -> Bool {
        var isBottomEdgePan = false;
        if let window = self.view as? UIWindow {
            isBottomEdgePan = false;
            let safeAreaInset = window.safeAreaInsets;
            var rect = window.bounds;
            let height = max(safeAreaInset.bottom,10);
            rect.origin.y = rect.height - height;
            rect.size.height = height;

            for eachTouch in touches {
                let loc = eachTouch.location(in: nil);
                if(rect.contains(loc)) {
                    isBottomEdgePan = true;
                    break;
                }
            }
        }
        return isBottomEdgePan;
    }
}

extension FTOnScreenWritingViewController {
    func setupSingleTapPopoverDismissNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(dismissPopverActionNotification(_:)), name: .popoverDismissal, object: nil)
    }

    @objc private func dismissPopverActionNotification(_ notification: Notification) {
        if notification.isSameSceneWindow(for: self.view.window) {
            self.cancelCurrentStroke()
        }
    }
}
