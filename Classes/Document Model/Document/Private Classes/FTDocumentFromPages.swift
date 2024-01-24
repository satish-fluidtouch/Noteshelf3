//
//  FTDocumentFromPages.swift
//  Noteshelf
//
//  Created by Amar on 08/06/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentFromPages: NSObject {

    private var document: FTNoteshelfDocument;
    private var purpose: FTDocumentCreationPurpose = .default;
    private var recoveryInfoPlist: FTNotebookRecoverPlist?
    
    init(with doc: FTNoteshelfDocument,purpose inPurpose: FTDocumentCreationPurpose) {
        purpose = inPurpose;
        document = doc;
    }
    
    func createDocumentAtTemporaryURL(_ toURL : Foundation.URL,
                                      fromPages : [FTPageProtocol],
                                      documentInfo: FTDocumentInputInfo,
                                      onCompletion :@escaping ((Error?) -> Void)) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = Int64(2);
        
        guard let ftdocument = FTDocumentFactory.documentForItemAtURL(toURL) as? FTNoteshelfDocument  else {
            onCompletion(FTDocumentCreateErrorCode.error(.unexpectedError));
            return progress;
        }
        
        ftdocument.createDocument(documentInfo) { (error, success) in
            progress.completedUnitCount += 1;
            if(error == nil) {
                ftdocument.isInDocCreationMode = true;
                ftdocument.openDocument(purpose: .write, completionHandler:
                    { (success,error) in
                        if(success) {
                            if(self.purpose == .trashRecovery) {
                                let url = ftdocument.fileURL;
                                let recoveryinfo = FTNotebookRecoverPlist(url: url.appendingPathComponent(NOTEBOOK_RECOVERY_PLIST), isDirectory: false,document: self.document);
                                recoveryinfo?.documentUUID = self.document.documentUUID
                                self.recoveryInfoPlist = recoveryinfo;
                                ftdocument.rootFileItem.addChildItem(recoveryinfo);
                            }
                        
                            let subProgress: Progress;
                            if(self.document.isPinEnabled()) {
                                subProgress = ftdocument.recursivelyCopyPages(fromPages,
                                                                              currentPageIndex: 0,
                                                                              startingInsertIndex: 0,
                                                                              pageInsertPosition: .none)
                                { (_, error, _) in
                                    ftdocument.isInDocCreationMode = false;
                                    ftdocument.closeDocument{ _ in
                                        onCompletion(error);
                                    };
                                }
                            }
                            else {
                                subProgress = self.copyPage(pages: fromPages,
                                                            toDocument: ftdocument,
                                                            fromIndex: 0)
                                { (error) in
                                    ftdocument.isInDocCreationMode = false;
                                    ftdocument.closeDocument{ _ in
                                        onCompletion(error);
                                    };
                                }
                                
                            }
                            progress.addChild(subProgress, withPendingUnitCount: 1);
                        }
                        else {
                            ftdocument.isInDocCreationMode = false;
                            DispatchQueue.main.async {
                                onCompletion(FTDocumentCreateErrorCode.error(.openFailed));
                            }
                        }
                });
            }
            else {
                ftdocument.isInDocCreationMode = false;
                DispatchQueue.main.async {
                    onCompletion(error);
                }
            }
        };
        return progress;
    }
    
    private func copyPage(pages: [FTPageProtocol],
                          toDocument : FTNoteshelfDocument,
                          fromIndex:Int,
                          onCompletion:@escaping (Error?)->()) -> Progress {
        let subProgress = Progress();
        subProgress.totalUnitCount = Int64(pages.count);

        DispatchQueue.main.async(execute: {
            self._copyPages(pages,
                            toDocument: toDocument,
                            fromIndex: fromIndex,
                            progress: subProgress,
                            onCompletion: onCompletion)
        });
        return subProgress;
    }
    
    private func _copyPages(_ inPages: [FTPageProtocol],
                            toDocument : FTNoteshelfDocument,
                            fromIndex:Int,
                            progress: Progress,
                            onCompletion:@escaping (Error?)->()) {
        var pages = inPages;
        if(pages.isEmpty) {
            toDocument.saveDocument { (_) in
                onCompletion(nil);
            }
        }else {
            let _page = pages.removeFirst();
            guard let page = (_page as? FTNoteshelfPage) else {
                onCompletion(FTDocumentCreateErrorCode.error(.saveFailed));
                return
            }
            let newPage = page.copyPage(toDocument);
            newPage.recognitionInfo = page.recognitionInfo;
            let error = page.copyResource(from: document,
                                          to: toDocument,
                                          toPage:newPage);
            progress.completedUnitCount += 1;
            if let _error = error {
                onCompletion(_error);
            }
            else {
                self.recoveryInfoPlist?.addPageIndex(page.pageIndex(), pageUUID: newPage.uuid);
                toDocument.documentInfoPlist()?.insertPage(newPage, atIndex: fromIndex);
                DispatchQueue.main.async(execute: {
                    self._copyPages(pages,
                                    toDocument: toDocument,
                                    fromIndex: fromIndex + 1,
                                    progress: progress,
                                    onCompletion: onCompletion);
                })
            }
        }
    }
}

private extension FTNoteshelfPage {
    func copyResource(from fromDoc:FTNoteshelfDocument,
                      to toDoc: FTNoteshelfDocument,
                      toPage: FTNoteshelfPage) -> Error?
    {
        var filesToCopy = [FTCopySource]();
        let readingURL = fromDoc.fileURL;
        let writingURL = toDoc.fileURL;

        if let newFileName = self.associatedPDFFileName {
            toDoc.setTemplateValues(newFileName, values: self.templateInfo);
        }
        
        let sqliteName = self.sqliteFileName();
        let fromURL = readingURL.appendingPathComponent(ANNOTATIONS_FOLDER_NAME).appendingPathComponent(sqliteName);
        let tosqliteName = toPage.sqliteFileName();
        let toURL = writingURL.appendingPathComponent(ANNOTATIONS_FOLDER_NAME).appendingPathComponent(tosqliteName);

        let entry = FTCopySource(source: fromURL, destination: toURL);
        filesToCopy.append(entry)
        
        if let fileName = self.associatedPDFFileName {
            let fromURL = readingURL.appendingPathComponent(TEMPLATES_FOLDER_NAME).appendingPathComponent(fileName);
            let toURL = writingURL.appendingPathComponent(TEMPLATES_FOLDER_NAME).appendingPathComponent(fileName);
            
            let entry = FTCopySource(source: fromURL, destination: toURL);
            filesToCopy.append(entry)
        }

        let resourceFiles = self.resourceFileNames();
        resourceFiles.forEach { (eachFile) in
            let fromURL = readingURL.appendingPathComponent(RESOURCES_FOLDER_NAME).appendingPathComponent(eachFile);
            let toURL = writingURL.appendingPathComponent(RESOURCES_FOLDER_NAME).appendingPathComponent(eachFile);
            
            let entry = FTCopySource(source: fromURL, destination: toURL);
            filesToCopy.append(entry)
        }

        var copyError: Error?;
        for eachItem in filesToCopy {
            do {
                try eachItem.copyFile();
            }
            catch {
                copyError = error;
                break;
            }
        }
        return copyError;
    }
}

private class FTCopySource: NSObject {
    var sourceURL: URL;
    var destinationURL: URL;
    
    init(source: URL, destination: URL) {
        sourceURL = source;
        destinationURL = destination;
        super.init();
    }
        
    func copyFile() throws {
        let fileManager = FileManager();
        if fileManager.fileExists(atPath: self.sourceURL.path),
            !fileManager.fileExists(atPath: self.destinationURL.path) {
            try fileManager.copyItem(at: self.sourceURL, to: self.destinationURL);
        }
    }
}
