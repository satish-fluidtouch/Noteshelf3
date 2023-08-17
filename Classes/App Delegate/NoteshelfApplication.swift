//
//  NoteshelfApplication.swift
//  Noteshelf
//
//  Created by Akshay on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

let Application = UIApplication.shared as! NoteshelfApplication

typealias FTApplication = UIApplication

@objcMembers class NoteshelfApplication: FTApplication {
    var visibleViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.visibleViewController
    }
    
    override func sendEvent(_ event: UIEvent) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: FTUserDidTouchOnScreenNotification), object: nil);
        if let touch = event.allTouches?.first,
            let window = touch.view?.window,
            window.windowLevel == .normal {
            window.makeKey();
        }
        super.sendEvent(event);
    }
}
