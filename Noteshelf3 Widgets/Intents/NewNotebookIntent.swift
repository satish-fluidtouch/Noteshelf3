//
//  NewNotebookIntent.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 07/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import AppIntents

struct NewNotebookIntent : AppIntent {
    static var title: LocalizedStringResource = "New Notebook"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTNotebookCreateWidgetActionType.newNotebook)
        return .result()
    }
}
