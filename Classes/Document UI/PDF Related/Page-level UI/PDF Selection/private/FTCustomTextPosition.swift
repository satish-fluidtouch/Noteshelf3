//
//  FTCustomTextPosition.swift
//  PDFView
//
//  Created by Amar on 26/05/21.
//

import UIKit

class FTCustomTextPosition: UITextPosition {
    /// The offset from the start index of the text position
    let offset: Int
    
    /// An initializer for a CustomTextPosition that takes in an offset
    /// - Parameter offset: the offset from the start index of this text position
    init(offset: Int) {
        self.offset = offset
    }
}

extension FTCustomTextPosition: Comparable {
    static func < (lhs: FTCustomTextPosition, rhs: FTCustomTextPosition) -> Bool {
        lhs.offset < rhs.offset
    }
    
    static func <= (lhs: FTCustomTextPosition, rhs: FTCustomTextPosition) -> Bool {
        lhs.offset <= rhs.offset
    }

    static func >= (lhs: FTCustomTextPosition, rhs: FTCustomTextPosition) -> Bool {
        lhs.offset >= rhs.offset
    }

    static func > (lhs: FTCustomTextPosition, rhs: FTCustomTextPosition) -> Bool {
        lhs.offset > rhs.offset
    }

}
