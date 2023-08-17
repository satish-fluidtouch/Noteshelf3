//
//  FTPDFOutline.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

/*           Container
            (Root level nodes are just containers, never be used to display OR search purpose)
             |---FTPDFOutline(✖)-|PDFOutline(✔) - Children[PDFOutline(✔)]
             (PDF-1)             |PDFOutline(✔) - Children[PDFOutline(✔)]
                                 |PDFOutline(✔) - Children[PDFOutline(✔)]
 
             |---FTPDFOutline(✖)-|PDFOutline(✔) - Children[PDFOutline(✔)]
             (PDF-2)             |PDFOutline(✔) - Children[PDFOutline(✔)]
                                 |PDFOutline(✔) - Children[PDFOutline(✔)]
 
             The real outlines data is from second level.
 */

class FTPDFOutlineContainer: NSObject {
    var pdfFileNames: [String] = [String]()
    var pdfOutlineRoots: [FTPDFOutline] = [FTPDFOutline]()
}

class FTPDFOutline: NSObject {
    var pdfOutline: PDFOutline!
    weak var page: FTPageProtocol?
    weak var parent: FTPDFOutline?
    var children: [FTPDFOutline] = [FTPDFOutline]()
    
    var title: String {
        get{
           return pdfOutline.label ?? ""
        }
    }
    var isOpen: Bool {
        get{
            return pdfOutline.isOpen
        }
        set{
            pdfOutline.isOpen = newValue
        }
    }
    var hasChildren: Bool {
        return pdfOutline.numberOfChildren > 0
    }
    var pageNumberInPdf: Int{
        if let pageRef = self.pdfOutline.destination?.page, let pdfDoc = self.pdfOutline.document {
            let pageNumber = pdfDoc.index(for: pageRef)
            return pageNumber
        }
        return -1
    }
    var pageNumberInNotebook: String?{
        if let currentPage = page {
            return "p. \(currentPage.pageIndex() + 1)"
        }
        return ""
    }
    
    
    func addChild(_ child: FTPDFOutline){
        self.children.append(child)
    }
}
