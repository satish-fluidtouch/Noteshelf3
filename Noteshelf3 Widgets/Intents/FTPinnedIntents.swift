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
    static var persistentIdentifier: String = "PinnedPenIntent"

    @Parameter(title: "Path")
    var relativePath: String
        
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.pen(self.relativePath))
        return .result()
    }
}

struct FTPinnedAudioIntent : AppIntent {
    static var title: LocalizedStringResource = "Audio"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedAudioIntent"
    
    @Parameter(title: "Path")
    var relativePath: String
        
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.audio(self.relativePath))
        return .result()
    }
}

struct FTPinnedOpenAIIntent : AppIntent {
    static var title: LocalizedStringResource = "OpenAI"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedOpenAIIntent"
    @Parameter(title: "Path")
    var relativePath: String
        
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.openAI(self.relativePath))
        return .result()
    }
}

struct FTPinnedTextIntent : AppIntent {
    static var title: LocalizedStringResource = "Text"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedTextIntent"
    @Parameter(title: "Path")
    var relativePath: String
        
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.text(self.relativePath))
        return .result()
    }
}

struct FTPinnedBookOpenIntent : AppIntent {
    static var title: LocalizedStringResource = "BookOpen"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedBookOpenIntent"
    
    @Parameter(title: "Path")
    var relativePath: String
        
    func perform() async throws -> some IntentResult {
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.bookOpen(self.relativePath))
        return .result()
    }
}
