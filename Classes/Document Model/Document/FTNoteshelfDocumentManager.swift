//
//  FTNoteshelfDocumentManager.swift
//  Noteshelf
//
//  Created by Amar on 11/11/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

typealias FTocumentCloseCallBack = (Bool)->();
typealias FTDocumentOpenCallBack = ((FTDocumentOpenToken,FTDocumentProtocol?,Error?)->());

@objcMembers class FTDocumentOpenToken: NSObject {
    var token = UUID().uuidString;
    private(set) var purpose = FTDocumentOpenPurpose.read;
    
    convenience init(purpose: FTDocumentOpenPurpose) {
        self.init();
        self.purpose = purpose;
    }
}

@objcMembers class FTNoteshelfDocumentManager: NSObject {
    static let shared = FTNoteshelfDocumentManager();
    private override init() {}

    private var documentsInUse = [FTDocumentTokenInfo]();
    private var requestQueue = [FTDocumentOpenRequest]();
    private var currentRequest: FTDocumentOpenRequest?;

    func openDocument(request:FTDocumentOpenRequest,onCmmpletion : @escaping FTDocumentOpenCallBack) {
        request.onCompletion = onCmmpletion;
        if(request.purpose == .read) {
            self.processDocumentReadRequest(request);
        }
        else {
            self.requestQueue.append(request);
            if nil == self.currentRequest {
                DispatchQueue.main.async {
                    self.processDocumentWriteRequest();
                }
            }
        }
    }
        
    func closeDocument(document:FTDocumentProtocol,
                       token:FTDocumentOpenToken,
                       onCompletion: FTocumentCloseCallBack?) {
        if token.purpose == .write,
           let storedToken = self.token(for: document.URL) {
            if storedToken.removeToken(token) {
                if(storedToken.canClose) {
                    storedToken.document?.closeDocument(completionHandler: { success in
                        // cache the document if required.
                       FTDocumentCache.shared.cacheShelfItemFor(url: document.URL, documentUUID: document.documentUUID)
                        onCompletion?(success)
                    })
                    if let index = self.documentsInUse.firstIndex(of: storedToken) {
                        self.documentsInUse.remove(at: index);
                    }
                }
                else {
                    onCompletion?(true);
                }
            }
        }
        else {
            (document as? FTDocumentProtocolInternal)?.closeDocument(completionHandler: onCompletion);
        }
    }
    
    func saveAndClose(document:FTDocumentProtocol,
                      token:FTDocumentOpenToken,
                      onCompletion: FTocumentCloseCallBack?) {
        (document as? FTDocumentProtocolInternal)?.prepareForClosing();
        document.saveDocument { (saveSuccess) in
            if(saveSuccess) {
                self.closeDocument(document: document,
                                   token: token,
                                   onCompletion: onCompletion);
            }
            else {
                onCompletion?(saveSuccess);
            }
        }
    }

    func isDocumentAlreadyOpen(for url: URL) -> Bool {
        let isAlredyOpen = self.documentsInUse.contains(where: { docInUse in
            if let doc = docInUse.document, doc.URL == url {
                return true
            } else {
                return false
            }
        })

        return isAlredyOpen
    }
    
    func isDocumentOpen(for documentUUID: String) -> Bool {
        let isAlredyOpen = self.documentsInUse.contains(where: { docInUse in
            if let doc = docInUse.document, doc.documentUUID == documentUUID {
                return true
            } else {
                return false
            }
        })

        return isAlredyOpen
    }

}

private extension FTNoteshelfDocumentManager {
    private func processDocumentWriteRequest() {
        func _updateTokenFor(request: FTDocumentOpenRequest,
                             document: FTDocumentProtocolInternal?,
                             error : Error?) {
            var tokenID = FTDocumentOpenToken(purpose: request.purpose);
            if nil == error,let _doc = document {
                tokenID = self.registerToken(_doc, purpose: request.purpose);
            }
            request.onCompletion?(tokenID,document as? FTDocumentProtocol,error);
            self.currentRequest = nil;
            DispatchQueue.main.async {
                self.processDocumentWriteRequest();
            }
        }
        
        if !self.requestQueue.isEmpty,nil == self.currentRequest {
            let request = self.requestQueue.removeFirst();
            self.currentRequest = request;
            if let error = request.preprocessRequest() {
                _updateTokenFor(request: request, document: nil, error: error);
                return;
            }
            
            if let token = self.token(for: request.url), let document = token.document {
                _updateTokenFor(request: request,
                                document: document,
                                error: nil);
            }
            else {
                request.executeRequest { (document, error) in
                    _updateTokenFor(request: request,
                                    document: document as? FTDocumentProtocolInternal,
                                    error: error);
                }
            }
        }
    }
                
    func processDocumentReadRequest(_ request: FTDocumentOpenRequest) {
        let tokenID = FTDocumentOpenToken(purpose: request.purpose);
        if let error = request.preprocessRequest() {
            request.onCompletion?(tokenID,nil,error);
            return;
        }
        request.executeRequest { (document, error) in
            request.onCompletion?(tokenID,document,error);
        }
    }
    
    func token(for url:URL) -> FTDocumentTokenInfo? {
        let urlHash = url.urlByDeleteingPrivate().hashKey;
        let token = self.documentsInUse.first { (eachItem) -> Bool in
            return (eachItem.hashKey == urlHash);
        }
        return token;
    }
    
    func registerToken(_ document: FTDocumentProtocolInternal,purpose: FTDocumentOpenPurpose) -> FTDocumentOpenToken {
        var token = self.token(for: document.URL);
        if(nil == token) {
            let _token = FTDocumentTokenInfo();
            _token.document = document;
            self.documentsInUse.append(_token);
            token = _token;
        }
        guard let item = token else {
            fatalError("something problem");
        }
        let uuid = item.issueToken(purpose: purpose);
        return uuid;
    }
}

private class FTDocumentTokenInfo : NSObject {
    var tokens = [FTDocumentOpenToken]();
    var document: FTDocumentProtocolInternal?;
    private let uuid = UUID().uuidString;

    var canClose: Bool {
        return self.tokens.isEmpty;
    }

    var hashKey: String {
        return self.document?.URL.urlByDeleteingPrivate().hashKey ?? uuid;
    }
    
    @discardableResult func removeToken(_ token:FTDocumentOpenToken) -> Bool {
        if let index = self.tokens.index(of: token) {
            self.tokens.remove(at: index);
            return true;
        }
        return false;
    }
    
    func issueToken(purpose: FTDocumentOpenPurpose) -> FTDocumentOpenToken {
        let uuid = FTDocumentOpenToken(purpose: purpose);
        self.tokens.append(uuid);
        return uuid;
    }
}

@objcMembers class FTDocumentOpenRequest: NSObject {
    private(set) var url: URL;
    fileprivate var onCompletion: FTDocumentOpenCallBack?;
    private(set) var purpose = FTDocumentOpenPurpose.read;
    var pin: String?;
    
    init(url inUrl: URL,purpose: FTDocumentOpenPurpose) {
        self.url = inUrl;
        self.purpose = purpose;
    }
    
    fileprivate func preprocessRequest() -> Error? {
        if self.url.isPinEnabledForDocument(), (self.pin?.isEmpty ?? true) {
            return FTDocumentOpenErrorCode.error(.invalidPin);
        }
        return nil;
    }

    fileprivate func executeRequest(onCompletion:@escaping (FTDocumentProtocol?,Error?)->()) {
        let document = FTDocumentFactory.documentForItemAtURL(self.url);
        if document.documentState == UIDocument.State.inConflict {
            onCompletion(nil,FTDocumentOpenErrorCode.error(.inConflict));
        }
        else {
            guard let _document = document as? FTDocumentProtocolInternal else {
                fatalError("\(document) should implement FTDocumentProtocolInternal");
            }
            if let nsdocument = document as? FTDocument,nsdocument.isPinEnabled() {
                nsdocument.pin = self.pin;
            }
            _document.openDocument(purpose: self.purpose) { (uccess, error) in
                onCompletion(uccess ? document : nil,error);
            }
        }
    }
}
