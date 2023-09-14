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

class FTDefaultTextStyleItem: FTTextStyleItem {
    var isAutoLineSpace = false
    var lineSpace: Int = 0
    var alignment: Int = NSTextAlignment.left.rawValue // 0

    init(from styleItem: FTTextStyleItem, isAutoLineSpace: Bool, lineSpace: Int, alignment: NSTextAlignment) {
        super.init()
        displayName = styleItem.displayName
        fontFamily = styleItem.fontFamily
        fontName = styleItem.fontName
        allowsEdit = styleItem.allowsEdit
        fontSize = styleItem.fontSize
        textColor = styleItem.textColor
        isUnderLined = styleItem.isUnderLined
        strikeThrough = styleItem.strikeThrough
        isDefault = styleItem.isDefault
        fontId = styleItem.fontId
        // Additional properties for FTDefaultTextStyleItem
        self.isAutoLineSpace = isAutoLineSpace
        self.lineSpace = lineSpace
        self.alignment = alignment.rawValue
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func dictionaryRepresentation() -> [String : Any] {
        var dict = super.dictionaryRepresentation()
        dict["isAutoLineSpace"] = self.isAutoLineSpace
        dict["lineSpace"] = self.lineSpace
        dict["alignment"] = self.alignment
        return dict
    }

    override func isEqual(_ object: Any?) -> Bool {
        var status = super.isEqual(object)
        if status, let rhs = object as? FTDefaultTextStyleItem {
            let lhs = self
            if !(lhs.isAutoLineSpace == rhs.isAutoLineSpace && lhs.lineSpace == rhs.lineSpace && lhs.alignment == rhs.alignment) {
                status = false
            }
        }
        return status
    }

    override func isFullyEqual(_ object: Any?) -> Bool {
        var status = super.isEqual(object)
        if status, let rhs = object as? FTDefaultTextStyleItem {
            let lhs = self
            if !(lhs.isAutoLineSpace == rhs.isAutoLineSpace && lhs.lineSpace == rhs.lineSpace && lhs.alignment == rhs.alignment) {
                status = false
            }
        }
        return status
    }

    override func textStyleFromAttributes(_ attributes: [NSAttributedString.Key : Any], scale: CGFloat) -> FTDefaultTextStyleItem {
        if let item = super.textStyleFromAttributes(attributes, scale: scale) as? FTDefaultTextStyleItem {
            if let paragrapghStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                item.lineSpace = Int(paragrapghStyle.lineSpacing)
                item.alignment = paragrapghStyle.alignment.rawValue
            }
            return item
        }
        return FTDefaultTextStyleItem(from: FTTextStyleItem(),isAutoLineSpace: false, lineSpace: 0, alignment: .left)
    }
}
