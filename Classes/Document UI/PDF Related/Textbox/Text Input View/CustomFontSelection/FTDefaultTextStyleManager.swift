//
//  FTCustomFontManager.swift
//  Noteshelf
//
//  Created by Naidu on 21/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

struct FTFontStorage {
    public static let recentFontsKey = "recentFonts"
    public static let displayNameKey = "displayName"
    public static let fontSizeKey = "fontSize"
    public static let fontStyleKey = "fontStyle"
    public static let fontNameKey = "fontName"
    public static let textColorKey = "textColor"
    public static let isUnderlinedKey = "isUnderlined"
    public static let isStrikeThroughKey = "isStrikeThrough"
    public static let isLineSpaceEnabledKey = "isLineSpaceEnabled"
    public static let lineSpaceKey = "lineSpace"
    public static let textAlignmentKey = "textAlignment"
}

@objcMembers class FTDefaultTextStyleManager: NSObject {
    var textStyleInfo: FTTextStyleItem!

    override init() {
        self.textStyleInfo =  FTTextStyleItem()
    }
}
