//
//  FTCustomFontInfo.swift
//  Noteshelf
//
//  Created by Naidu on 20/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

@objcMembers class FTCustomFontInfo: NSObject {
    
    var displayName:String = ""
    var fontName:String = ""
    var fontStyle:String = ""
    var fontSize:CGFloat = 18
    var textColor:UIColor = UIColor.headerColor
    var isBold:Bool = false
    var isItalic:Bool = false
    var isUnderlined:Bool = false
    
    class func font(withDictionary dictInfo: [String : String]) -> FTCustomFontInfo {
        let fontInfo = FTCustomFontInfo()
        if let displayName = dictInfo["displayName"], let fontName = dictInfo["fontName"], let fontStyle = dictInfo["fontStyle"], let fontSize = dictInfo["fontSize"], let isBold = dictInfo["isBold"], let isItalic = dictInfo["isItalic"], let isUnderlined = dictInfo["isUnderlined"], let textColor = dictInfo["textColor"] {
            fontInfo.displayName = displayName
            fontInfo.fontName = fontName
            fontInfo.fontStyle = fontStyle
            fontInfo.fontSize = CGFloat(fontSize.floatValue)
            fontInfo.textColor = UIColor.init(hexString: textColor)
            fontInfo.isBold = (isBold as NSString).integerValue == 0 ? false : true
            fontInfo.isItalic = (isItalic as NSString).integerValue == 0 ? false : true
            fontInfo.isUnderlined = (isUnderlined as NSString).integerValue == 0 ? false : true
            return fontInfo
        }
        return fontInfo
    }
    
    func dictionaryRepresentation() -> [String : String] {
        var fontInfoDict : [String : String] = [:]
        
        fontInfoDict["displayName"] = self.displayName
        fontInfoDict["fontName"] = self.fontName
        fontInfoDict["fontStyle"] = self.fontStyle
        fontInfoDict["fontSize"] = String(format: "%.0f", self.fontSize)
        fontInfoDict["textColor"] = self.textColor.hexStringFromColor()
        fontInfoDict["isBold"] = self.isBold ? "1" : "0"
        fontInfoDict["isItalic"] = self.isItalic ? "1" : "0"
        fontInfoDict["isUnderlined"] = self.isUnderlined ? "1" : "0"
        
        return fontInfoDict
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        let lhs = self;
        if let rhs = object as? FTCustomFontInfo {
            let fontsize : CGFloat = CGFloat(roundf(Float(rhs.fontSize)))
            let value = lhs.fontName == rhs.fontName && lhs.fontStyle == rhs.fontStyle &&  lhs.fontSize == fontsize && lhs.textColor.hexStringFromColor() == rhs.textColor.hexStringFromColor() && lhs.isBold == rhs.isBold && lhs.isItalic == rhs.isItalic && lhs.isUnderlined == rhs.isUnderlined
            return value;
        }
        return false;
    }
}

//extension FTCustomFontInfo : Equatable {
//
//    static func == (lhs: FTCustomFontInfo, rhs: FTCustomFontInfo) -> Bool {
//        return lhs.displayName == rhs.displayName && lhs.fontName == rhs.fontName && lhs.fontStyle == rhs.fontStyle && lhs.fontSize == rhs.fontSize && lhs.textColor == rhs.textColor && lhs.isBold == rhs.isBold && lhs.isItalic == rhs.isItalic && lhs.isUnderlined == rhs.isUnderlined
//    }
//}
