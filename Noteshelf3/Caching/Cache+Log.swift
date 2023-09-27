//
//  Cache+Log.swift
//  Noteshelf
//
//  Created by Akshay on 20/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

// MARK: Logging
enum LogType {
    case error
    case info
    case success
}

func cacheLog(_ type: LogType = .info, _ items: Any...) {
    #if DEBUG
    let icon: String
    switch type {
    case .error:
        icon = "🔴"
    case .info:
        icon = "ℹ️"
    case .success:
        icon = "✅"
    }
    print("♻️", icon, items)
    #endif
}
