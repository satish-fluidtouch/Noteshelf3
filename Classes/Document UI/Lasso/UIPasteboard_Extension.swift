//
//  UIPasteboard_Extension.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 10/12/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private let FTPDFAnnotationUTI = "com.fluidTouch.noteshelf.annotation";
private let FTPDFShapeAnnotationUTI = "com.fluidTouch.noteshelf.shapeannotation";

extension UIPasteboard {
    class func pdfAnnotationUTI() -> String {
        return FTPDFAnnotationUTI
    }

    class func pdfShapeAnnotationUTI() -> String {
        return FTPDFShapeAnnotationUTI
    }

    class func canPasteShapeContent() -> Bool {
        var canPasteContent: Bool = false
        let pasteBoard = UIPasteboard.general
        let pbItems = pasteBoard.types
        guard !pbItems.isEmpty else {
            return canPasteContent
        }
        if pasteBoard.contains(pasteboardTypes:[UIPasteboard.pdfShapeAnnotationUTI()]) {
            canPasteContent = true
        }
        return canPasteContent
    }

    class func canPasteContent() -> Bool {
        let pasteBoard = UIPasteboard.general
        let pbItems = pasteBoard.types
        guard !pbItems.isEmpty else {
            return false
        }
        
        var canPasteContent: Bool = false
        
        if pasteBoard.hasStrings {
            canPasteContent = true
        } else if pasteBoard.hasImages {
            canPasteContent = true
        }
        
        if pasteBoard.contains(pasteboardTypes: [UIPasteboard.pdfAnnotationUTI(),UIPasteboard.pdfShapeAnnotationUTI()]) {
            canPasteContent = true
        }
        return canPasteContent
    }

    class func getContent() -> Any? {
        var content: Any?
        let pasteBoard = UIPasteboard.general

        if !UIPasteboard.canPasteContent() {
            content = nil
        } else if pasteBoard.contains(pasteboardTypes: [UIPasteboard.pdfAnnotationUTI()]),
            let data = pasteBoard.data(forPasteboardType: UIPasteboard.pdfAnnotationUTI()) {
            content = data
        } else if pasteBoard.contains(pasteboardTypes: [UIPasteboard.pdfShapeAnnotationUTI()]),
            let data = pasteBoard.data(forPasteboardType: UIPasteboard.pdfShapeAnnotationUTI()) {
            content = data
        } else if let image = pasteBoard.image {
            content = image
        } else if let str = pasteBoard.string {
            content = str
        }
        
        return content
    }
    
}
