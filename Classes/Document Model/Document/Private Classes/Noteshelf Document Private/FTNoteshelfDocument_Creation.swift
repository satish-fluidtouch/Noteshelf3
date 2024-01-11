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
            let docName = FTUtils.getUUID().appending(".\(nsPDFExtension)");
            let destinationURL = self.templateFolderItem()!.fileItemURL.appendingPathComponent(docName);
            
            let blockToExecute : ((URL,String?) -> Void) = { (writeURL, password) in
                do {
                    _ = try FileManager.default.copyItem(at: info.inputFileURL!, to: writeURL);
                    self.propertyInfoPlist()?.setObject(DOC_VERSION as AnyObject, forKey: DOCUMENT_VERSION_KEY);
                    
                    let docName = writeURL.lastPathComponent;
                    let templateInfo = FTTemplateInfo(documentInfo: info)
                    templateInfo.password = password;
                    self.setTemplateValues(docName, values:templateInfo);

                    var fileItem = self.templateFolderItem()!.childFileItem(withName: docName) as? FTPDFKitFileItemPDF;
                    if(nil == fileItem)
                    {
                        fileItem = FTPDFKitFileItemPDF.init(fileName: docName, isDirectory: false)
                        fileItem?.documentPassword = password;
                        fileItem?.securityDelegate = self;
                        self.templateFolderItem()!.addChildItem(fileItem);
                    }
                    
                    page.associatedPDFPageIndex = 1;
                    page.associatedPDFFileName = docName;
                    page.resetRotation()
                    
                    page.lineHeight = info.pageProperties.lineHeight;
                    page.bottomMargin = info.pageProperties.bottomMargin;
                    page.topMargin = info.pageProperties.topMargin;
                    page.leftMargin = info.pageProperties.leftMargin;

                    page.pdfPageRect = fileItem!.pageRectOfPage(atNumber: page.associatedPDFKitPageIndex);
                    page.isCover = info.isCover
                    DispatchQueue.main.async(execute: {
                        page.isDirty = true;
                        self.saveDocument(completionHandler: { (success) in
                            onCompletion(nil,true);
                        });
                    });
                }
                catch let error as NSError {
                    DispatchQueue.main.async(execute: {
                        onCompletion(error,false);
                    });
                }
            }

            let copyFileBlock : ((String?)-> Void) = { password in
                DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
                    let fileCoordinator = NSFileCoordinator.init(filePresenter: self);
                    var coordinateError : NSError?;
                    fileCoordinator.coordinate(writingItemAt: destinationURL, options: NSFileCoordinator.WritingOptions.forReplacing, error: &coordinateError, byAccessor: { (writeURL) in
                        blockToExecute(writeURL, password);
                    });
                    if(nil != coordinateError) {
                        DispatchQueue.main.async(execute: {
                            onCompletion(coordinateError,false);
                        });
                    }
                };
            }

            if let writeURL = info.inputFileURL, FTNoteshelfDocument.isPDFDocumentPasswordProtected(writeURL) {
                runInMainThread {
                    self.askPasswordForDocument(writeURL,
                                                viewController: info.rootViewController,
                                                onCompletion: { (password, error) in
                                                    if(nil != error) {
                                                        onCompletion(error,false);
                                                    }
                                                    else {
                                                        copyFileBlock(password)
                                                    }
                                                });
                };
            }
            else {
                copyFileBlock(nil)
            }
        }
    }
    
    fileprivate func importFileWithInfo(_ info : FTDocumentInputInfo,
                                         onCompletion : @escaping ((Bool,NSError?) ->Void))
    {
        let docName = FTUtils.getUUID().appending(".\(nsPDFExtension)");
        let destinationURL = self.templateFolderItem()!.fileItemURL.appendingPathComponent(docName);

        
        let blockToExecute : ((URL)->Void) = { (writeURL) in
            do {
                if(info.isTemplate) {
                    _ = try FileManager.default.copyItem(at: info.inputFileURL!, to: writeURL);
                }
                else {
                    #if targetEnvironment(macCatalyst)
                    _ = try FileManager.default.copyItem(at: info.inputFileURL!, to: writeURL);
                    #else
                    _ = try FileManager.default.moveItem(at: info.inputFileURL!, to: writeURL);
                    #endif
                }
                if(FTNoteshelfDocument.isPDFDocumentPasswordProtected(writeURL)) {
                    runInMainThread {
                    self.askPasswordForDocument(writeURL,
                                                viewController: info.rootViewController,
                                                onCompletion: { (password, error) in
                        if(nil != error) {
                            onCompletion(false,error);
                        }
                        else {
                            let error = self.startImporting(writeURL,
                                                            password: password,
                                                            info : info);
                            
                            onCompletion((error == nil) ? true : false,error);
                        }
                    });
                    };
                }
                else {
                    let error = self.startImporting(writeURL,
                                                    password: nil,
                                                    info : info);
                    onCompletion((error == nil) ? true : false,error);
                }
            }
            catch let error as NSError {
                onCompletion(false,error);
            }
        }
        
        if(info.isNewBook) {
            blockToExecute(destinationURL);
        }
        else {
            DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
                let fileCoordinator = NSFileCoordinator.init(filePresenter: self);
                var coordinateError : NSError?;
                fileCoordinator.coordinate(writingItemAt: destinationURL, options: NSFileCoordinator.WritingOptions.forReplacing, error: &coordinateError, byAccessor: { (writeURL) in
                    blockToExecute(writeURL);
                });
                if(nil != coordinateError) {
                    DispatchQueue.main.async(execute: {
                        onCompletion(false,coordinateError);
                    });
                }
            };
        }
    }
    
    fileprivate func askPasswordForDocument(_ url : Foundation.URL,
                                            viewController : UIViewController?,
                                        onCompletion:@escaping ((String?,NSError?) -> Void))
    {
        var password : String?
        let alertController = UIAlertController.init(title: NSLocalizedString("PasswordProtectedPDF", comment: "Password Protected PDF"), message: NSLocalizedString("EnterPassword", comment: "EnterPassword"), preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction.init(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: { _ in
            onCompletion(password,FTDocumentCreateErrorCode.error(.cancelled))
        })
        alertController.addAction(cancelAction)
        
        let okAction = UIAlertAction.init(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertAction.Style.default, handler: { [weak alertController,weak self] _ in
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
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alertController.textFields?.first, queue: OperationQueue.main) { _ in
            if let textField = alertController.textFields?.first as? UITextField, let text = textField.text {
                okAction.isEnabled =  !text.isEmpty
            }
        }
        alertController.addAction(okAction)
        
        alertController.addTextField(configurationHandler: nil);
        #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
        viewController?.present(alertController, animated: true, completion: nil);
        #endif
    }
    
    fileprivate func startImporting(_ url : Foundation.URL,
                                password : String?,
                                info : FTDocumentInputInfo) -> NSError?
    {
        self.propertyInfoPlist()?.setObject(DOC_VERSION as AnyObject, forKey: DOCUMENT_VERSION_KEY);

        let templateInfo = FTTemplateInfo(documentInfo: info);
        templateInfo.password = password;

        let docName = url.lastPathComponent;
        self.setTemplateValues(docName, values: templateInfo);

        var fileItem = self.templateFolderItem()!.childFileItem(withName: docName) as? FTPDFKitFileItemPDF;
        if(nil == fileItem)
        {
            fileItem = FTPDFKitFileItemPDF.init(fileName: docName, isDirectory: false)
            fileItem?.documentPassword = password;
            fileItem?.securityDelegate = self;
            self.templateFolderItem()!.addChildItem(fileItem);
        }
        let page = fileItem!.pdfDocumentRef();
        var error : NSError?;
        
        if(nil == page) {
            error = FTDocumentCreateErrorCode.error(.failedToImport);
        }
        else {
            error = self.createPageEntities(page!,
                                            url: url,
                                            index: info.insertAt,
                                            info : info);
        }
        return error;
    }
    
    fileprivate func createPageEntities(_ pdfDocument : PDFDocument,
                                    url : Foundation.URL,
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
                page.associatedPDFFileName = url.lastPathComponent;
                
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
                        if currentPageInfo.type == .day,
                           currentPageInfo.shouldShowThisPageOnDiaryLaunch {
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
