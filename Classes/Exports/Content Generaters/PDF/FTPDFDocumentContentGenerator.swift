//
//  FTPDFDocumentContentGenerator.swift
//  Noteshelf
//
//  Created by Siva on 23/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTPDFDocumentContentGenerator: FTExportContentGenerator {
    private var notebook : FTDocumentProtocol?;
    private var documentToken: FTDocumentOpenToken = FTDocumentOpenToken();
    
    internal var _pinRequestCompletionBLock:((String?, Bool,Bool) -> Void)?
    internal var pinRequestCompletionBLock: ((String?, Bool) -> Void)?; //not used
    internal var pagesToExport : [FTPageProtocol]!;
    
    override func resumeProcess() {
        if(self.exportPaused) {
            DispatchQueue.global().async {
                if let completionHandler = self.internalCompletionHandler {
                    self.generateContent(forItem: self.currentItem!, onCompletion: completionHandler)
                }
            };
        }
    }
    //MARK:- CommonMethods
    func pageRectForPDFPage(_ page: FTPageProtocol, scale: inout CGFloat) -> CGRect
    {
        var rect = CGRect.zero;
        rect.size = page.pageReferenceViewSize();
        
        let pageRect = page.pdfPageRect;
        let normalWidth = rect.size.width;
        scale = normalWidth / pageRect.size.width;

        return rect.integral;
    }

    internal func pageName() -> String
    {
        let fileName = String(format: "%@ P%lu", self.preferedFileName, self.progress.completedUnitCount + 1);
        return fileName;
    }
    
    internal func localFilePathWithExtension() -> String {
        var cacheDirectory = self.temporaryCacheLocation();
        let fileName: String;
        if self.target.properties.exportFormat == kExportFormatImage {
            cacheDirectory = self.localFolderPath();
            fileName = self.pageName()
        }
        else {
            fileName = self.preferedFileName;
            
        }
        let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent(fileName).appendingPathExtension(self.target.properties.exportFormat.filePathExtension());
        return url.path;
    }
    
    internal func localFolderPath() -> String
    {
        let cacheDirectory = self.temporaryCacheLocation();
        let fileName = self.preferedFileName;
        let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent(fileName);
        return url.path;
    }
    
    fileprivate func temporaryCacheLocation() -> String
    {
        var tempFileLoc = "";
        if let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last {
            let url = URL(fileURLWithPath: cacheDirectory).appendingPathComponent("TEMP_CACHE_DIR");
            tempFileLoc = url.path;
            var isDir : ObjCBool = false;
            if FileManager.default.fileExists(atPath: tempFileLoc, isDirectory: &isDir) == false || !isDir.boolValue
            {
                do {
                    try FileManager.default.createDirectory(atPath: tempFileLoc, withIntermediateDirectories: true, attributes:nil);
                }
                catch {
                    
                }
            }
        }
        return tempFileLoc;
    }
    
    internal func finalizeProcess()
    {
        if let doc = self.notebook {
            FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: self.documentToken, onCompletion: nil);
        }
        self.notebook = nil;
        self.pagesToExport = nil;
        self.internalCompletionHandler = nil;
    }
    
    internal func preprocessGeneration(_ handler : @escaping (NSError?) -> Void)
    {
        if(nil != self.pagesToExport) {
            handler(nil);
            return;
        }
        
        self.pagesToExport = [FTPageProtocol]();
        
        func openDocumentAndAccessPages(_ url: URL,pin: String?) {
            let openRequest = FTDocumentOpenRequest(url: url, purpose: .read);
            openRequest.pin = pin;
            FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, error) in
                DispatchQueue.global().async {
                    if let doc = document {
                        self.notebook = doc;
                        self.documentToken = token;
                        self.pagesToExport = self.notebook!.pages();
                        handler(nil);
                    }
                    else {
                        handler(NSError.init(domain: "NSExport", code: 101, userInfo: nil));
                    }
                }
            }
        }
        
        if let exportPages = self.target.pages,!exportPages.isEmpty {
            self.pagesToExport = exportPages;
            handler(nil);
            return;
        }
        
        if let shelfItem = self.currentItem?.shelfItem {
            let url = shelfItem.URL;
            if true == url.isPinEnabledForDocument() {
                guard let visibleController = self.presentingController else {
                    handler(NSError.init(domain: "NSExport", code: 101, userInfo: nil));
                    return;
                }
                DispatchQueue.main.async {
                    FTDocumentPasswordValidate.validateShelfItem(shelfItem: shelfItem,
                                                                 onviewController: visibleController)
                    { (pin, success,cancelled) in
                        if(success) {
                            DispatchQueue.global().async {
                                openDocumentAndAccessPages(url, pin: pin);
                            }
                        }
                        else {
                            let error: NSError
                            if cancelled {
                                error = NSError.exportCancelError();
                            }
                            else {
                                error = NSError(domain: "NSExport", code: 101, userInfo: nil);
                            }
                            handler(error);
                        }
                    }                    
                }
            }
            else {
                openDocumentAndAccessPages(url, pin: nil);
            }
        }
        else {
            handler(NSError.init(domain: "NSExport", code: 101, userInfo: nil));
        }
    }
}
