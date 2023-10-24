//
//  FTTextList.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

/*
The marker format is specified as a constant string, except for a numbering specifier, which takes the form {keyword}. The currently supported values for keyword include:


box    //u2610
check
circle
diamond
disc
hyphen
square //u25A1
lower-hexadecimal
upper-hexadecimal
octal
lower-alpha or lower-latin
upper-alpha or upper-latin
lower-roman
upper-roman
decimal
*/

import Foundation

@objcMembers class FTTextList: NSObject {
    var markerList: String?
    var mask = 0
    var startingItemNumber = 0

    class func textListWithMarkerFormat(_ format:String!, option mask:UInt) -> FTTextList {
        let list:FTTextList
        if (format.hasPrefix("{checkbox}"))
        {
            list = FTCheckBoxTextList(markerFormat:format, options:Int(mask))
        }
        else if (format.hasPrefix("{decimal}"))
        {
            list = FTNumberTextList(markerFormat:format, options:Int(mask))
        }
        else if (format.hasPrefix("{upper-alpha}"))
        {
            list = FTAlphabetTextList(markerFormat:format, options:Int(mask))
        }
        else
        {
            list = FTTextList(markerFormat: format, options: Int(mask))
        }
        return list
    }

    // MARK: Coder/Encode and Equal
    func isEqual(otherList:FTTextList!) -> Bool {
        return (self.markerFormat() == otherList.markerFormat())
    }

   required init?(coder decoder: NSCoder) {
        super.init()
        markerList = decoder.decodeObject(forKey: "markerFormat") as? String
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(markerList, forKey: "markerFormat")
    }

    // MARK: AnyObject instance Methods
    init(markerFormat format: String, options mask: Int) {
        super.init()
        markerList = format
        self.mask = mask
    }

    func listOptions() -> UInt {
        return UInt(mask)
    }

    func markerFormat() -> String {
        return markerList ?? ""
    }

    func marker(forItemNumber itemNum: Int) -> String {
        var bulletString: String?
        if markerList == "{box}" {
            bulletString = String(utf8String: "\u{25ab}") //box
        } else if markerList == "{check}" {
            bulletString = String(utf8String: "\u{2713}") //check
        } else if markerList == "{circle}" {
            bulletString = String(utf8String: "\u{25e6}") //circle
        } else if markerList == "{diamond}" {
            bulletString = String(utf8String: "\u{25c6}") //diamond
        } else if markerList == "{disc}" {
            bulletString = String(utf8String: "\u{2022}") //disc
        } else if markerList == "{hyphen}" {
            bulletString = String(utf8String: "\u{2043}") //hyphen
        } else if markerList == "{square}" {
            bulletString = String(utf8String: "\u{25aa}") //square
        }
        return bulletString ?? ""
    }

    func setStartingItemNumber(itemNum:Int) {
        startingItemNumber = itemNum
    }

    func getStartingItemNumber() -> Int {
        return startingItemNumber
    }

    func _isOrdered() -> Bool {
       return false
    }
    
    public var isOrdered: Bool { return false }

    func _markerSuffix() -> AnyObject! {
        return nil
    }

    func _markerPrefix() -> AnyObject! {
        return nil
    }
    
    //In iOS17 NSTextList is expecting a below Selector to layout the string, since it is a internal method we are not sure what is signature of it. Hence returing nil attachment.
    @available(iOS 17.0, *)
    func markerTextAttachment() -> NSTextAttachment? {
        return nil
    }

    func attributedMarker(forItemNumber itemNumber: Int, scale: CGFloat) -> NSAttributedString? {
        let marker = self.marker(forItemNumber: itemNumber)
        if marker == "" {
            #if DEBUG
            print(String(format:"nil bullet: %@",self.markerFormat()))
            #endif
        }
        let stringToReturn = NSAttributedString(string:marker)
        return stringToReturn
    }

    func markerItemNumber(inLineString lineString: String) -> Int {
        return 0
    }

    func isOrderedTextList() -> Bool {
        return false
    }
}
