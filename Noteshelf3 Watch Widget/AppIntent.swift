//
//  AppIntent.swift
//  Noteshelf3 Watch Widget
//
//  Created by Narayana on 19/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import WidgetKit
import AppIntents
import Combine

struct ConfigurationAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    func perform() async throws -> some IntentResult {
        FTWatchWidgetActionController.shared.performAction(action: .record)
        return .result()
    }
}

enum FTWatchWidgetActionType {
    case record
}

class FTWatchWidgetActionController {
    static var shared : FTWatchWidgetActionController = FTWatchWidgetActionController()
    private(set) var actionToExecute : FTWatchWidgetActionType?
    private init() {}

    func performAction(action : FTWatchWidgetActionType) {
        self.actionToExecute = action
    }
    func resetWidgetAction() {
        self.actionToExecute = nil
    }
}
