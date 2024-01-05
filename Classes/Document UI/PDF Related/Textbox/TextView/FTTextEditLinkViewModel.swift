//
//  FTTextEditLinkViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 05/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTTextEditLinkViewModel: NSObject {
    private(set) var docTitle: String?
    private(set) var pageNumber: Int?
    private(set) weak var selectedDocument: FTDocumentProtocol?
    
    private var token: FTDocumentOpenToken?
    weak var infoDelegate: FTTextLinkInfoDelegate?

    init(delegate: FTTextLinkInfoDelegate?) {
        self.infoDelegate = delegate
    }
    
    func getExistingTextLinkInfo() -> FTTextLinkInfo? {
        guard let info = self.infoDelegate?.getTextLinkInfo() else {
            return nil
        }
        return info
    }
    
    func updateTextLinkInfo(_ info: FTTextLinkInfo) {
        self.infoDelegate?.updateTextLinkInfo(info)
    }
    
    func removeLink() {
        self.infoDelegate?.removeLink()
    }
    
    func updateDocumentTitle(_ title: String) {
        self.docTitle = title
    }
    
    func updatePageNumber(_ number: Int) {
        self.pageNumber = number
    }
    
    func closeOpenedDocumentIfNeeded() {
        // should not be closing if selected document and current document are same
        if let info = self.getExistingTextLinkInfo(), let currentDoc = info.currentDocument, let selDoc = self.selectedDocument, currentDoc.documentUUID != selDoc.documentUUID, let token = self.token {
            FTNoteshelfDocumentManager.shared.closeDocument(document: selDoc, token: token, onCompletion: nil)
        }
    }
    
    func getDocumentDetails(onCompletion: ((FTDocumentProtocol?) -> Void)?) {
        guard let info = self.getExistingTextLinkInfo() else {
            onCompletion?(nil)
            return
        }
        if let document = info.currentDocument,  info.docUUID == document.documentUUID { // same document
            self.selectedDocument = document
            onCompletion?(document)
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        self.selectedDocument = document
                        self.token = token
                        onCompletion?(document)
                    }
                }
            }
        }
    }
    
    func prepareDocumentDetails(onCompletion: ((Bool) -> Void)?) {
        guard let info = self.getExistingTextLinkInfo() else {
            onCompletion?(false)
            return
        }
        if let doc = info.currentDocument,  info.docUUID == doc.documentUUID {
            self.selectedDocument = doc
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    self.docTitle = shelfItem.displayTitle
                    let pages = doc.pages()
                    if let pageIndex = pages.firstIndex(where: { $0.uuid == info.pageUUID }) {
                        self.pageNumber = pageIndex + 1
                    } else {
                        self.pageNumber = 1
                        var updatedInfo = info
                        updatedInfo.pageUUID = pages.first?.uuid ?? ""
                        self.infoDelegate?.updateTextLinkInfo(updatedInfo)
                    }
                    onCompletion?(true)
                }
            }
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let doc = document {
                            self.selectedDocument = doc
                            self.token = token
                            self.docTitle = shelfItem.displayTitle
                            let pages = doc.pages()
                            if let pageIndex = pages.firstIndex(where: { $0.uuid == info.pageUUID }) {
                                self.pageNumber = pageIndex + 1
                            } else {
                                self.pageNumber = 1
                                var updatedInfo = info
                                updatedInfo.pageUUID = pages.first?.uuid ?? ""
                                self.infoDelegate?.updateTextLinkInfo(updatedInfo)
                            }
                            onCompletion?(true)
                        }
                    }
                }
            }
        }
    }
}
