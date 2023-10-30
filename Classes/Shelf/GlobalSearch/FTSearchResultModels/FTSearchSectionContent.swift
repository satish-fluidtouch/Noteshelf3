//
//  FTSearchSectionContent.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 05/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSearchSectionContent: NSObject, FTSearchSectionContentProtocol {
    var uuid = UUID().uuidString
    var searchKey: String = ""
    var onStatusChange: ((_ section: FTSearchSectionProtocol?, _ isActive: Bool) -> Void)?

    private var contentAccessCounter: Int = 0
    private var document: FTDocumentProtocol?
    private var documentOpenToken: FTDocumentOpenToken = FTDocumentOpenToken()
    private(set) var items: [FTSearchResultProtocol] = [FTSearchResultBookProtocol]()

    weak var sectionHeaderItem: FTDiskItemProtocol?//FTShelfItem

    var contentType: FTSearchContentType {
        return .page
    }

    var title: String {
        return self.sectionHeaderItem?.displayTitle ?? ""
    }

    func associatedPage(forItem item : FTSearchResultPageProtocol) -> FTThumbnailable? {
        var reqPage: FTThumbnailable?
        if let doc = self.document, let index = item.searchingInfo?.pageIndex {
            let pages = doc.pages()
            if index < pages.count {
                let page = pages[index]
                reqPage = page as? FTThumbnailable
                if nil == reqPage {
                    reqPage = pages.first(where: { $0.uuid == page.uuid }) as? FTThumbnailable
                }
            }
        }
        return reqPage
    }
    
    deinit {
        self.deactivate()
        #if DEBUG
        debugPrint("GLOBAL: deinit \(self.classForCoder)");
        #endif
    }
    
    func beginContentAccess(){
        if self.contentAccessCounter == 0 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivate), object: nil)
            self.activate()
        }
        self.contentAccessCounter += 1
    }
    
    func endContentAccess(){
        self.contentAccessCounter -= 1;
        if(self.contentAccessCounter < 0) {
            FTLogError("Counter -ve");
            self.contentAccessCounter = 0;
        }
        if self.contentAccessCounter == 0 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.deactivate), object: nil)
            self.perform(#selector(self.deactivate), with: nil, afterDelay: 0.5, inModes: [RunLoop.Mode.default])
        }
    }
    
    func addSearchItem(_ item: FTSearchResultPageProtocol){
        self.items.append(item)
    }
    
    @objc private func activate(){
        if self.document != nil{
            return
        }
        if let currentShelfItem = self.sectionHeaderItem {
            let openRequest = FTDocumentOpenRequest(url: currentShelfItem.URL, purpose: .read);
            FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { [weak self] (token, document, _) in
                if let notebook = document {
                    guard let `self` = self else {
                        FTNoteshelfDocumentManager.shared.closeDocument(document: notebook, token: token, onCompletion: nil);
                        return
                    }
                    self.document = notebook
                    self.documentOpenToken = token
                    self.onStatusChange?(self, true)
                }
            }
        }
    }
    
    @objc private func deactivate(){
        if let doc = self.document {
            FTNoteshelfDocumentManager.shared.closeDocument(document: doc,
                                                            token: self.documentOpenToken,
                                                            onCompletion: nil);
            self.document = nil
            self.onStatusChange?(self, false)
        }
    }
}
