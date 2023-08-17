//
//  FTPDFOutlinesManager.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 27/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPDFOutlinesManager: NSObject {
    private var outlineContainer: FTPDFOutlineContainer = FTPDFOutlineContainer()
    
    lazy var notebookOutlines: [FTPDFOutline] = {
        var allOutlines: [FTPDFOutline] = [FTPDFOutline]()
        self.outlineContainer.pdfOutlineRoots.forEach { (eachRootOutline) in
            allOutlines.append(contentsOf: eachRootOutline.children)
        }
        return allOutlines
    }()
    
    func processPage(_ page: FTPageProtocol){
        if let pdfFileName = page.associatedPDFFileName{
            if let pdfDoc = page.pdfPageRef?.document {
                if(outlineContainer.pdfFileNames.contains(pdfFileName) == false){
                    if let outline = self.tableOfContents(for: pdfDoc){
                        outlineContainer.pdfFileNames.append(pdfFileName)
                        outlineContainer.pdfOutlineRoots.append(outline)
                    }
                }
            }
            
            if let index = outlineContainer.pdfFileNames.firstIndex(of: pdfFileName) {
                let pdfOutlineRoot = outlineContainer.pdfOutlineRoots[index]
                if(pdfOutlineRoot.children.count > 0){
                    for i in (0..<pdfOutlineRoot.children.count){
                        let eachOutline = pdfOutlineRoot.children[i]
                        self.assignAssociatedPage(to: eachOutline, currentPage: page)
                    }
                }
            }
        }
    }
    func outlinesWithSearchText(_ searchKey: String)->[FTPDFOutline]{
        let key: String = searchKey.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
        if key.count == 0{
            return self.notebookOutlines
        }
        var resultOutlines = [FTPDFOutline]()
        self.notebookOutlines.forEach { (outline) in
            if outline.page != nil && outline.title.lowercased().contains(key){
                resultOutlines.append(outline)
            }
            resultOutlines.append(contentsOf: self.matchingChildren(with: key, parentOutline: outline))
        }
        return resultOutlines
    }
}
extension FTPDFOutlinesManager {
    fileprivate func assignAssociatedPage(to outline: FTPDFOutline, currentPage: FTPageProtocol?){
        if let page = currentPage {
            let pageNumber = outline.pageNumberInPdf
            if pageNumber == page.associatedPDFKitPageIndex {
                outline.page = page
            }
        }
        if(outline.children.count > 0){
            for i in (0..<outline.children.count){
                let eachOutline = outline.children[i]
                self.assignAssociatedPage(to: eachOutline, currentPage: currentPage)
            }
        }
    }
    fileprivate func tableOfContents(for document: PDFDocument) -> FTPDFOutline?{
        //Load all outlines recursively in tree structure
        var mainOutline: FTPDFOutline?
        
        if let root = document.outlineRoot {
            if root.numberOfChildren > 0{
                mainOutline = FTPDFOutline()
                mainOutline?.pdfOutline = root
                mainOutline?.isOpen = false
                
                for i in (0..<root.numberOfChildren){
                    if let child = root.child(at: i){
                        let childOutline = self.buildChild(with: child)
                        mainOutline?.addChild(childOutline)
                    }
                }
                
            }
        }
        return mainOutline
    }
    
    fileprivate func buildChild(with pdfOutline: PDFOutline) -> FTPDFOutline {
        let outline: FTPDFOutline = FTPDFOutline()
        outline.pdfOutline = pdfOutline
        outline.isOpen = false
        
        if pdfOutline.numberOfChildren > 0{
            for i in (0..<pdfOutline.numberOfChildren){
                if let child = pdfOutline.child(at: i){
                    let childOutline = self.buildChild(with: child)
                    childOutline.parent = outline
                    outline.addChild(childOutline)
                }
            }
        }
        return outline
    }
    fileprivate func matchingChildren(with searchKey: String, parentOutline: FTPDFOutline) -> [FTPDFOutline]{
        var resultOutlines = [FTPDFOutline]()
        if parentOutline.children.count > 0{
            parentOutline.children.forEach { (child) in
                if child.page != nil && child.title.lowercased().contains(searchKey){
                    resultOutlines.append(child)
                }
                resultOutlines.append(contentsOf: self.matchingChildren(with: searchKey, parentOutline: child))
            }
        }
        
        return resultOutlines
    }
}
