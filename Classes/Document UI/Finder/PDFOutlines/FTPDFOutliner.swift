//
//  FTPDFOutliner.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 27/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTOutlineLoadingState: Int {
    case none
    case inProgress
    case finished
}

class FTPDFOutliner: NSObject {
    fileprivate var loadingState: FTOutlineLoadingState = .none
    fileprivate var completionBlock: (([FTPDFOutline]) -> (Void))?
    fileprivate var searchCompletionBlock: (([FTPDFOutline]) -> (Void))?
    
    weak var currentDocument: FTNoteshelfDocument?
    private var outlineContainer: FTPDFOutlineContainer = FTPDFOutlineContainer()
   
    convenience init(withDocument document:FTNoteshelfDocument?){
        self.init()
        self.currentDocument = document
    }
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    lazy var notebookOutlines: [FTPDFOutline] = {
        objc_sync_enter(self);
        var allOutlines: [FTPDFOutline] = [FTPDFOutline]()
        self.outlineContainer.pdfOutlineRoots.forEach { (eachRootOutline) in
            allOutlines.append(contentsOf: eachRootOutline.children)
        }
        objc_sync_exit(self);
        return allOutlines
    }()
    
    func outlinesWithSearchText(_ searchKey: String, onCompletion: (([FTPDFOutline]) -> (Void))?){

        if !searchKey.isEmpty {
            self.searchCompletionBlock = onCompletion
        }
        else{
            self.completionBlock = onCompletion
        }
        if(self.loadingState == .inProgress){
            return
        }
        DispatchQueue.global().async {
            //***********************************
            if self.loadingState == .none {
                self.loadingState = .inProgress
                self.loadAllPDFOutlines()
                self.loadingState = .finished
                if searchKey.isEmpty {
                    self.completionBlock?(self.notebookOutlines)
                }
                else{
                    self.outlinesWithSearchText(searchKey, onCompletion: self.searchCompletionBlock)
                }
            }
            //***********************************
            else if self.loadingState == .finished {
                let key: String = searchKey.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
                if key.isEmpty {
                    self.completionBlock?(self.notebookOutlines)
                    return
                }
                var resultOutlines = [FTPDFOutline]()
                self.notebookOutlines.forEach { (outline) in
                    if outline.page != nil && outline.title.lowercased().contains(key){
                        resultOutlines.append(outline)
                    }
                    resultOutlines.append(contentsOf: self.matchingChildren(with: key, parentOutline: outline))
                }
                self.searchCompletionBlock?(resultOutlines)
            }
            //***********************************
        }

    }
    fileprivate func loadAllPDFOutlines(){
        self.currentDocument?.pages().forEach {[weak self] (page) in
            if let pdfFileName = page.associatedPDFFileName{
                if let weakSelf = self {
                    let pdfFileItem = weakSelf.currentDocument?.pdfFileItem(with: pdfFileName)
                    if(weakSelf.outlineContainer.pdfFileNames.contains(pdfFileName) == false){
                        let outline = pdfFileItem?.pdfTableOfContents()
                        if outline != nil{
                            weakSelf.outlineContainer.pdfFileNames.append(pdfFileName)
                            weakSelf.outlineContainer.pdfOutlineRoots.append(outline!)
                        }
                    }
                    
                    if let index = weakSelf.outlineContainer.pdfFileNames.firstIndex(of: pdfFileName) {
                        let pdfOutlineRoot = weakSelf.outlineContainer.pdfOutlineRoots[index]
                        if(!pdfOutlineRoot.children.isEmpty){
                            for i in (0..<pdfOutlineRoot.children.count){
                                let eachOutline = pdfOutlineRoot.children[i]
                                weakSelf.assignAssociatedPage(to: eachOutline, currentPage: page)
                            }
                        }
                    }
                }
            }
        }
    }
}

////======================Private Methods===========================
extension FTPDFOutliner {
    fileprivate func assignAssociatedPage(to outline: FTPDFOutline, currentPage: FTPageProtocol?){
        if let page = currentPage {
            let pageNumber = outline.pageNumberInPdf
            if pageNumber == page.associatedPDFKitPageIndex {
                outline.page = page
            }
        }
        if(!outline.children.isEmpty){
            for i in (0..<outline.children.count){
                let eachOutline = outline.children[i]
                self.assignAssociatedPage(to: eachOutline, currentPage: currentPage)
            }
        }
    }
    fileprivate func matchingChildren(with searchKey: String, parentOutline: FTPDFOutline) -> [FTPDFOutline]{
        var resultOutlines = [FTPDFOutline]()
        if !parentOutline.children.isEmpty{
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
//=================================================================
extension FTNoteshelfDocument {
    
    func pdfFileItem(with fileName: String) -> FTPDFKitFileItemPDF? {
        var pageTemplateFileItem: FTPDFKitFileItemPDF?
        objc_sync_enter(self);
        let tempalteFileName = fileName;
        let rawTempalteFileName = "rawenc-".appending(tempalteFileName);
        if(nil != pageTemplateFileItem && nil == pageTemplateFileItem!.parent) {
            pageTemplateFileItem = nil;
        }
        
        if((nil == pageTemplateFileItem) ||
            ((pageTemplateFileItem!.fileName != tempalteFileName) && (pageTemplateFileItem!.fileName != rawTempalteFileName))
            )
        {
            pageTemplateFileItem = self.templateFolderItem()?.childFileItem(withName: tempalteFileName) as? FTPDFKitFileItemPDF;
            if(nil == pageTemplateFileItem) {
                pageTemplateFileItem = self.templateFolderItem()?.childFileItem(withName: rawTempalteFileName) as? FTPDFKitFileItemPDF;
            }
        }
        objc_sync_exit(self);
        return pageTemplateFileItem
    }
}
//=================================================================
extension FTPDFKitFileItemPDF {
    func pdfTableOfContents() -> FTPDFOutline?{
        //Load all outlines recursively in tree structure
        var mainOutline: FTPDFOutline?
        if let root = self.pdfDocumentRef()?.outlineRoot {
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
}
//=================================================================
