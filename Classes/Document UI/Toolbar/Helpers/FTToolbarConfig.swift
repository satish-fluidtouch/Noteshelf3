//
//  FTToolbarConfig.swift
//  Noteshelf3
//
//  Created by Narayana on 04/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTToolbarConfig {
    static let borderColor = UIColor.appColor(.toolbarOutline).resolvedColor(with: .current)
    static let borderWidth: CGFloat = 0.5
    static let cornerRadius: CGFloat = 12.0
    static let bgColor = UIColor.appColor(.regularToolbarBgColor)
    static let stickyBgColor = UIColor.appColor(.hModeToolbarBgColor)
    static let compactModeThreshold: CGFloat = 512.0

    struct Height {
        static let compact: CGFloat = 110.5
        static let regular: CGFloat = 62.5
    }

    struct CenterPanel {
        struct DeskToolSize {
            static let compact = CGSize(width: 48, height: 48)
            static let regular = CGSize(width: 44, height: 48)
        }
        struct NavButtonWidth {
            static let compact: CGFloat = 40.0
            static let regular: CGFloat = 26.0
        }
    }
}
