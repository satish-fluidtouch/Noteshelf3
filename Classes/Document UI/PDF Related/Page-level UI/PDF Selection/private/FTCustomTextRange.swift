//
//  FTCustomTextRange.swift
//  PDFView
//
//  Created by Amar on 26/05/21.
//

import UIKit

class FTCustomTextRange: UITextRange {
    /// The start offset of this range
    let startOffset: Int
    /// The end offset of this range
    let endOffset: Int
    
    /// Create a `CustomTextRange` with the given offsets
    /// - Parameters:
    ///   - startOffset: The start offset of this range
    ///   - endOffset: The end offset of this range
    init(startOffset: Int, endOffset: Int) {
        self.startOffset = startOffset
        self.endOffset = endOffset
        
        super.init()
    }
    
    // MARK: UITextRange Overrides
    
    override var isEmpty: Bool {
        return startOffset == endOffset
    }
    
    override var start: UITextPosition {
        return FTCustomTextPosition(offset: startOffset)
    }
    
    override var end: UITextPosition {
        return FTCustomTextPosition(offset: endOffset)
    }
    
    override var description: String {
        return "start: \(self.startOffset) end: \(self.endOffset)";
    }
    
    var range: NSRange {
        let start = self.startOffset;
        let end = self.endOffset;
        let length = end - start;
        let nsrange = NSRange(location: start, length: length);
        return nsrange;
    }
}
