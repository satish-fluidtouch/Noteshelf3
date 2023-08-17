//
//  FTRotateTapGesture.swift
//  Noteshelf3
//
//  Created by Sameer on 14/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTRotateTapGesture: UITapGestureRecognizer {
    private var touchBeganTime: TimeInterval = Date().timeIntervalSinceReferenceDate;

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if state == .failed {
            return
        }
        self.touchBeganTime = Date().timeIntervalSinceReferenceDate;
        state = UIGestureRecognizer.State.possible
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let toucheEndTime = Date().timeIntervalSinceReferenceDate;
        let touchTime = toucheEndTime - touchBeganTime
        if(touchTime > 0.1) {
            state = UIGestureRecognizer.State.failed
            return
        }
        state = .recognized
    }
}
