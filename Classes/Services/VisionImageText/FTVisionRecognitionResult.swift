//
//  FTVisionRecognitionResult.swift
//  TextRecognitionDemo
//
//  Created by Simhachalam Naidu on 25/09/19.
//  Copyright © 2019 Naidu. All rights reserved.
//

import UIKit

@objcMembers class FTVisionRecognitionResult: NSObject {
    var characterRects : [CGRect] = []
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
            let characterRectValues:[NSValue]? = NSDataValueConverter.rectValuesArray(from: characterRectsData)
            var characterRects :[CGRect] = []
            characterRectValues?.forEach { (rectValue) in
                let charRect = rectValue.cgRectValue
                characterRects.append(charRect)
            }
            self.characterRects = characterRects
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
        //debugPrint("\(type(of: self)) is deallocated");
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
