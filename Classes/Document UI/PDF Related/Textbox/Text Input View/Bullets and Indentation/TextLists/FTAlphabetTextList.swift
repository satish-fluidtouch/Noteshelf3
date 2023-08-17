//
//  FTAlphabetTextList.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTAlphabetTextList: FTTextList {
    let base = 26
    
    override init(markerFormat format: String, options mask: Int) {
        super.init(markerFormat: format, options: mask)
        startingItemNumber = 0
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override  func markerFormat() -> String {
        return markerList ?? ""
    }
    
    override func _isOrdered() -> Bool {
        return true
    }
    
    override var isOrdered: Bool {
        return true;
    }
    
    override func marker(forItemNumber itemNum: Int) -> String {
        let alphaChar = decToOther(itemNum + startingItemNumber, base)
        return  String(format: "%@.",alphaChar ?? "")
    }
    
    override func markerItemNumber(inLineString lineString: String) -> Int {
        let scanner = Scanner(string: lineString)
        var scannedString: String?
        var newNumber = 0
        
        if #available(iOS 13.0, *) {
               scannedString = scanner.scanUpToString(".\t")
        } else {
            var result: NSString?
            _ = scanner.scanUpTo(".\t", into: &result)
            scannedString = result as String?
        }

        if scannedString != nil {
            newNumber = otherToDec(scannedString, base)
        }
        return newNumber - startingItemNumber
    }

    override func isOrderedTextList() -> Bool {
        return true
    }
}

    func aReverseString(_ original: String?) -> String? {
        guard let string = original else {
            return ""
        }
        var chars = [Character]()
        string.reversed().forEach{ string in
            chars.append(string)
        }
        return String(chars)
    }

    func otherToDec(_ original: String?, _ base: Int) -> Int {
        guard let original = original, !original.uppercased().isEmpty else {
            return 0
        }
      
        let str = (original.uppercased()).cString(using: .ascii)
        let len = strlen(str!)
        var power = len - 1
        var number: Int
        var j: Int

        number = 0
        for i in 0..<len {
            j = Int(str![i]) - 65
            let p = (pow(Decimal(base), power) as NSDecimalNumber).intValue
            number += j * p
            power -= 1
        }
        return number
    }

    func decToOther(_ number: Int, _ base: Int) -> String? {
        var number = number
        let mutableString = NSMutableString.init(string: "")
        var temp: Int
        number = number % base

        repeat {
            temp = number % base
            mutableString.appendFormat("%c", (65 + temp))
            number /= base
        } while number != 0
        return aReverseString(mutableString as String)
    }
