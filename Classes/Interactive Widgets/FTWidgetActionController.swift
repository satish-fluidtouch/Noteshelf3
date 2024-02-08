//
//  FTWidgetActionController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 08/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTWidgetActionController {
    static var shared : FTWidgetActionController = FTWidgetActionController()
    private(set) var actionToExecute : FTWidgetActionType?
    private init() {}

    func performAction(action : FTWidgetActionType) {
        self.actionToExecute = action
    }
    func resetWidgetAction() {
        self.actionToExecute = nil
    }
}
