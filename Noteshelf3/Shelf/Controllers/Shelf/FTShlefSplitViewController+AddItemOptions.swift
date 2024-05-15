//
//  FTShlefSplitViewController+PhotoLibraryDelegate.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PhotosUI
import Combine
import FTCommon

extension FTShelfSplitViewController {
    private func importItem(_ item: FTImportItem, shouldOpen: Bool = false) {
        self.beginImporting(items: [item]) { [weak self] status, shelfItemsList in
            if status && shouldOpen {
                if let shelfItemProtocol = shelfItemsList.first {
                    self?.currentShelfViewModel?.setcurrentActiveShelfItemUsing(shelfItemProtocol, isQuickCreated: false)
                }
            }
            self?.currentShelfViewModel?.addObserversForShelfItems()
        }
    }
    private func beginImporting(items: [FTImportItem]) {
        self.beginImporting(items: items,
                            completionHandler: nil);
    }
    func beginImporting(items : [FTImportItem],
                                completionHandler: ((Bool,[FTShelfItemProtocol]) -> Void)?)
    {
        guard FTIAPManager.shared.premiumUser.canAddFewMoreBooks(count: items.count) else {
            FTIAPurchaseHelper.shared.showIAPAlert(on: self);
            completionHandler?(false, [])
            return
        }
        let progress = Progress();
        progress.totalUnitCount = Int64(items.count);
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");

        let ftsmartMessage = FTSmartProgressView.init(progress: progress);
        ftsmartMessage.showProgressIndicator(NSLocalizedString("Importing", comment: "Importing..."),
                                             onViewController: self);

        self.importItems(items,progress: progress) {[weak self] (error, shelfItemsList) in
            ftsmartMessage.hideProgressIndicator();
            if let error, error is FTPremiumUserError {
                guard let self = self else { return }
                FTIAPurchaseHelper.shared.showIAPAlert(on: self);
                completionHandler?(false,shelfItemsList);
            } else if let nsError = error {
                if !(nsError as NSError).isDownloadCancelError {
                    (nsError as NSError).showAlert(from: self)
                    completionHandler?(false,shelfItemsList);
                }
            }
            else {
                completionHandler?(true,shelfItemsList);
            }
        };
    }

    private func importItems(_ items : [FTImportItem],
                             shelfItems inItems: [FTShelfItemProtocol]? = nil,
                             progress : Progress,
                             onCompletion : ((Error?,[FTShelfItemProtocol]) -> Void)?)
    {
        var itemsToImport = items;
        let firstItem = itemsToImport.last
        var outShelfItems = inItems ?? [FTShelfItemProtocol]();
        if !progress.isCancelled,let importItem = firstItem {
            let subprogress = self.startImportOfItem(importItem, onCompletion: { (shelfItem,error) in
                if let item = shelfItem {
                    itemsToImport.removeLast();
                    outShelfItems.append(item)
                    runInMainThread {
                        self.importItems(itemsToImport,
                                         shelfItems: outShelfItems,
                                         progress : progress,
                                         onCompletion: onCompletion);
                    }
                } else {
                    onCompletion?(error,outShelfItems);
                }
            });
            progress.addChild(subprogress, withPendingUnitCount: 1);
        } else {
            onCompletion?(nil,outShelfItems);
        }
    }
    fileprivate func pathExtensionforItem(_ inItem : FTImportItem) -> String
    {
        var pathExtension : String = "";
        if let item = inItem.importItem as? NSString {
            pathExtension = item.pathExtension;
        }
        else if let item = inItem.importItem as? URL {
            pathExtension = item.pathExtension;
        }
        return pathExtension;
    }
    //MARK:- Import
    fileprivate func startImportOfItem(_ item: FTImportItem
                                       ,onCompletion:((FTShelfItemProtocol?,Error?) -> Void)?) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");

        if FTIAPManager.shared.premiumUser.nonPremiumQuotaReached {
            onCompletion?(nil, FTPremiumUserError.nonPremiumError)
            progress.completedUnitCount = 1
            return progress;
        }

        let pathExt = self.pathExtensionforItem(item);
        if (FTUtils.isNoteshelfBookType(pathExt)) {
            let subProgress = self.performBookImport(item.importItem, with: item.imporItemInfo,onCompletion: onCompletion);
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }
        else if let zipItem = item.importItem as? FTImportItemZip {
            func performNBZipImportInsideCollection(_ collection: FTShelfItemCollection) {
                let zipImporter = FTNBKZipFileImporter(shelfItemCollection: collection,
                                                       group: self.currentShelfViewModel?.groupItem);
                let subProgress = zipImporter.performImport(zipItem) { (error) in
                    onCompletion?(nil,error);
                }
                progress.addChild(subProgress, withPendingUnitCount: 1);
            }
            if isInNonCollectionMode {
                self.selectUnfiledCollection { unfiledShelfItemCollection in
                    if let  unfiledShelfItemCollection {
                        performNBZipImportInsideCollection(unfiledShelfItemCollection)
                    }
                }
            } else if let collection = self.shelfItemCollection {
                performNBZipImportInsideCollection(collection)
            }
        }else if let fileURL = item.importItem as? URL, isAudioFile(fileURL.path) {
            if isSupportedAudioFile(fileURL.path) {
                let audioItem = FTAudioFileToImport.init(withURL: fileURL)
                audioItem.fileName = fileURL.deletingPathExtension().lastPathComponent
                audioItem.isWatchRecording = false
                if let importInfo = item.imporItemInfo {
                    if !importInfo.notebook.isEmpty {
                        var subProgress1 = Progress()
                        // Fetch the document and open and insert image as annotation
                        subProgress1 = self.insertFileItem(item, atIndex: 0) { sucess, error in
                            onCompletion?(nil, error)
                        }
                        progress.addChild(subProgress1, withPendingUnitCount: 1);
                    } else {
                        self.fetchCollectionDetails(with: importInfo) { _shelfItemColleciton, _groupItem, _shelfItem in
                            let subProgress = self.createNotebookWithAudioItem(audioItem,
                                                             isiWatchDocument: false,
                                                            collection: _shelfItemColleciton,
                                                            groupItem: _groupItem,
                                                             onCompletion: onCompletion)
                            progress.addChild(subProgress, withPendingUnitCount: 1);
                        }
                    }
                    
                } else {
                    func createAudioItemInsideCollection(_ collection: FTShelfItemCollection?, group: FTGroupItemProtocol?) {
                        let subProgress = self.createNotebookWithAudioItem(audioItem,
                                                         isiWatchDocument: false,
                                                        collection: collection,
                                                        groupItem: group,
                                                        onCompletion: onCompletion)
                        progress.addChild(subProgress, withPendingUnitCount: 1);
                    }
                    if isInNonCollectionMode {
                        self.selectUnfiledCollection { unfiledShelfItemCollection in
                            createAudioItemInsideCollection(unfiledShelfItemCollection,group:nil)
                        }
                    } else {
                        createAudioItemInsideCollection(self.shelfItemCollection,group: self.currentShelfViewModel?.groupItem)
                    }
                }
            } else {
                progress.completedUnitCount += 1;
                onCompletion?(nil,nil);
                let alertController = UIAlertController(title: "",
                                                        message: NSLocalizedString("NotSupportedFormat", comment: "Note supported format"),
                                                        preferredStyle: .alert);
                let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Ok"), style: .cancel, handler: nil);
                alertController.addAction(cancelAction);
                self.present(alertController, animated: true, completion: nil);
            }
        } else if let importItem = item.importItem as? URL, isImageFile(importItem.path(percentEncoded: false)), let importInfo = item.imporItemInfo {
            if !importInfo.notebook.isEmpty {
                var subProgress1 = Progress()
                // Fetch the document and open and insert image as annotation
                subProgress1 = self.insertFileItem(item, atIndex: 0) { sucess, error in
                    onCompletion?(nil, error)
                }
                progress.addChild(subProgress1, withPendingUnitCount: 1);
            } else {
                //Create new document and insert image as annotation
                let filePath = FTPDFFileGenerator().generateBlankPDFFile(UIDevice.isLandscapeOrientation)
                if !filePath.isEmpty {
                    self.fetchCollectionDetails(with: importInfo) { _shelfItemColleciton, _groupItem, _shelfItem in
                        _ = self.startImporting(filePath, title: filePath.lastPathComponent.deletingPathExtension,isImageSource: false, collection: _shelfItemColleciton, groupItem: _groupItem) {
                            shelfItem, error in
                            if let shelfItem {
                                let _importItem = FTImportItem(item: item.importItem)
                                let importItemInfo = FTImportItemInfo(collection: item.imporItemInfo?.collection ?? "", group: "", notebook: shelfItem.URL.relativePathWRTCollection())
                                _importItem.imporItemInfo = importItemInfo
                                var subProgress1 = Progress()
                                subProgress1 = self.insertFileItem(_importItem, shelfItemProtocol: shelfItem, atIndex: 0) { sucess, error in
                                    onCompletion?(shelfItem, error)
                                }
                                progress.addChild(subProgress1, withPendingUnitCount: 1);
                            }
                        }
                    }
                } else {
                    progress.completedUnitCount += 1;
                    onCompletion?(nil,nil);
                }
            }
        } else {
            progress.totalUnitCount += 1;
            let importer = FTFileImporter();
            let subProgress = importer.pdfFileFrom(item) { (filePath, error, isImageSource) in
                if(nil != filePath) {
                    let fileName = filePath!.lastPathComponent.deletingPathExtension;
                    var subProgress1 = Progress()
                    if let importInfo = item.imporItemInfo {
                        if !importInfo.notebook.isEmpty {
                            // Fetch the document and open and insert new page
                            subProgress1 = self.insertFileItem(item, atIndex: 0) { sucess, error in
                                onCompletion?(nil, error)
                            }
                            progress.addChild(subProgress1, withPendingUnitCount: 1);
                        } else {
                            self.fetchCollectionDetails(with: importInfo) { _shelfItemColleciton, _groupItem, _shelfItem in
                                subProgress1 = self.startImporting(filePath!, title: fileName,isImageSource: isImageSource,collection: _shelfItemColleciton, groupItem: _groupItem, onCompletion: onCompletion)
                                progress.addChild(subProgress1, withPendingUnitCount: 1);
                            }
                        }
                    } else {
                        func importFileInsideCollection(_ collection: FTShelfItemCollection?, group: FTGroupItemProtocol?) {
                            subProgress1 = self.startImporting(filePath!,
                                                               title: fileName,
                                                               isImageSource: isImageSource,
                                                               collection: collection,
                                                               groupItem: group,
                                                               onCompletion: onCompletion)
                            progress.addChild(subProgress1, withPendingUnitCount: 1);
                        }
                        if self.isInNonCollectionMode {
                            self.selectUnfiledCollection { unfiledShelfItemCollection in
                                importFileInsideCollection(unfiledShelfItemCollection,group:nil)
                            }
                        } else {
                            importFileInsideCollection(self.shelfItemCollection,group: self.currentShelfViewModel?.groupItem)
                        }

                    }
                }
                else {
                    progress.completedUnitCount += 1;
                    onCompletion?(nil,error);
                }
            };
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }
        return progress;
    }
    
    
    private func insertFileItem(_ item : FTImportItem,
                                                 shelfItemProtocol: FTShelfItemProtocol? = nil,
                                                 atIndex : Int,
                                                 onCompletion:((FTShelfItemProtocol?,Error?) -> Void)?) -> Progress
    {
        let importer = FTFileImporter();
        weak var weakSelf = self;
        let progress = Progress();
        progress.totalUnitCount = 1;
        guard let importItemInfo = item.imporItemInfo else {
            progress.completedUnitCount += 1;
            onCompletion?(nil,nil);
            return progress;
        }
        FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: importItemInfo.notebook, igrnoreIfNotDownloaded: true) { shelfItemColleciton, groupItem, _shelfItem in
            var shelfItem = shelfItemProtocol
            if shelfItem == nil {
                shelfItem = _shelfItem
            }
            if let shelfItem {
                if let fileURL = item.importItem as? URL, isImageFile(fileURL.path) {
                    var imageData : Data?
                    do {
                        imageData = try Data(contentsOf: fileURL)
                    } catch {
                        print(error.localizedDescription)
                    }
                    if let dataOfImage = imageData, let img = UIImage(data: dataOfImage) {
                        let notebookUrl = shelfItem.URL
                        self.insertImageInDocument(img: img, with: notebookUrl) { success, error in
                            onCompletion?(shelfItem, error)
                        }
                        progress.completedUnitCount += 1;
                    } else {
                        progress.completedUnitCount += 1;
                        onCompletion?(shelfItem, nil)
                    }
                } else if let fileURL = item.importItem as? URL, isAudioFile(fileURL.path) {
                    if isSupportedAudioFile(fileURL.path) {
                        let item = FTAudioFileToImport.init(withURL: fileURL)
                        item.fileName = fileURL.deletingPathExtension().lastPathComponent
                        item.isWatchRecording = false
                        let notebookUrl = shelfItem.URL
                        self.insertAudioInDocument(audioUrl: item, with: notebookUrl){ success, error in
                            onCompletion?(shelfItem, error)
                        }
                        progress.completedUnitCount += 1;
                    } else {
                        progress.completedUnitCount += 1;
                        onCompletion?(shelfItem, nil)
                        let alertController = UIAlertController(title: "",
                                                                message: NSLocalizedString("NotSupportedFormat", comment: "Note supported format"),
                                                                preferredStyle: .alert);
                        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Ok"), style: .cancel, handler: nil);
                        alertController.addAction(cancelAction);
                        self.present(alertController, animated: true, completion: nil);
                    }
                } else {
                    let subProgress = importer.pdfFileFrom(item) { (filePath, error, _) in
                        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");
                        if(nil != error) {
                            //                progress.completedUnitCount += 1;
                            FTLogError("Insertion: Download Error", attributes: error?.userInfo);
                            onCompletion?(shelfItem,error);
                        }
                        else {
                            if((filePath == nil) || (nil == weakSelf)) {
                                //                    progress.completedUnitCount += 1;
                                onCompletion?(shelfItem,NSError.init(domain: "NSImportError", code: 1001, userInfo: nil));
                                return;
                            }
                            let info = FTDocumentInputInfo();
                            info.rootViewController = self;
                            info.inputFileURL = URL.init(fileURLWithPath: filePath!);
                            info.insertAt = atIndex;
                            info.isTemplate = false;
                            FTCLSLog("Inserting PDF File");
                            let notebookUrl = shelfItem.URL
                            let docrequest = FTDocumentOpenRequest(url: notebookUrl, purpose: .write)
                            FTNoteshelfDocumentManager.shared.openDocument(request: docrequest) { docToken, ftDocument, error in
                                if let ftDocument, error == nil {
                                    info.insertAt = ftDocument.pages().count
                                    ftDocument.insertFile(info, onCompletion: { error, success in
                                        FTNoteshelfDocumentManager.shared.saveAndClose(document: ftDocument, token: docToken) { _ in
                                            progress.completedUnitCount += 1;
                                            onCompletion?(shelfItem,error);
                                        }
                                    })
                                } else {
                                    progress.completedUnitCount += 1;
                                    onCompletion?(shelfItem, nil)
                                }
                            }
                            
                        }
                    };
                    progress.addChild(subProgress, withPendingUnitCount: 1);
                }
            } else {
                progress.completedUnitCount += 1;
                onCompletion?(nil, nil)
            }
        }
        return progress;
    }
    
    private func insertImageInDocument(img: UIImage, with notebookUrl: URL, onCompletion : @escaping ((Bool,NSError?) -> Void)) {
        let docrequest = FTDocumentOpenRequest(url: notebookUrl, purpose: .write)
        FTNoteshelfDocumentManager.shared.openDocument(request: docrequest) { docToken, ftDocument, error in
            if let ftDocument, error == nil {
                if let lastPage = ftDocument.pages().last as? FTNoteshelfPage {
                    if let image = img.scaleAndRotateImageFor1x() {
                        let pageRect = lastPage.pdfPageRect
                        let startingFrame = image.aspectFrame(withinScreenArea: pageRect, zoomScale: 1)
                        let imageInfo = FTImageAnnotationInfo(image: image)
                        imageInfo.boundingRect = startingFrame
                        imageInfo.scale = 1
                        if let imageAnn = imageInfo.annotation() {
                            imageAnn.associatedPage = lastPage
                            lastPage.addAnnotations([imageAnn], indices: nil)
                        }
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: ftDocument, token: docToken) { _ in
                            onCompletion(true,nil);
                        }
                    }
                }
            } else {
                onCompletion(false, nil)
            }
        }
    }
    
    private func insertAudioInDocument(audioUrl: FTAudioFileToImport, with notebookUrl: URL, onCompletion : @escaping ((Bool,NSError?) -> Void)) {
        let docrequest = FTDocumentOpenRequest(url: notebookUrl, purpose: .write)
        FTNoteshelfDocumentManager.shared.openDocument(request: docrequest) { docToken, ftDocument, error in
            if let ftDocument, error == nil {
                if let lastPage = ftDocument.pages().last as? FTNoteshelfPage {
                    (ftDocument as? FTDocumentCreateWatchExtension)?.addAudioAnnotations(urls: [audioUrl], toPage: lastPage, onCompletion: { (annotations) in
                        FTNoteshelfDocumentManager.shared.saveAndClose(document: ftDocument, token: docToken) { _ in
                            onCompletion(true, nil)
                        }
                    })
                }
            } else {
                onCompletion(false, nil)
            }
        }
    }
    
    
    func fetchCollectionDetails(with info: FTImportItemInfo,
    onCompeltion : @escaping (FTShelfItemCollection?, FTGroupItemProtocol?, FTShelfItemProtocol?)->()) {
        let defaultCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        let currentGroup = self.currentShelfViewModel?.groupItem // this can be nil
        if !info.notebook.isEmpty {
            FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: info.notebook, igrnoreIfNotDownloaded: true) { shelfItemColleciton, groupItem, shelfItem in
                if let shelfItemColleciton, let shelfItem {
                    onCompeltion(shelfItemColleciton,groupItem,shelfItem)
                } else {
                    onCompeltion(defaultCollection,currentGroup, nil)
                }
            }
        } else if !info.group.isEmpty {
            FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: info.group, igrnoreIfNotDownloaded: true) { shelfItemColleciton, groupItem, shelfItem in
                if let shelfItemColleciton, let groupItem {
                    onCompeltion(shelfItemColleciton,groupItem, shelfItem)
                } else {
                    onCompeltion(defaultCollection,currentGroup, nil)
                }
            }
        } else if !info.collection.isEmpty  {
            FTNoteshelfDocumentProvider.shared.shelfCollection(title: info.collection) { shelfItemColleciton in
                let collection = shelfItemColleciton ?? defaultCollection
                onCompeltion(collection,currentGroup, nil)
            }
        } else {
            onCompeltion(defaultCollection, currentGroup, nil)
        }
    }
    
    fileprivate func performBookImport(_ item : AnyObject,
                                       with importInfo: FTImportItemInfo?,
                                       onCompletion : ((FTShelfItemProtocol?,Error?)->Void)?) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        progress.localizedDescription = NSLocalizedString("Downloading", comment: "Downloading...");

        if let importItem = item as? String {
            let subprogress = self.startImportingBookAtPath(importItem,
                                                            with: importInfo,
                                                            deleteSourceFile: false,
                                                            onCompletion: onCompletion);
            progress.addChild(subprogress, withPendingUnitCount: 1);
        }
        else if let importItem = item as? URL {
            var shouldDeleteSourceFile: Bool = true
            #if targetEnvironment(macCatalyst)
                shouldDeleteSourceFile = false
            #endif
            let subprogress = self.startImportingBookAtPath(importItem.path,
                                                            with: importInfo,
                                                            deleteSourceFile: shouldDeleteSourceFile,
                                                            onCompletion: onCompletion);
            progress.addChild(subprogress, withPendingUnitCount: 1);
        }
        return progress;
    }

    fileprivate func startImportingBookAtPath(_ downloadPath : String,
                                              with importInfo: FTImportItemInfo?,
                                              deleteSourceFile : Bool,
                                              onCompletion : ((FTShelfItemProtocol?,Error?) -> Void)?) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 100;
        progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");

        DispatchQueue.main.async(execute: {
            if let importInfo {
                self.fetchCollectionDetails(with: importInfo) { collection, group, shelfItem in
                    processImport(with: collection!, group: group, shelfItem: shelfItem)
                }
            } else if !self.isInNonCollectionMode,let collection = self.shelfItemCollection {
                processImport(with: collection, group: self.currentShelfViewModel?.groupItem, shelfItem: nil)
                self.shelfItemCollection = collection
            } else if self.isInNonCollectionMode {
                self.selectUnfiledCollection { unfiledShelfItemCollection in
                    if let unfiledShelfItemCollection {
                        processImport(with: unfiledShelfItemCollection, group: nil, shelfItem: nil)
                        self.shelfItemCollection = unfiledShelfItemCollection
                    }
                }
            }
            func processImport(with collection: FTShelfItemCollection, group: FTGroupItemProtocol?, shelfItem: FTShelfItemProtocol?) {
                let importer = FTNBKFormatImporter.init(url: URL.init(fileURLWithPath: downloadPath), collection: collection, group: group, shelfItem: shelfItem);
                importer.deleteSourceFileOnCompletion = deleteSourceFile;
                importer.startImporting(onUpdate: { (progressValue) in
                    progress.completedUnitCount = Int64(progressValue*100);
                }, onCompletion: { (error, shelfItem) in
                    progress.completedUnitCount = 100;
                    self.navigationController?.dismiss(animated: true, completion: nil);
                    onCompletion?(shelfItem,error);
                })
            }
        });
        return progress;
    }
    
    func startImporting(_ filePath : String,
                        title : String,
                        isImageSource:Bool,
                        isTemplate: Bool = false,
                        collection:FTShelfItemCollection?,
                        groupItem:FTGroupItemProtocol?,
                        onCompletion : ((FTShelfItemProtocol?,Error?) -> Void)?) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        progress.localizedDescription = NSLocalizedString("Saving", comment: "Saving...");

        let tempDocURL = FTDocumentFactory.tempDocumentPath(FTUtils.getUUID());
        let ftdocument = FTDocumentFactory.documentForItemAtURL(tempDocURL);

        let defaultCover = FTThemesLibrary(libraryType: .covers).getDefaultTheme(defaultMode: .quickCreate)

        let info = FTDocumentInputInfo();
        /*var controller : UIViewController? = self;
        if let cont = self.rootViewController?.presentedViewController, !cont.isBeingDismissed {
            controller = cont;
        }*/
        info.isTemplate = isTemplate
        info.rootViewController = self
        info.inputFileURL = URL.init(fileURLWithPath: filePath);
        info.overlayStyle = .clearWhite
        info.coverTemplateImage = defaultCover.themeThumbnail()
        info.isNewBook = true;
        ftdocument.createDocument(info) { (error, _) in
            progress.completedUnitCount += 1;
            if(error == nil) {
                collection!.addShelfItemForDocument(ftdocument.URL, toTitle: title, toGroup: groupItem, onCompletion: { (inerror, item) in
                    if(onCompletion != nil) {
                        onCompletion!(item,inerror);
                    }
                });
            }
            else {
                    if(onCompletion != nil) {
                        onCompletion!(nil,error);
                    }
            }
        };
        return progress;
    }
}
extension FTShelfSplitViewController : FTImportFileHandlerDelegate
{
    var supportsNoteshelfFormat : Bool {
        return true;
    }

    var supportsAudioFileImport : Bool {
        return true;
    }

    var allowsMultipleSelection : Bool {
        return true;
    }

    func importFileHandler(_ handler: FTImportFileHandler, didFinishingPickingURL urls: [URL]) {
        var items = [FTImportItem]();
        urls.forEach { (eachItem) in
            let item = FTImportItem(item: eachItem as AnyObject, onCompletion: nil);
            items.append(item);
        }
        self.beginImporting(items: items);
        self.importFileHandler = nil;
    }
}
extension FTShelfSplitViewController : FTScanDocumentServiceDelegate
{
    func scanDocumentService(_ service: FTScanDocumentService, didFinishWith url: URL) {
        let item = FTImportItem(item: url as AnyObject, onCompletion: nil);
        self.importItem(item,shouldOpen: true)
    }
}
