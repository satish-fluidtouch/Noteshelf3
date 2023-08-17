//
//  FTTextStyle.swift
//  Noteshelf
//
//  Created by Mahesh on 27/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private let plistName = "FTTextStyle"
let key_Default_Style_Name = "New Style"

class FTTextStyle: NSObject, Decodable {
    var version: Int = 0
    var styles: [FTTextStyleItem] = []
  
    func dictionaryRepresentation() -> [String : Any] {
        var fontInfoDict : [String : Any] = [:]
        fontInfoDict["version"] = self.version
        fontInfoDict["styles"] = self.styles
        return fontInfoDict
    }
}


class FTTextStyleItem: NSObject, Decodable {
    var displayName: String = key_Default_Style_Name
    var fontFamily: String = "Helvetica Neue"
    var fontName: String = "HelveticaNeue"
    var allowsEdit: Bool = false
    var fontSize: Int = 16
    var textColor: String = "#000000"
    var isUnderLined: Bool = false
    var strikeThrough: Bool = false
    var fontId: String = UUID().uuidString
    var isDefault: Bool = false

    func dictionaryRepresentation() -> [String : Any] {
        var fontInfoDict : [String : Any] = [:]
        
        fontInfoDict["displayName"] = self.displayName
        fontInfoDict["fontName"] = self.fontName
        fontInfoDict["fontFamily"] = self.fontFamily
        fontInfoDict["fontSize"] = self.fontSize
        fontInfoDict["textColor"] = self.textColor
        fontInfoDict["isUnderLined"] = self.isUnderLined
        fontInfoDict["strikeThrough"] = self.strikeThrough
        fontInfoDict["fontId"] = self.fontId
        fontInfoDict["allowsEdit"] = self.allowsEdit
        fontInfoDict["isDefault"] = self.isDefault
        
        return fontInfoDict
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        let lhs = self;
        if let rhs = object as? FTTextStyleItem {
            let value = lhs.fontName == rhs.fontName && lhs.fontFamily == rhs.fontFamily &&  lhs.fontSize == rhs.fontSize && lhs.textColor.replacingOccurrences(of: "#", with: "") == rhs.textColor.replacingOccurrences(of: "#", with: "") && lhs.isUnderLined == rhs.isUnderLined && lhs.strikeThrough == rhs.strikeThrough
            return value;
        }
        return false
    }
    
    func isFullyEqual(_ object: Any?) -> Bool {
        let lhs = self;
        if let rhs = object as? FTTextStyleItem {
            let value = lhs.displayName == rhs.displayName && lhs.fontName == rhs.fontName && lhs.fontFamily == rhs.fontFamily &&  lhs.fontSize == rhs.fontSize && lhs.textColor.replacingOccurrences(of: "#", with: "") == rhs.textColor.replacingOccurrences(of: "#", with: "") && lhs.isUnderLined == rhs.isUnderLined && lhs.strikeThrough == rhs.strikeThrough
            return value;
        }
        return false
    }
    
    func textStyleFromAttributes(_ attributes: [NSAttributedString.Key : Any], scale: CGFloat) -> FTTextStyleItem {
        var font = attributes[NSAttributedString.Key.font] as! UIFont;
        let originalFont = attributes[NSAttributedString.Key(rawValue: "NSOriginalFont")] as? UIFont;
        let fontColor = attributes[NSAttributedString.Key.foregroundColor] as? UIColor
        let isUnderLined = attributes[NSAttributedString.Key.underlineStyle] as? Int
        let isStrikeThrough = attributes[NSAttributedString.Key.strikethroughStyle] as? Int
        let paragrapghStyle = attributes[NSAttributedString.Key.paragraphStyle]
        
        if(nil != originalFont) {
            font = originalFont!;
        }
        
        let fontPointSize = font.pointSize/scale;
        self.fontFamily = font.familyName
        self.fontName = font.fontName
        self.fontSize = Int(fontPointSize);
        
        if fontColor != nil {
            self.textColor = fontColor?.hexStringFromColor() ?? "#000000"
        }
        else {
            self.textColor = UIColor.black.hexStringFromColor()
        }
        self.isUnderLined = (isUnderLined != nil && isUnderLined == 1) ? true : false
        self.strikeThrough = (isStrikeThrough != nil && isStrikeThrough == 1) ? true : false
        return self
    }
    
    func textStyleShortName() -> String {
        let comps = self.displayName.components(separatedBy: .whitespaces)
        if comps.count <= 1 {
            return String(self.displayName.prefix(2))
        }
        return comps.prefix(2).map({$0.prefix(1)}).joined(separator: "")
    }
}
class FTTextPresetViewModel: NSObject {

    let reset = "Reset".localized
    let navPresettitle = "shelf.notebook.textstyle.Presets".localized
    let done = "done".localized
    let navReordertitle = "shelf.notebook.textstyle.Reorder".localized
    let resetAlertdes = "shelf.notebook.textstyle.resetdescrption".localized
    let alertCancel = "shelf.alert.cancel".localized
    let resetAlert = "Reset".localized
    let editpreset = "Edit".localized
    let deletepreset = "Delete".localized
}
