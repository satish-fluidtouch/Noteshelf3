//
//  FTLinkToTextViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTLinkToTab: String {
    case page
    case url

    var localizedString: String {
        let str: String
        switch self {
        case .page:
            str = "Page"
        case .url:
            str = "URL"
        }
        return str
    }
}

enum FTLinkToOption: String, CaseIterable {
    case linkText = "Link Text"
    case document = "Notebook"
}

struct FTTextLinkInfo {
    var docUUID: String
    var pageUUID: String
    weak var currentDocument: FTDocumentProtocol?
}

protocol FTPageSelectionDelegate: AnyObject {
    func didSelect(page: FTNoteshelfPage)
}

protocol FTDocumentSelectionDelegate: AnyObject {
    func didSelect(document: FTShelfItemProtocol)
}

protocol FTTextLinkEditDelegate: AnyObject {
    func updateTextLinkInfo(_ info: FTTextLinkInfo)
    func removeLink()
}

class FTLinkToTextViewModel: NSObject {
    private var token: FTDocumentOpenToken?
    private(set) var info: FTTextLinkInfo
    private(set) weak var selectedDocument: FTDocumentProtocol?

    private(set) var linkText = ""
    private(set) var docTitle: String = ""
    private(set) var pageNumber: Int?

    weak var delegate: FTTextLinkEditDelegate?

    init(info: FTTextLinkInfo, linkText: String, delegate: FTTextLinkEditDelegate?) {
        self.info = info
        self.linkText = linkText
        self.delegate = delegate
    }

    func updateTextLinkInfo(_ info: FTTextLinkInfo) {
        self.info = info
    }

    func updateDocumentTitle(_ title: String) {
        self.docTitle = title
    }

    func updatePageNumber(_ number: Int) {
        self.pageNumber = number
    }

    func saveLinkInfo() {
        self.delegate?.updateTextLinkInfo(self.info)
    }

    func prepareDocumentDetails(onCompletion: ((Bool) -> Void)?) {
        if let doc = info.currentDocument,  info.docUUID == doc.documentUUID {
            self.selectedDocument = doc
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    self.updateDocumentTitle(shelfItem.displayTitle)
                    let pages = doc.pages()
                    if let pageIndex = pages.firstIndex(where: { $0.uuid == self.info.pageUUID }) {
                        self.updatePageNumber(pageIndex + 1)
                    } else {
                        self.updatePageNumber(1)
                        var updatedInfo = self.info
                        updatedInfo.pageUUID = pages.first?.uuid ?? ""
                        self.delegate?.updateTextLinkInfo(updatedInfo)
                    }
                    onCompletion?(true)
                }
            }
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    self.updateDocumentTitle(shelfItem.displayTitle)
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let doc = document {
                            self.selectedDocument = doc
                            self.token = token
                            let pages = doc.pages()
                            if let pageIndex = pages.firstIndex(where: { $0.uuid == self.info.pageUUID }) {
                                self.updatePageNumber(pageIndex + 1)
                            } else {
                                self.updatePageNumber(1)
                                var updatedInfo = self.info
                                updatedInfo.pageUUID = pages.first?.uuid ?? ""
                                self.delegate?.updateTextLinkInfo(updatedInfo)
                            }
                            onCompletion?(true)
                        }
                    }
                }
            }
        }
    }

    func getSelectedDocumentDetails(onCompletion: ((FTDocumentProtocol?) -> Void)?) {
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

    func closeOpenedDocumentIfNeeded() {
        // should not be closing if selected document and current document are same
        if let currentDoc = self.info.currentDocument, let selDoc = self.selectedDocument, currentDoc.documentUUID != selDoc.documentUUID, let token = self.token {
            FTNoteshelfDocumentManager.shared.closeDocument(document: selDoc, token: token, onCompletion: nil)
        }
    }
}
