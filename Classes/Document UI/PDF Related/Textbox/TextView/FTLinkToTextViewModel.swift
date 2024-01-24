//
//  FTLinkToTextViewModel.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTLinkToSegment: String {
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

    var options: [FTLinkToOption] {
        let options: [FTLinkToOption]
        switch self {
        case .page:
            options = [.linkText, .document]
        case .url:
            options = [.linkText, .url]
        }
        return options
    }
}

enum FTLinkToOption: String {
    case linkText = "Link Text"
    case document = "Notebook"
    case url = "URL"
}

struct FTPageLinkInfo {
    var docUUID: String
    var pageUUID: String
}

protocol FTPageSelectionDelegate: AnyObject {
    func didSelect(page: FTNoteshelfPage)
}

protocol FTDocumentSelectionDelegate: AnyObject {
    func didSelect(document: FTShelfItemProtocol)
}

protocol FTTextLinkEditDelegate: AnyObject {
    func updateTextLinkInfo(_ info: FTPageLinkInfo, text: String)
    func updateWebLink(_ url: URL, text: String)
}

class FTLinkToTextViewModel: NSObject {
    private var url: URL?
    private var token: FTDocumentOpenToken?
    private weak var currentPage: FTPageProtocol?
    private weak var currentDocument: FTDocumentProtocol? {
        return self.currentPage?.parentDocument
    }

    private(set) var linkText = ""
    private(set) var docTitle = ""
    private(set) var webUrlStr = ""
    private(set) var pageNumber: Int = 0
    private(set) var info = FTPageLinkInfo(docUUID: "", pageUUID: "")
    private(set) weak var selectedDocument: FTDocumentProtocol?

    weak var delegate: FTTextLinkEditDelegate?

    init(linkText: String, url: URL?, currentPage: FTPageProtocol, delegate: FTTextLinkEditDelegate?) {
        super.init()
        self.linkText = linkText
        self.url = url
        self.delegate = delegate
        self.currentPage = currentPage
        self.configPageLinkInfo()
    }

    private func configPageLinkInfo() {
        if let schemeUrl = self.url { // when url is already available
            if FTTextLinkRouteHelper.checkIfURLisAppLink(schemeUrl), let documentId = FTTextLinkRouteHelper.getQueryItems(of: schemeUrl).docId, let pageId = FTTextLinkRouteHelper.getQueryItems(of: schemeUrl).pageId {
                self.info = FTPageLinkInfo(docUUID: documentId, pageUUID: pageId)
                return
            } else {
                self.webUrlStr = schemeUrl.absoluteString
            }
        }
        if let doc = self.currentDocument, let page = self.currentPage {
            self.info = FTPageLinkInfo(docUUID: doc.documentUUID, pageUUID: page.uuid)
        }
    }

    func updateTextLinkInfo(_ info: FTPageLinkInfo) {
        self.info = info
    }

    func updateDocumentTitle(_ title: String) {
        self.docTitle = title
    }

    func updatePageNumber(_ number: Int) {
        self.pageNumber = number
    }

    func updateLinkText(_ text: String?) {
        self.linkText = text ?? ""
    }

    func updateWebUrlString(_ urlStr: String?) {
        self.webUrlStr = urlStr ?? ""
    }

    func saveLinkInfo(isWebLink: Bool = false) {
        if isWebLink {
            if let urlStr = URL(string: self.webUrlStr) {
                self.delegate?.updateWebLink(urlStr, text: self.linkText)
            }
        } else {
            self.delegate?.updateTextLinkInfo(self.info, text: self.linkText)
        }
    }

    func prepareDocumentDetails(onCompletion: ((Bool) -> Void)?) {
        if let doc = self.currentDocument,  info.docUUID == doc.documentUUID {
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
                            }
                            onCompletion?(true)
                        }
                    }
                }
            }
        }
    }

    func getSelectedDocumentDetails(onCompletion: ((FTDocumentProtocol?) -> Void)?) {
        if let document = self.currentDocument,  info.docUUID == document.documentUUID { // same document
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

    func closeOpenedDocumentIfExists() {
        // should not be closing if selected document and current document are same
        if let currentDoc = self.currentDocument, let selDoc = self.selectedDocument, currentDoc.documentUUID != selDoc.documentUUID, let token = self.token {
            FTNoteshelfDocumentManager.shared.closeDocument(document: selDoc, token: token, onCompletion: nil)
        }
    }
}
