//
//  SearchIntent.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 05/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import AppIntents
import UIKit

struct SearchIntent : AppIntent {
    static var title: LocalizedStringResource = "Search"
    static var openAppWhenRun: Bool = true
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
