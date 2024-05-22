//
//  FTTemplateStoryDisplayType.swift
//  FTTemplatesStore
//
//  Created by Narayana on 21/05/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTTemplateStoryDisplayType {
    case iPhone
    case large
    case medium
    case small

    var columnCount: Int {
        let count: Int
        switch self {
        case .iPhone, .medium:
            count = 2
        case .large:
            count = 3
        case .small:
            count = 1
        }
        return count
    }

    var interSpacing: CGFloat {
        let spacing: CGFloat
        switch self {
        case .iPhone, .small:
            spacing = 8
        case .large:
            spacing = 12
        case .medium:
            spacing = 10
        }
        return spacing
    }

    var contentInset: UIEdgeInsets {
        let insets: UIEdgeInsets
        switch self {
        case .iPhone, .small:
            insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        case .large:
            insets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        case .medium:
            insets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        }
        return insets
    }

    static func currentType(for size: CGSize) -> FTTemplateStoryDisplayType {
        let type: FTTemplateStoryDisplayType
        let orientation = UIDevice.current.orientation
        if UIDevice.current.isIphone() {
            type = .iPhone
        } else {
            if orientation == .portrait {
                if size.width > 375 {
                    type = .medium
                } else {
                    type = .small
                }
            } else {
                if size.width >= 900 {
                    type = .large
                } else if size.width > 375 {
                    type = .medium
                } else {
                    type = .small
                }
            }
        }
        return type
    }
}
