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
        else if let zipItem = item.importItem as? FTImportItemZip, let collection = self.shelfItemCollection {
            let zipImporter = FTNBKZipFileImporter(shelfItemCollection: collection,
                                                   group: self.currentShelfViewModel?.groupItem);
            let subProgress = zipImporter.performImport(zipItem) { (error) in
                onCompletion?(nil,error);
            }
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }else if let fileURL = item.importItem as? URL, isAudioFile(fileURL.path) {
            if isSupportedAudioFile(fileURL.path) {
                let audioItem = FTAudioFileToImport.init(withURL: fileURL)
                if let importInfo = item.imporItemInfo {
                    self.fetchCollectionDetails(with: importInfo) { _shelfItemColleciton, _groupItem in
                        let subProgress = self.createNotebookWithAudioItem(audioItem,
                                                         isiWatchDocument: false,
                                                        collection: _shelfItemColleciton,
                                                        groupItem: _groupItem,
                                                         onCompletion: onCompletion)
                        progress.addChild(subProgress, withPendingUnitCount: 1);
                    }
                } else {
                    let subProgress = self.createNotebookWithAudioItem(audioItem,
                                                     isiWatchDocument: false,
                                                    collection: self.shelfItemCollection,
                                                    groupItem: self.currentShelfViewModel?.groupItem,
                                                    onCompletion: onCompletion)
                    progress.addChild(subProgress, withPendingUnitCount: 1);
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
        } else {
            progress.totalUnitCount += 1;
            let importer = FTFileImporter();
            let subProgress = importer.pdfFileFrom(item) { (filePath, error, isImageSource) in
                if(nil != filePath) {
                    let fileName = filePath!.lastPathComponent.deletingPathExtension;
                    var subProgress1 = Progress()
                    if let importInfo = item.imporItemInfo {
                        self.fetchCollectionDetails(with: importInfo) { _shelfItemColleciton, _groupItem in
                            subProgress1 = self.startImporting(filePath!, title: fileName,isImageSource: isImageSource,collection: _shelfItemColleciton, groupItem: _groupItem, onCompletion: onCompletion)
                            progress.addChild(subProgress1, withPendingUnitCount: 1);
                        }
                    } else {
                        subProgress1 = self.startImporting(filePath!, title: fileName,isImageSource: isImageSource,collection: self.shelfItemCollection, groupItem: self.currentShelfViewModel?.groupItem,onCompletion: onCompletion)
                        progress.addChild(subProgress1, withPendingUnitCount: 1);
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
    
    func fetchCollectionDetails(with info: FTImportItemInfo,
                         onCompeltion : @escaping (FTShelfItemCollection?, FTGroupItemProtocol?)->()) {
        let defaultCollection = FTNoteshelfDocumentProvider.shared.allNotesShelfItemCollection
        let currentGroup = self.currentShelfViewModel?.groupItem // this can be nil
        if !info.group.isEmpty {
            FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: info.group, igrnoreIfNotDownloaded: true) { shelfItemColleciton, groupItem, _ in
                if let shelfItemColleciton, let groupItem {
                    onCompeltion(shelfItemColleciton,groupItem)
                } else {
                    onCompeltion(defaultCollection,currentGroup)
                }
            }
        } else if !info.collection.isEmpty  {
            FTNoteshelfDocumentProvider.shared.shelfCollection(title: info.collection) { shelfItemColleciton in
                let collection = shelfItemColleciton ?? defaultCollection
                onCompeltion(collection,currentGroup)
            }
        } else {
            onCompeltion(defaultCollection, currentGroup)
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
                self.fetchCollectionDetails(with: importInfo) { collection, group in
                    processImport(with: collection!, group: group)
                }
            } else if let collection = self.shelfItemCollection {
                processImport(with: collection, group: self.currentShelfViewModel?.groupItem)
            }
            func processImport(with collection: FTShelfItemCollection, group: FTGroupItemProtocol?) {
                let importer = FTNBKFormatImporter.init(url: URL.init(fileURLWithPath: downloadPath), collection: collection, group: group);
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
