//
//  FTNumberTextList.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTNumberTextList: FTTextList {
    override init(markerFormat format: String, options mask: Int) {
        super.init(markerFormat: format, options: mask)
        startingItemNumber = 1
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func _isOrdered() -> Bool {
        return true
    }
    
    override var isOrdered: Bool {
        return true;
    }

    override func marker(forItemNumber itemNum: Int) -> String {
        return String(format: "%ld.", itemNum + startingItemNumber)
    }
    
    override func markerItemNumber(inLineString lineString: String?) -> Int {
        let scanner = Scanner(string: lineString ?? "")
        var scannedString: String?
        
        if #available(iOS 13.0, *) {
           scannedString = scanner.scanUpToString(".\t")
        } else {
           var result: NSString?
           _ = scanner.scanUpTo(".\t", into: &result)
           scannedString = result as String?
        }
        var newNumber = 0

        if let scannedString = scannedString {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            newNumber = f.number(from: scannedString)?.intValue ?? 0
        }
        return newNumber - startingItemNumber
    }

    override func isOrderedTextList() -> Bool {
        return true
    }
}
