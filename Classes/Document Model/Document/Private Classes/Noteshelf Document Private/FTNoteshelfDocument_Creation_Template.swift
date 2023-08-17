//
//  FTNoteshelfDocument_Creation_Template.swift
//  Noteshelf
//
//  Created by Amar on 10/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

extension FTNoteshelfDocument
{
    internal func createDocumentFromNSTemplate(_ info : FTDocumentInputInfo,
                                               onCompletion : @escaping  ((NSError?,Bool)->Void))
    {
        let templateURL = info.inputFileURL;
        let templateFileName = templateURL!.deletingLastPathComponent().deletingPathExtension().lastPathComponent;
        FTNSDocumentUnzipper.unzipFile(atPath: templateURL!.path,
                                       onUpdate: nil)
        { (path, error) in
            if(nil == error) {
                do {
                    let url = NSURL.init(fileURLWithPath: path!) as URL;
                    try FileManager().moveItem(at:url, to: self.fileURL);
                     #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                    self.unlockTemplateDocument(templatename: templateFileName,
                                                onViewController: info.rootViewController,
                                                onCompletion: { (pin, error,isTouchIDEnabled) in
                        if(nil != error) {
                            DispatchQueue.main.async(execute: {
                                self.isInDocCreationMode = false;
                                onCompletion(error,false);
                            });
                        }
                        else {
                            if(nil != pin && nil == info.pinModel) {
                                info.pinModel = FTDocumentPin.init(pin: pin,
                                                              hint: self.getHint(),
                                                              isTouchIDEnabled: FTBiometricManager.shared().isTouchIDEnabled());
                            }
                            self._createDocumentFromNSTemplate(info, onCompletion: onCompletion);
                        }
                    });
                    #else
//                    let url = NSURL.init(fileURLWithPath: path!) as URL;
                    if url.isPinEnabledForDocument() {
                        onCompletion(nil,false);
                    }else{
                        self._createDocumentFromNSTemplate(info, onCompletion: onCompletion);
                    }
                    #endif
                    
                }
                catch let nserror as NSError {
                    onCompletion(nserror,false);
                }
            }
            else {
                onCompletion(error,false);
            }
        }
    }
    
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    internal func insertPageFromNSTemplate(_ info : FTDocumentInputInfo,
                                           onCompletion : @escaping  ((NSError?,Bool)->Void))
    {
        let templateURL = info.inputFileURL;
        let templateFileName = templateURL!.deletingLastPathComponent().deletingPathExtension().lastPathComponent;
        FTNSDocumentUnzipper.unzipFile(atPath: templateURL!.path,
                                       onUpdate: nil)
        { (path, error) in
            if(nil != error) {
                onCompletion(error,false);
            }
            else {
                let url = NSURL.init(fileURLWithPath: path!) as URL;
                let document = FTNoteshelfDocument.init(fileURL: url);
                document.unlockTemplateDocument(templatename: templateFileName,
                                                onViewController: info.rootViewController,
                                                onCompletion: { (pin, error,isTouchIDEnabled) in
                    if(nil != error) {
                        DispatchQueue.main.async {
                            onCompletion(error,false);
                        }
                    }
                    else {
                        document.openDocument(purpose: .read,completionHandler: { (sucess,_) in
                            if(sucess) {
                                let pages = document.pages();
                                _ = self.recursivelyCopyPages(pages,
                                                              currentPageIndex: 0,
                                                              startingInsertIndex: info.insertAt,
                                                              pageInsertPosition: FTPageInsertPostion.inBetween,
                                                              onCompletion: { (success, error, pages) in
                                                                DispatchQueue.main.async {
                                                                    onCompletion(error,success);
                                                                }
                                                                if(success) {
                                                                    FTCLSLog("Notebook Template : Insert Page");
                                                                }
                                                                document.closeDocument(completionHandler: nil);
                                });
                            }
                            else {
                                DispatchQueue.main.async {
                                    onCompletion(FTDocumentCreateErrorCode.error(.openFailed),false);
                                }
                            }
                        });
                    }
                });
            }
        }
    }
    
    internal func updateTemplateFromNSTemplate(page : FTPageProtocol,
                                               info : FTDocumentInputInfo,
                                               onCompletion: @escaping ((NSError?, Bool) -> Void))
    {
        if let templateURL = info.inputFileURL {
            let templateFileName = templateURL.deletingLastPathComponent().deletingPathExtension().lastPathComponent;
            FTNSDocumentUnzipper.unzipFile(atPath: templateURL.path,
                                           onUpdate: nil)
            { (path, error) in
                if(nil != error) {
                    onCompletion(error,false);
                }
                else {
                    let url = NSURL.init(fileURLWithPath: path!) as URL;
                    let tempDoc = FTDocumentFactory.documentForItemAtURL(url) as! FTNoteshelfDocument;
                    tempDoc.unlockTemplateDocument(templatename: templateFileName,
                                                   onViewController: info.rootViewController,
                                                   onCompletion:
                        { (pin, error,isTouchIDEnabled) in
                            if(nil != error) {
                                DispatchQueue.main.async(execute: {
                                    onCompletion(error,false);
                                });
                            }
                            else {
                                tempDoc.openDocument(purpose: .read,completionHandler: { (success, error) in
                                    if(nil != error) {
                                        DispatchQueue.main.async(execute: {
                                            onCompletion(error,false);
                                        });
                                    }
                                    else {
                                        if let firstPage = tempDoc.pages().first, let toCopyPageItem = tempDoc.templateFolderItem()?.childFileItem(withName: firstPage.associatedPDFFileName) {
                                            let pageAnnotations = firstPage.annotations();
                                            let docName = FTUtils.getUUID().appending(".\(nsPDFExtension)");
                                            //copy pdf file if needed
                                            let pdfTemplateFileItem = FTPDFKitFileItemPDF.init(fileName: docName)!
                                            pdfTemplateFileItem.securityDelegate = self;
                                            self.templateFolderItem()!.addChildItem(pdfTemplateFileItem);
                                            
                                            FileManager.coordinatedCopyAtURL(toCopyPageItem.fileItemURL,
                                                                             toURL: pdfTemplateFileItem.fileItemURL,
                                                                             onCompletion:
                                                { (success, error) in
                                                    if(nil != error) {
                                                        DispatchQueue.main.async(execute: {
                                                            onCompletion(error,false);
                                                        });
                                                    }
                                                    else {
                                                        if let values = firstPage.templateInfo.copy() as? FTTemplateInfo {
                                                            self.setTemplateValues(docName, values: values);
                                                            if let _password = values.password {
                                                                pdfTemplateFileItem.documentPassword = _password
                                                            }
                                                        }
                                                        page.associatedPDFFileName = docName;
                                                        page.associatedPDFPageIndex = firstPage.associatedPDFPageIndex;
                                                        page.pdfPageRect = firstPage.pdfPageRect;
                                                        page.lineHeight = firstPage.lineHeight;
                                                        page.resetRotation()
                                                        (page as! FTNoteshelfPage).deepCopyAnnotations(pageAnnotations,
                                                                                                       insertFrom : 0,
                                                                                                       onCompletion:
                                                            {
                                                                self.saveDocument(completionHandler: { (success) in
                                                                    tempDoc.closeDocument(completionHandler : nil);
                                                                    onCompletion(nil,success);
                                                                });
                                                        });
                                                    }
                                            });
                                        }
                                        else {
                                            DispatchQueue.main.async(execute: {
                                                onCompletion(FTDocumentCreateErrorCode.error(.failedToUpdateTemplate),false);
                                            });
                                        }
                                    }
                                });
                            }
                    });
                }
            };
        }
    }
    #endif
    
    private func _createDocumentFromNSTemplate(_ info : FTDocumentInputInfo,
                                               onCompletion : @escaping  ((NSError?,Bool) -> Void))
    {
        let closeDocBlock : (Bool) -> ()  = { (success) in
            self.closeDocument(completionHandler: { (_) in
                var error : NSError?;
                if(!success) {
                    error = FTDocumentCreateErrorCode.error(.saveFailed);
                }
                else {
                    FTCLSLog("Notebook Template : new notebook")
                }
                onCompletion(error,success);
            });
        }

        if let shelfImage = info.coverTemplateImage {
            self.openDocument(purpose: .write, completionHandler: { (openSuccess,_) in
                if(openSuccess) {
                    self.shelfImage = shelfImage;
                    self.documentUUID = FTUtils.getUUID()
                    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
                    if info.overlayStyle != FTCoverStyle.default{
                        self.shelfImage = self.transparentThumbnail(isEncrypted: info.isEnCrypted)
                    }
                    
                    if let pinModel = info.pinModel {
                        if false == self.isSecured() {
                            self.pin = pinModel.pin;
                            self.pinHint = pinModel.hint;
                            self.secureDocument(onCompletion: { (saveSuccess) in
                                closeDocBlock(saveSuccess);
                            });
                        }
                        else {
                            self.setHint(pinModel.hint);
                            self.updatePin(pinModel.pin, onCompletion: { (success) in
                                closeDocBlock(success);
                            });
                        }
                    }
                    else {
                        self.saveDocument(completionHandler: { (saveSuccess) in
                            closeDocBlock(saveSuccess);
                        });
                    }
                    #else
                    self.saveDocument(completionHandler: { (saveSuccess) in
                        closeDocBlock(saveSuccess);
                    });
                    #endif
                    
                }
                else {
                    onCompletion(FTDocumentCreateErrorCode.error(.openFailed),openSuccess);
                }
            });
        }
        else {
            DispatchQueue.main.async(execute: {
                self.isInDocCreationMode = false;
                onCompletion(nil,true);
            });
        }
    }
}
