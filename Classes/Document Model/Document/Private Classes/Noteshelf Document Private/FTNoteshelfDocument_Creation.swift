//
//  FTNoteshelfDocument_Creation.swift
//  Noteshelf
//
//  Created by Amar on 30/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTDocumentFramework
import FTCommon

enum FTPageInsertPostion : Int
{
    case none
    case inBetween
    case nextToCurrent
    case atTheEnd
}

extension FTNoteshelfDocument
{
    //MARK:- Insert PDF File -
    internal func insertFileFromInfo(_ info : FTDocumentInputInfo,
                                    onCompletion : @escaping ((Bool,NSError?) -> Void))
    {
        self.importFileWithInfo(info,
                                onCompletion: { (success, error) in
                                    DispatchQueue.main.async(execute: {
                                        if(nil != error) {
                                            onCompletion(success,error);
                                        }
                                        else {
                                            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                                            if info.overlayStyle != FTCoverStyle.default{
                                                self.shelfImage = self.transparentThumbnail(isEncrypted: info.isEnCrypted)
                                            }
                                            #endif
                                            self.saveDocument(completionHandler: { (success) in
                                                if(success) {
                                                    onCompletion(success,nil);
                                                }
                                                else {
                                                    onCompletion(success,FTDocumentCreateErrorCode.error(.saveFailed));
                                                }
                                            });
                                        }
                                    });
        });
    }
        
    internal func updatePageTemplateFromInfo(page : FTPageProtocol,
                                             info : FTDocumentInputInfo,
                                             onCompletion: @escaping ((NSError?, Bool) -> Void))
    {
        let themeURL = info.inputFileURL;
        if(themeURL?.pathExtension == nsBookExtension) {
            #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                self.updateTemplateFromNSTemplate(page : page,
                                                  info : info,
                                                  onCompletion: onCompletion);
            #endif
        }
        else {
            let blockToExecute : ((FTPDFKitFileItemPDF) -> Void) = { (fileItem) in
                page.associatedPDFPageIndex = 1;
                page.associatedPDFFileName = fileItem.fileName;
                page.resetRotation()
                
                page.lineHeight = info.pageProperties.lineHeight;
                page.bottomMargin = info.pageProperties.bottomMargin;
                page.topMargin = info.pageProperties.topMargin;
                page.leftMargin = info.pageProperties.leftMargin;

                page.pdfPageRect = fileItem.pageRectOfPage(atNumber: page.associatedPDFKitPageIndex);
                page.isCover = info.isCover
                DispatchQueue.main.async(execute: {
                    page.isDirty = true;
                    self.saveDocument(completionHandler: { (success) in
                        onCompletion(nil,true);
                    });
                });
            }

            FTCLSLog("Updating template: \(self.addressString)")
            self.copyInputFileToTemplateFolder(info: info) { (filePath, error) in
                if let _filePath = filePath {
                    blockToExecute(_filePath);
                }
                else {
                    FTCLSLog("Updating template failed: \(self.addressString) - \(error?.localizedDescription ?? "")")
                    onCompletion(error,false);
                }
            }
        }
    }
    
    fileprivate func importFileWithInfo(_ info : FTDocumentInputInfo,
                                         onCompletion : @escaping ((Bool,NSError?) ->Void))
    {
        FTCLSLog("import File: \(self.addressString)")
        self.copyInputFileToTemplateFolder(info: info) { (filePath, error) in
            if let _filePath = filePath {
                let error = self.startImporting(_filePath, info : info);
                onCompletion((error == nil) ? true : false,error);
            }
            else {
                FTCLSLog("import File failed: \(self.addressString) - \(error?.localizedDescription ?? "")")
                onCompletion(false,error);
            }
        }
    }
    
    fileprivate func askPasswordForDocument(_ url : Foundation.URL,
                                            viewController : UIViewController?,
                                        onCompletion:@escaping ((String?,NSError?) -> Void))
    {
        weak var textDidChangeoBbserver: NSObjectProtocol?;
        
        var password : String?
        let alertController = UIAlertController.init(title: NSLocalizedString("PasswordProtectedPDF", comment: "Password Protected PDF"), message: NSLocalizedString("EnterPassword", comment: "EnterPassword"), preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
            if let observer = textDidChangeoBbserver {
                NotificationCenter.default.removeObserver(observer);
            }
            onCompletion(password,FTDocumentCreateErrorCode.error(.cancelled))
        })
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { [weak alertController,weak self] _ in
            if let observer = textDidChangeoBbserver {
                NotificationCenter.default.removeObserver(observer);
            }
            if let weakAlertController = alertController {
                password = weakAlertController.textFields?.first?.text;
                if(FTNoteshelfDocument.decryptedDocumentAtURL(url, withPassword: password))
                {
                    onCompletion(password,nil);
                }
                else
                {
                    let alertVc = UIAlertController.init(title: "", message: NSLocalizedString("NotCorrectPassword", comment: "In correct password message"), preferredStyle: UIAlertController.Style.alert)
                    let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { [weak self] (_) in
                        self?.askPasswordForDocument(url,
                                                         viewController: viewController,
                                                         onCompletion: onCompletion)
                    })
                    alertVc.addAction(okAction)
                    viewController?.present(alertVc, animated: true, completion: nil)
                }
            }
        })
        
        okAction.isEnabled = false
        textDidChangeoBbserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alertController.textFields?.first, queue: OperationQueue.main) { [weak alertController, weak okAction]  _ in
            if let textField = alertController?.textFields?.first as? UITextField
                , let text = textField.text {
                okAction?.isEnabled =  !text.isEmpty
            }
        }
        alertController.addAction(okAction)
        
        alertController.addTextField { textField in
            textField.isSecureTextEntry = true
        };
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        viewController?.present(alertController, animated: true, completion: nil);
        #endif
    }
    
    fileprivate func startImporting(_ fileItem : FTPDFKitFileItemPDF, info : FTDocumentInputInfo) -> NSError?
    {
        let page = fileItem.pdfDocumentRef();
        var error : NSError?;
        
        if(nil == page) {
            error = FTDocumentCreateErrorCode.error(.failedToImport);
        }
        else {
            error = self.createPageEntities(page!,
                                            fileName: fileItem.fileName,
                                            index: info.insertAt,
                                            info : info);
        }
        return error;
    }
    
    fileprivate func createPageEntities(_ pdfDocument : PDFDocument,
                                        fileName : String,
                                        index : Int,
                                        info : FTDocumentInputInfo) -> NSError?
    {
        //This should never happen
        if (self.pages().count < index) {
            return FTDocumentCreateErrorCode.error(.pageIndexMismatch);
        }
        
        let count = pdfDocument.pageCount;
        if(count == 0) {
            return FTDocumentCreateErrorCode.error(.failedToImport);
        }
        
        guard let docInfoPlist = self.documentInfoPlist() else {
            return FTDocumentCreateErrorCode.error(.unexpectedError);
        }

        for i in 0..<count {
            autoreleasepool(invoking: {
                let page = FTNoteshelfPage.init(parentDocument: self);
                page.associatedPDFPageIndex = i+1;
                page.isCover = info.isCover
                page.associatedPDFFileName = fileName;
                
                page.lineHeight = info.pageProperties.lineHeight;
                page.bottomMargin = info.pageProperties.bottomMargin;
                page.topMargin = info.pageProperties.topMargin;
                page.leftMargin = info.pageProperties.leftMargin;

#if !NOTESHELF_ACTION
                if !info.isCover {
                    // To associate diary infomration to the Noteshelf page and set it as last viewed page index, to show the current date page when created and opened
                    if let diaryPagesInfo = info.diaryPagesInfo,
                       diaryPagesInfo.count == count {
                        let currentPageInfo = diaryPagesInfo[i]
                        page.diaryPageInfo = currentPageInfo
                        if currentPageInfo.isCurrentPage {
                            self.setLastViewedPageIndexTo(i+1) // as we have cover as first page in the notebook, adding + 1
                        }
                    }
                }
#endif

                if let bgColor = info.backgroundColor {
                    page.updateBackgroundColor(color: bgColor);
                }
                if let pdfPage = pdfDocument.page(at: i) {
                    var pageRect = pdfPage.bounds(for: PDFDisplayBox.cropBox);
                    let trasnform = pdfPage.transform(for: PDFDisplayBox.cropBox);
                    pageRect = pageRect.applying(trasnform);
                    pageRect.origin = CGPoint.zero;
                    page.pdfPageRect = pageRect;
                }
                if info.isCover  {
                    if i == 0 {
                        //We have two pdf pages for standard/custom cover, so insert only first page. Second page will be used to show thumnail on shelf.
                        docInfoPlist.insertPage(page,atIndex:i+index);
                    }
                } else {
                    docInfoPlist.insertPage(page,atIndex:i+index);
                }
            });
        }
        return nil;
    }
    
    fileprivate class func isPDFDocumentPasswordProtected(_ url : Foundation.URL) -> Bool
    {
        var requiresPassword = false;
        let theURL = url as CFURL;
        
        let pdfDocRef = PDFDocument.init(url: theURL as URL);
        if (pdfDocRef != nil)
        {
            if(pdfDocRef!.isEncrypted == true)
            {
                // Try a blank password first, per Apple's Quartz PDF example
                if(pdfDocRef!.unlock(withPassword: "") == false)
                {
                    // Nope, now let's try the provided password to unlock the PDF
                    requiresPassword = true;
                }
            }
        }
        return requiresPassword;
    }

    fileprivate class func decryptedDocumentAtURL(_ url : Foundation.URL, withPassword password:String?) -> Bool
    {
        var isValidPassword = false;
        let theURL = url as CFURL;
        
        let thePDFDocRef = PDFDocument.init(url: theURL as URL);
        if(thePDFDocRef != nil)
        {
            if(FTNoteshelfDocument.isPDFDocumentPasswordProtected(url))
            {
                if ((password != nil) && (password!.count > 0)) // Not blank?
                {
                    if(thePDFDocRef!.unlock(withPassword: password!) == true)
                    {
                        isValidPassword = true;
                    }
                }
            }
        }
        return isValidPassword;
    }

}

private extension FTNoteshelfDocument {
    private func copyInputFileToTemplateFolder(info: FTDocumentInputInfo, onCompletion: @escaping (FTPDFKitFileItemPDF?,NSError?)->()) {
        guard let inputFilePath = info.inputFileURL else {
            onCompletion (nil,FTDocumentCreateErrorCode.error(.failedToImport));
            return;
        }
        
        func generateFileItem(_ password:String?) {
            var fileItem: FTFileItemPDFTemp?;
            var _error: NSError?;
            do {
                let url = try self.copyFileToTempLocation(inputFilePath, isTemplate: info.isTemplate);
                let docName = url.lastPathComponent;

                fileItem = FTFileItemPDFTemp.init(fileName: docName, isDirectory: false)
                fileItem?.setSourceFileURL(url);
                fileItem?.documentPassword = password;
                fileItem?.securityDelegate = self;
                self.templateFolderItem()!.addChildItem(fileItem);
                
                self.propertyInfoPlist()?.setObject(DOC_VERSION as AnyObject, forKey: DOCUMENT_VERSION_KEY);
                
                let templateInfo = FTTemplateInfo(documentInfo: info)
                templateInfo.password = password;
                self.setTemplateValues(docName, values:templateInfo);
            }
            catch {
                _error  = error as NSError
            }
            onCompletion(fileItem,_error);
        }
        
        if(FTNoteshelfDocument.isPDFDocumentPasswordProtected(inputFilePath)) {
            runInMainThread {
                self.askPasswordForDocument(inputFilePath,
                                            viewController: info.rootViewController,
                                            onCompletion: { (password, error) in
                    if(nil == error) {
                        generateFileItem(password)
                    }
                    else {
                        onCompletion(nil,error);
                    }
                });
            };
        }
        else {
            generateFileItem(nil)
        }
    }
    
    func copyFileToTempLocation(_ inputFilePath: URL, isTemplate: Bool) throws -> URL {
        guard let tempPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
            throw FTDocumentCreateErrorCode.error(.failedToImport);
        }
        
        let fileManager = FileManager();
        
        let docName = FTUtils.getUUID().appending(".\(nsPDFExtension)");
        let tempFilePath = Foundation.URL(filePath:tempPath).appending(path: docName);
        try? fileManager.removeItem(at: tempFilePath);
      
        if(isTemplate) {
            _ = try fileManager.copyItem(at: inputFilePath, to: tempFilePath);
        }
        else {
            #if targetEnvironment(macCatalyst)
            _ = try fileManager.copyItem(at: inputFilePath, to: tempFilePath);
            #else
            _ = try fileManager.moveItem(at: inputFilePath, to: tempFilePath);
            #endif
        }
        return tempFilePath;
    }
}
