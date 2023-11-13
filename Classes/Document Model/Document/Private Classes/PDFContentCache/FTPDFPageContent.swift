//
//  FTPDFPageContent.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 25/10/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPDFPageContent: NSObject,NSSecureCoding {
    private(set) var pdfContent: String = "";
    private var characterRects = [CGRect]();
    
    required override init() {
        super.init();
    }
    
    static var supportsSecureCoding: Bool = true;
    
    init(pdfContent: String, charRects: [CGRect]) {
        super.init();
        self.pdfContent = pdfContent;
        self.characterRects = charRects;
    }
    
    required init?(coder: NSCoder) {
        super.init();
        if let stringValue = coder.decodeObject(forKey: "contnet") as? String {
            self.pdfContent = stringValue;
        }
        if let values = coder.decodeObject(forKey: "charRect") as? [CGRect] {
            self.characterRects = values;
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.pdfContent, forKey: "contnet");
        coder.encode(self.characterRects, forKey: "charRect");
    }
        
    func ranges(for searchKey: String) -> [CGRect] {
        let pdfString = pdfContent.lowercased();
        let lowerSearchKey = searchKey.lowercased();
        let ranges = pdfString.ranges(of:lowerSearchKey);
        var rectsToReturn = [CGRect]();
        if !ranges.isEmpty {
            let charRects = self.characterRects;
            let searchkeyLength = lowerSearchKey.count;
            for eachRange in ranges {
                let nsRange = NSRange(eachRange, in: pdfString);
                let index = nsRange.location;
                var rect = CGRect.null
                for i in 0..<searchkeyLength {
                    rect = rect.union(charRects[index + i]);
                }
                if !rect.isNull {
                    rectsToReturn.append(rect);
                }
            }
        }
        return rectsToReturn;
    }
}
