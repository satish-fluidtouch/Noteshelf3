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
    static var path = "Hello"
    init() {}

    init(path: String) {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        sharedDefaults?.set(path, forKey: FTPinnedPenIntent.persistentIdentifier)
    }
    
    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        let path = sharedDefaults?.value(forKey: FTPinnedPenIntent.persistentIdentifier) as? String ?? ""
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.pen(path))
        return .result()
    }
}

struct FTPinnedAudioIntent : AppIntent {
    static var title: LocalizedStringResource = "Audio"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedAudioIntent"
    
    init() {}

    init(path: String) {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        sharedDefaults?.set(path, forKey: FTPinnedPenIntent.persistentIdentifier)
    }

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        let path = sharedDefaults?.value(forKey: FTPinnedPenIntent.persistentIdentifier) as? String ?? ""
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.audio(path))
        return .result()
    }
}

struct FTPinnedOpenAIIntent : AppIntent {
    static var title: LocalizedStringResource = "OpenAI"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedOpenAIIntent"
    init() {}

    init(path: String) {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        sharedDefaults?.set(path, forKey: FTPinnedPenIntent.persistentIdentifier)
    }
    
    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        let path = sharedDefaults?.value(forKey: FTPinnedPenIntent.persistentIdentifier) as? String ?? ""
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.openAI(path))
        return .result()
    }
}

struct FTPinnedTextIntent : AppIntent {
    static var title: LocalizedStringResource = "Text"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedTextIntent"
    init() {}

    init(path: String) {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        sharedDefaults?.set(path, forKey: FTPinnedPenIntent.persistentIdentifier)
    }
    
    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        let path = sharedDefaults?.value(forKey: FTPinnedPenIntent.persistentIdentifier) as? String ?? ""
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.text(path))
        return .result()
    }
}

struct FTPinnedBookOpenIntent : AppIntent {
    static var title: LocalizedStringResource = "BookOpen"
    static var openAppWhenRun: Bool = true
    static var persistentIdentifier: String = "PinnedBookOpenIntent"
    static var path = "Hello"
    init() {}

    init(path: String) {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        sharedDefaults?.set(path, forKey: FTPinnedPenIntent.persistentIdentifier)
    }
    
    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: FTSharedGroupID.getAppGroupID())
        let path = sharedDefaults?.value(forKey: FTPinnedPenIntent.persistentIdentifier) as? String ?? ""
        FTWidgetActionController.shared.performAction(action: FTPinndedWidgetActionType.bookOpen(path))
        return .result()
    }
}
