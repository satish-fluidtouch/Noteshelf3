//
//  FTPDFRenderViewController_KeyboardListener.swift
//  Noteshelf
//
//  Created by Amar on 23/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation

private struct AssociatedKeys {
    static var keyboardHeight: UInt8 = 0
    static var isOrientationChanging: UInt8 = 0
}

@objc extension FTPDFRenderViewController {

    private var keyboardHeight: Int {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.keyboardHeight) as? Int;
            return value ?? 0;
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.keyboardHeight, newValue, .OBJC_ASSOCIATION_ASSIGN);
        }
    }

    private var isOrientationChanging: Bool {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.isOrientationChanging) as? Bool;
            return value ?? false;
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isOrientationChanging, newValue, .OBJC_ASSOCIATION_ASSIGN);
        }
    }

    func addkeyboardListeners() {
        let defaultNotificationCenter = NotificationCenter.default;
        defaultNotificationCenter.addObserver(self,
                                              selector: #selector(keyboardStatusDidChange(_:)),
                                              name: UIApplication.keyboardWillHideNotification,
                                              object: nil);
        defaultNotificationCenter.addObserver(self,
                                              selector: #selector(keyboardStatusDidChange(_:)),
                                              name: UIApplication.keyboardWillShowNotification,
                                              object: nil);
    }
    
    private func keyboardStatusDidChange(_ notification : Notification)
    {
        if let userInfo = notification.userInfo, let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,let rootController = self.view.window?.rootViewController {
            let endFrame = endFrameValue.cgRectValue;
            let endFrameWrtWindow = rootController.view.convert(endFrame, to: nil);
            let screenHeight = UIScreen.main.bounds.height;
            let viewHeight = rootController.view.frame.height;
            let offset = (screenHeight - viewHeight)*0.5;
            
            let heightOfKeyboard = fabsf(Float(viewHeight - endFrameWrtWindow.origin.y + offset));
            
            self.keyboardHeight = Int(heightOfKeyboard)
            if isFloatingKeyboard(keyboardFrame: endFrame) {
                self.keyboardHeight = 0
            }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateAccesooryHieght), object: nil);
            if(self.isOrientationChanging) {
                self.perform(#selector(self.updateAccesooryHieght), with: nil, afterDelay: 0.1);
            }
            else {
                self.updateAccesooryHieght();
            }
        }
    }
    
    private func isFloatingKeyboard(keyboardFrame: CGRect) -> Bool {
        let screenBounds = UIScreen.main.bounds
        return !(screenBounds.width == keyboardFrame.width)
    }
    
    func willBeginTransitionToSize() {
        self.isOrientationChanging = true;
        if(self.keyboardHeight > 0) {
            self.keyboardHeight = 0;
            self.updateAccesooryHieght();
        }
    }
    
    func didEndTransitionToSize() {
        self.isOrientationChanging = false;
    }

    private func updateAccesooryHieght() {
        if(self.pageLayoutHelper.layoutType == .vertical) {
            self.mainScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(self.keyboardHeight), right: 0);
        }
        else {
            self.firstPageController()?.scrollView?.accessoryViewHeight = self.keyboardHeight;
        }
    }
}
