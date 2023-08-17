//
//  FTAutoTriggerButton.swift
//  Noteshelf
//
//  Created by Amar on 01/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
private extension TimeInterval {
    static let startDelay: TimeInterval = 0.3;
    static let eventHitDelay: TimeInterval = 0.2;
}

class FTAutoTriggerButton: FTBaseButton {
    private let supportsAutoTrigger = true;
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let track = super.beginTracking(touch, with: event);
        if(track) {
            self.scheduleActionTrigger();
        }
        return track;
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event);
        self.cancelActionTrigger();
    }
    
    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event);
        self.cancelActionTrigger();
    }
}

private extension FTAutoTriggerButton {
    func scheduleActionTrigger() {
        if(supportsAutoTrigger) {
            self.perform(#selector(self.triggerAction(_:)), with: nil, afterDelay: TimeInterval.startDelay);
        }
    }
    func cancelActionTrigger() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.triggerAction(_:)), object: nil);
    }
    
    @objc func triggerAction(_ timer: Any?) {
        self.sendActions(for: .touchUpInside);
        if(self.isTracking) {
            self.perform(#selector(self.triggerAction(_:)), with: nil, afterDelay: TimeInterval.eventHitDelay);
        }
    }
}
