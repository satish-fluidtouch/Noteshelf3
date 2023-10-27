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
    
    var contentType: FTSearchContentType {
        return .page
    }

    var title: String {
        return self.sectionHeaderItem?.displayTitle ?? ""
    }
    
    private(set) var items: [FTSearchResultProtocol] = [FTSearchResultBookProtocol]()
    private var associatedPages: [FTPageProtocol]?
    
    func associatedPage(forItem item : FTSearchResultPageProtocol) -> FTThumbnailable?
    {
        if nil != self.document {
            let index = self.items.firstIndex { (eachItem) -> Bool in
                return (eachItem.hash == item.hash);
            }
            
            if let ind = index,ind < associatedPages?.count ?? 0 {
                return associatedPages?[ind] as? FTThumbnailable;
            }
        }
        return nil;
    }
    
    weak var sectionHeaderItem: FTDiskItemProtocol?//FTShelfItem
    
    private var document: FTDocumentProtocol?;
    private var documentOpenToken: FTDocumentOpenToken = FTDocumentOpenToken();

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
                    self.documentOpenToken = token;
                    let allPages = self.document?.pages();
                    
                    var set = Set<String>();
                    self.items.forEach({ (eachItem) in
                        
                        if let gridItem = eachItem as? FTSearchResultPageProtocol,
                           let pageUUID = gridItem.searchingInfo?.pageUUID {
                            set.insert(pageUUID);
                        }
                    });
                    self.associatedPages = []
                    allPages?.forEach { (eachPage) in
                        if(set.contains(eachPage.uuid)) {
                            self.associatedPages?.append(eachPage);
                        }
                    };
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
            self.associatedPages = nil
            self.onStatusChange?(self, false)
        }
    }
}
