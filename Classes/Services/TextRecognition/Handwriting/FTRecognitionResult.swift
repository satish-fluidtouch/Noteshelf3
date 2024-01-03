//
//  FTPageRecognitionResult.swift
//  Noteshelf
//
//  Created by Naidu on 21/12/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objcMembers class FTRecognitionResult: NSObject {
    
    private lazy var _characterRects : [CGRect] = {
        var characterRects :[CGRect] = []
        if let data = charRectsData {
            let characterRectValues:[NSValue]? = NSDataValueConverter.rectValuesArray(from: data)
            characterRectValues?.forEach { (rectValue) in
                let charRect = rectValue.cgRectValue
                characterRects.append(charRect)
            }
        }
        return characterRects
    }();
    
    var characterRects : [CGRect]  {
        set {
            self._characterRects = newValue;
        }
        get {
            return self._characterRects;
        }
    }
    
    private var charRectsData: Data?;
    
    var recognisedString : String = ""
    var languageCode : String = ""
    var lastUpdated : NSNumber! = NSNumber.init(value: 0.0)
    
    fileprivate var characterRectData : Data{
        let rectData = NSDataValueConverter.data(withRectValuesArray: self.characterRects)
        return rectData!
    }
    
    //MARK:- Life cycle -
    convenience init(withDictionary dict: Dictionary<String, Any>) {
        self.init();
        if dict["recognisedText"] != nil  {
            let fullString = dict["recognisedText"] as? NSString
            let recognisedText = (fullString  as String?) ?? ""
            self.recognisedString = recognisedText
        }
        
        if let characterRectsData = dict["characterRects"] as? Data{
            self.charRectsData = characterRectsData;
        }
        if let lastUpdated = dict["lastUpdated"] as? NSNumber{
            self.lastUpdated = lastUpdated
        }
        if dict["language"] != nil  {
            let language = dict["language"] as? NSString
            let languageCode = (language  as String?) ?? ""
            self.languageCode = languageCode
        }
    }
    
    deinit {
        #if DEBUG
      //  debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    //MARK:- Content Read/Write -
    
    func dictionaryRepresentation() -> [String : Any]
    {
        var dictRep = [String : Any]();
        
        dictRep["recognisedText"] = self.recognisedString
        dictRep["characterRects"] = self.characterRectData
        dictRep["lastUpdated"] = self.lastUpdated
        dictRep["language"] = self.languageCode
        return dictRep;
    }
}
extension String {
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, options: [CompareOptions.caseInsensitive], range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                                        break
            }
            position = index(after: after)
        }
        return indices
    }
    
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        get {
            return self[..<index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring {
        get {
            return self[...index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring {
        get {
            return self[index(startIndex, offsetBy: value.lowerBound)...]
        }
    }
}
