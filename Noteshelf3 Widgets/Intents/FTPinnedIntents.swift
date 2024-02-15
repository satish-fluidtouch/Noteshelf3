//
//  FTPinnedIntents.swift
//  Noteshelf3 WidgetsExtension
//
//  Created by Narayana on 15/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import AppIntents

struct FTPinnedPenIntent : AppIntent {
    static var title: LocalizedStringResource = "Pen"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.pen)
        return .result()
    }
}

struct FTPinnedAudioIntent : AppIntent {
    static var title: LocalizedStringResource = "Audio"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.audio)
        return .result()
    }
}

struct FTPinnedOpenAIIntent : AppIntent {
    static var title: LocalizedStringResource = "OpenAI"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.openAI)
        return .result()
    }
}

struct FTPinnedTextIntent : AppIntent {
    static var title: LocalizedStringResource = "Text"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.text)
        return .result()
    }
}
