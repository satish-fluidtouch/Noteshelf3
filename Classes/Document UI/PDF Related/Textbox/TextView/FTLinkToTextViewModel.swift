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
            str = "Page".localized
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
    case linkText
    case document
    case url

    var localizedString: String {
        let str: String
        switch self {
        case .linkText:
            str = "textLink_linktext".localized
        case .document:
            str = "Notebook".localized
        case .url:
            str = "URL"
        }
        return str
    }
}

let currentDocumentLinkingId: String = "SELF"

struct FTPageLinkInfo {
    private(set) var docUUID: String
    private(set) var pageUUID: String

    mutating func updateDocumentId(_ docId: String) {
        self.docUUID = docId
    }

    mutating func setCurrentDocumentId() {
        self.docUUID = currentDocumentLinkingId
    }

    mutating func updatePageId(_ pageId: String) {
        self.pageUUID = pageId
    }
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

    private var controllerToPresent: UIViewController? {
        return (self.delegate as? FTTextAnnotationViewController)?.presentedViewController
    }

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
        if nil != self.currentDocument, let page = self.currentPage {
            self.info.setCurrentDocumentId()
            self.info.updatePageId(page.uuid)
        }
    }

    private func handleNotAvailableDocument(for docID: String) {
        guard let controller = self.controllerToPresent else {
            return
        }
        FTTextLinkRouteHelper.handeDocumentUnAvailablity(for: docID, on: controller)
    }

    func updateTextLinkInfo(using doc: FTDocumentProtocol) {
        if doc.documentUUID == self.currentDocument?.documentUUID {
            self.info.setCurrentDocumentId()
        } else {
            self.info.updateDocumentId(doc.documentUUID)
        }
        if let firstPage = doc.pages().first {
            self.updatePageId(using: firstPage)
        }
    }
    
    func updatePageId(using page: FTPageProtocol) {
        self.info.updatePageId(page.uuid)
        self.pageNumber = page.pageIndex() + 1
    }

    func updateDocumentTitle(_ title: String) {
        self.docTitle = title
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
        if let doc = self.currentDocument,  info.docUUID == currentDocumentLinkingId {
            self.selectedDocument = doc
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: doc.documentUUID) { docItem in
                guard let shelfItem = docItem else {
                    self.handleNotAvailableDocument(for: doc.documentUUID)
                    return
                }
                self.updateDocumentTitle(shelfItem.displayTitle)
                let pages = doc.pages()
                if let page = pages.first(where: { $0.uuid == self.info.pageUUID }) {
                    self.updatePageId(using: page)
                } else if let firstPage = pages.first {
                    self.updatePageId(using: firstPage)
                }
                onCompletion?(true)
            }
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                guard let shelfItem = docItem else {
                    self.handleNotAvailableDocument(for: self.info.docUUID)
                    return
                }
                if let document = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTNoteshelfDocument {
                    if document.isPinEnabled(), let controller = self.controllerToPresent {
                        FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                                     onviewController: controller)
                        { (pin, success,_) in
                            if(success) {
                                prepareDetails(pin: pin)
                            }
                        }
                    } else {
                        prepareDetails(pin: nil)
                    }
                }

                func prepareDetails(pin: String?) {
                    self.updateDocumentTitle(shelfItem.displayTitle)
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    if let passcode = pin {
                        request.pin = passcode
                    }
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let doc = document {
                            self.selectedDocument = doc
                            self.token = token
                            let pages = doc.pages()
                            if let page = pages.first(where: { $0.uuid == self.info.pageUUID }) {
                                self.updatePageId(using: page)
                            } else if let firstPage = pages.first {
                                self.updatePageId(using: firstPage)
                            }
                            onCompletion?(true)
                        }
                    }
                }
            }
        }
    }

    func getSelectedDocumentDetails(using docId: String, onCompletion: ((FTDocumentProtocol?) -> Void)?) {
        if let document = self.currentDocument,  docId == document.documentUUID { // same document
            self.selectedDocument = document
            onCompletion?(document)
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: docId) { docItem in
                guard let shelfItem = docItem else {
                    self.handleNotAvailableDocument(for: docId)
                    return
                }
                if let document = FTDocumentFactory.documentForItemAtURL(shelfItem.URL) as? FTNoteshelfDocument {
                    if document.isPinEnabled(), let controller = self.controllerToPresent {
                        FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                                     onviewController: controller)
                        { (pin, success,_) in
                            if(success) {
                                prepareDetails(pin: pin)
                            }
                        }
                    } else {
                        prepareDetails(pin: nil)
                    }
                }

                func prepareDetails(pin: String?) {
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    if let passcode = pin {
                        request.pin = passcode
                    }
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

class FTTextLinkEventTracker: NSObject {
    static func trackEvent(with value: String, params: [String: Any]? = nil) {
        track(value, params: params,screenName: FTScreenNames.textbox)
    }
}

struct TextLinkEvents {
    static let linkToTap = "textbox_linkto_tap"
    static let selectedTextLinkToTap = "selectedtext_linkto_tap"
    static let linkToLinkTextType = "linkto_linktext_type"
    static let linkToNotebookTap = "linkto_notebook_tap"
    static let linkNotebookSelect = "link_notebook_select"
    static let linkToPageTap = "linkto_page_tap"
    static let linkToSegmentTap = "linkto_segment_tap"
    static let linkToURLType = "linkto_URL_type"
    static let linkToDoneTap = "linkto_done_tap"
    static let editLinkTap = "textbox_editlink_tap"
    static let removeLinkTap = "textbox_removelink_tap"
    static let pageLinkLongPress = "page_link_longpress"
    static let selectedTextEditLinkTap = "selectedtext_editlink_tap"
    static let selectedTextRemoveLinkTap = "selectedtext_removelink_tap"
}
