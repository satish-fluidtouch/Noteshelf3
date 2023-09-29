//
//  FTPDFRenderViewController_Extension.swift
//  Noteshelf
//
//  Created by Amar on 9/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import IntentsUI
import AVFoundation
import UIKit
import FTStyles
import FTCommon

private let customTransitioningDelegate = FTSlideInPresentationManager(mode: .topToBottom)
private let customLeftTransitioningDelegate = FTSlideInPresentationManager(mode: .leftToRight);

extension FTPDFRenderViewController {

    //Cancelling Thumbnail generation
    @objc func cancelAllThumbnailGeneration() {
        self.pdfDocument?.cancelAllThumbnailGeneration()
    }
    
    @objc func updateBackgroundcolor() {
    #if targetEnvironment(macCatalyst)
        //Change mac specific bgcolor in future
        self.contentHolderView.backgroundColor = UIColor.appColor(.pageBGColor)
    #else
        self.contentHolderView.backgroundColor = UIColor.appColor(.pageBGColor)
    #endif
    }
    
    //MARK:- FTSettingsDelegate
    func didDismissSettingsController() {
        self.handleSettingsDismiss();
    }
            
    //MARK:- Custom
    @objc @discardableResult func insertFileItem(_ item : FTImportItem,
                                                 atIndex : Int,
                                                 onCompletion : @escaping ((Bool,NSError?) -> Void)) -> Progress
    {
        let importer = FTFileImporter();
        weak var weakSelf = self;
        let progress = Progress();
        progress.totalUnitCount = 1;
        if let fileURL = item.importItem as? URL, isImageFile(fileURL.path) {
            var imageData : Data?
            do {
                 imageData = try Data(contentsOf: fileURL)
            } catch {
                print(error.localizedDescription)
            }
            if let dataOfImage = imageData, let image = UIImage(data: dataOfImage) {
                self.insert([image], center: CGPoint.zero, droppedPoint: .zero, source: FTInsertImageSourceInsertFrom)
            }
            self.pdfDocument.isDirty = true
            progress.completedUnitCount += 1;
            onCompletion(true,nil);

            }
      else  if let fileURL = item.importItem as? URL, isAudioFile(fileURL.path) {
            if isSupportedAudioFile(fileURL.path) {
                let item = FTAudioFileToImport.init(withURL: fileURL)
                if let subProgress = self.addRecordingToPage(actionType: .addToCurrentPage,
                                                             audio: item,
                                                             onCompletion: onCompletion) {
                    progress.addChild(subProgress, withPendingUnitCount: 1);
                }
                else {
                    progress.completedUnitCount += 1;
                    onCompletion(true,nil);
                }
            } else {
                progress.completedUnitCount += 1;
                onCompletion(false,nil);
                let alertController = UIAlertController(title: "",
                                                        message: NSLocalizedString("NotSupportedFormat", comment: "Note supported format"),
                                                        preferredStyle: .alert);
                let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Ok"), style: .cancel, handler: nil);
                alertController.addAction(cancelAction);
                self.present(alertController, animated: true, completion: nil);
            }
        }
        else {
            let subProgress = importer.pdfFileFrom(item) { (filePath, error, _) in
                progress.localizedDescription = NSLocalizedString("Importing", comment: "Importing...");
                if(nil != error) {
                    //                progress.completedUnitCount += 1;
                    FTLogError("Insertion: Download Error", attributes: error?.userInfo);
                    onCompletion(false,error);
                }
                else {
                    if((filePath == nil) || (nil == weakSelf)) {
                        //                    progress.completedUnitCount += 1;
                        onCompletion(false,NSError.init(domain: "NSImportError", code: 1001, userInfo: nil));
                        return;
                    }
                    let info = FTDocumentInputInfo();
                    info.rootViewController = self;
                    info.inputFileURL = URL.init(fileURLWithPath: filePath!);
                    info.insertAt = atIndex;
                    info.isTemplate = false;
                    FTCLSLog("Inserting PDF File");
                    weakSelf?.pdfDocument.insertFile(info,
                                                     onCompletion: { [weak self] (error, success) in
                                                        //                                                    progress.completedUnitCount += 1;
                                                        if(nil != error) {
                                                            FTLogError("Insertion Error", attributes: error?.userInfo)
                                                        }
                                                        self?.pdfDocument.isDirty = true
                                                        onCompletion(success,error);
                    });
                }
            };
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }
        return progress;
    }

    @objc func openSettingsPage()
    {
        guard let curPage = self.firstPageController()?.pdfPage else {
            return;
        }
        self.normalizeAndEndEditingAnnotation(true);

        if(curPage.isDirty) {
            self.pdfDocument.saveDocument(completionHandler: nil);
        }
        self.isNewPageFromTemplate = false
        var source: AnyObject

        #if targetEnvironment(macCatalyst)
        guard let toolbarItem = self.view.toolbar as? FTNotebookToolbar,
              let item = toolbarItem.toolbarItem(FTNotebookToolbarItemType.more.toolbarIdentifier) else {
            return
        }
        source = item
        #else
        guard let sourceView = self.rightPanelSource(for: .more) else { return }
        source = sourceView
        #endif
        FTNotebookMoreOptionsViewController.showAsPopover(fromSourceView: source,
                                                          overViewController: self,
                                                          notebookShelfItem: self.shelfItemManagedObject.documentItemProtocol,
                                                          notebookDocument: self.pdfDocument,
                                                          page: curPage,
                                                          delegate:self)

    }
    
   @objc func didTapAudio() {
       let pages = self.pdfDocument.pages()
       var audioAnnotations = [FTAudioAnnotation]()
       pages.forEach { eachPage in
           let annotations = eachPage.audioAnnotations().map { eachAnn in
               return eachAnn as! FTAudioAnnotation
           }
           audioAnnotations.append(contentsOf: annotations)
       }
       if let sourceView = self.centerPanelToolbarSource(for: .pen) {
           FTAudioTrackController.showAsPopover(fromSourceView: sourceView, overViewController: self, with: CGSize(width: defaultPopoverWidth, height: 366), annotations: audioAnnotations, mode: .notebook, selectedAnnotation: audioAnnotations.first)
       }
    }
    
    @objc func didTapOnFinderButton() {
        if let splitVc  = self.parent!.parent!.parent as? UISplitViewController {
            if isRegularClass() {
                let mode = splitVc.displayMode
                var preferredMode: UISplitViewController.DisplayMode = mode
                
                if UIDevice.isLandscapeOrientation {
                    if preferredMode == .oneBesideSecondary {
                        preferredMode = .secondaryOnly
                     } else {
                        preferredMode = .oneBesideSecondary
                    }
                } else {
                    if preferredMode == .secondaryOnly {
                        preferredMode = .oneOverSecondary
                    } else {
                        preferredMode = .secondaryOnly
                    }
                }
                UIView.animate(withDuration: 0.2) {
                    splitVc.preferredDisplayMode = preferredMode
                }
               // if let _mode = mode {
               // }
            }
        }
    }
    
    @objc func showRecentItems(_ animated: Bool) {
        self.normalizeAndEndEditingAnnotation(true);
        guard let currentPage = self.firstPageController()?.pdfPage else {
            return;
        }
        
        if(currentPage.isDirty) {
            self.pdfDocument.saveDocument(completionHandler: nil);
        }
//        let stroyBoard = UIStoryboard(name: "FTShelf_iOS13", bundle: nil)
//        if let categoryVC = stroyBoard.instantiateViewController(withIdentifier: "FTShelfCategoryViewController_iOS13") as? FTShelfCategoryViewController_iOS13 {
//            if let shelfItem = self.shelfItemManagedObject.documentItem as? FTShelfItemProtocol {
//                categoryVC.shelfItemCollection = shelfItem.shelfCollection;
//                categoryVC.delegate = self
//                categoryVC.displayMode = .notebook
//                self.ftPresentHorizontally(categoryVC, contentSize: CGSize.init(width: 300, height: UIScreen.main.bounds.height), animated: true, completion: nil)
//            }
//        }
    }    
    
    @objc
    func showShareScreenshotWindowWithImage(_ image : UIImage) {
        let controller = FTLassoScreenshotViewController.init(nibName:
            "FTLassoScreenshotViewController", bundle: nil)
        controller.screenshot = image
        if self.isRegularClass() {
            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            navigationController.isNavigationBarHidden = true
            self.present(navigationController, animated: true, completion: nil)
        } else {
            self.ftPresentModally(controller, animated: true, completion: nil)
        }
    }
    
    @objc func presentedRackType(for presentedViewController: UIViewController) -> Int {
        if let vc = presentedViewController as? FTPenRackViewController {
            return vc.penTypeRack.type.rawValue
        } else if presentedViewController is FTEraserRackViewController {
            return FTRackType.eraser.rawValue
        }
        return -1;
    }
    
    @objc func goToRecordings(with annotation: FTAnnotation) {
        self.finderNotifier?.didGoToAudioRecordings(with: annotation)
    }

    @objc func showNotebookInfoToast() {
        if let page = self.firstPageController()?.pdfPage as? FTThumbnailable, let shelfItemObj = self.shelfItemManagedObject {
            let creationDate = shelfItemObj.fileCreationDate
            let timeInterval = Date().timeIntervalSince(creationDate)
            // Not interested in showing notebook info toast for just created book
            if timeInterval > 10.0,  let title = shelfItemObj.title {
                let currentPageNum = page.pageIndex() + 1
                let totalPagesCount = self.pdfDocument.pages().count
                let info = FTNotebookToastInfo(title: title, currentPageNum: currentPageNum, totalPageCount: totalPagesCount)
                FTBookInfoToastHostController.showToast(from: self, info: info)
            }
        }
    }

    @objc func removeNotebookInfoToast() {
        FTBookInfoToastHostController.removeIfToastExists(from: self)
    }
}

extension FTPDFRenderViewController : FTWatchRecordedListViewControllerDelegate{
    func recordingViewController(_ recordingsViewController: FTWatchRecordedListViewController, didSelectRecording recordedAudio: FTWatchRecordedAudio, forAction actionType: FTAudioActionType) {
        self.dismiss(animated: true) {
            if(actionType == .exportAudio) {
                guard let sourceView = self.rightPanelSource(for: FTDeskRightPanelTool.add) else { return }
                let exporter = FTWatchAudioExporter(baseViewController: self);
                exporter.performExport(watchRecording: recordedAudio,
                                       onViewController: self.parent ?? self,
                                       sourceRect: sourceView.bounds, sourceView: sourceView);
                FTCLSLog("Watch Recording: Export - Inside");
                return;
            }
            
            if(recordedAudio.audioStatus == FTWatchAudioStatus.unread){
                let newRecording = FTWatchRecordedAudio.initWithDictionary(recordedAudio.dictionaryRepresentation())
                newRecording.audioStatus = FTWatchAudioStatus.read
                newRecording.filePath = recordedAudio.filePath
                FTNoteshelfDocumentProvider.shared.updateRecording(item: newRecording, onCompletion: { (error) in
                    if(error == nil){
                        self.continueToProcessRecording(withRecording: newRecording, andAction: actionType)
                    }
                    else
                    {
                        (error! as NSError).showAlert(from: self)
                    }
                })
            }
            else
            {
                self.continueToProcessRecording(withRecording: recordedAudio, andAction: actionType)
            }
        }
    }
    func continueToProcessRecording(withRecording recordedAudio: FTWatchRecordedAudio, andAction actionType: FTAudioActionType){
        
        let item = FTAudioFileToImport.init(withURL: recordedAudio.filePath!,
                                            date: recordedAudio.date,
                                            fileName: nil);

        addRecordingToPage(actionType: actionType, audio: item, onCompletion: nil)
    }
    
    @discardableResult func addRecordingToPage(actionType: FTAudioActionType,
                                               audio: FTAudioFileToImport,
                                               onCompletion : ((Bool,NSError?) -> Void)?) -> Progress? {
        let progress = Progress();
        progress.totalUnitCount = 1;
        
        if(actionType == .addToNewPage){
            let pageIndex = self.currentlyVisiblePage()?.pageIndex() ?? 0;
            (self.pdfDocument as? FTDocumentCreateWatchExtension)?.insertNewPageForWatchAudio([audio], atIndex: pageIndex + 1, onCompletion: { (page, error) in
                progress.completedUnitCount += 1;
                
                let newPageCount = self.pdfDocument.pages().count;
                let pagesAdded = newPageCount - self.numberOfPages();
                self.refreshUIforInsertedPages(at: UInt(pageIndex + 1), count: UInt(pagesAdded), forceReLayout: true)
                onCompletion?(true, nil)
                FTCLSLog("Watch Recording : Added new page");
                
            })
        }
        else if(actionType == .addToCurrentPage){
            guard let currentPageController = self.firstPageController(),
                let curPage = currentPageController.pdfPage else {
                    progress.completedUnitCount += 1;
                    onCompletion?(false, NSError(domain: "Noteshelf", code: 120, userInfo: [NSLocalizedDescriptionKey : "Failed importing audio"]));
                    return nil;
            }
            
            (self.pdfDocument as? FTDocumentCreateWatchExtension)?.addAudioAnnotations(urls: [audio], toPage: curPage, onCompletion: { (annotations) in
                progress.completedUnitCount += 1;
                var rect = CGRect.null
                annotations.forEach({ (annotation) in
                    if(rect.isNull) {
                        rect = annotation.renderingRect
                    }
                    else {
                        rect = rect.union(annotation.renderingRect);
                    }
                });
                
                if !rect.isNull , let localWritingView = currentPageController.writingView {
                    let properties = FTRenderingProperties();
                    properties.renderImmediately = true;
                    properties.pageID = localWritingView.pageToDisplay.uuid;
                    currentPageController.refresh(rect,
                                                  scale: currentPageController.pageContentScale,
                                                  renderProperties: properties);
                }
                
                onCompletion?(true, nil)
                FTCLSLog("Watch Recording : Added to Current");
            })
        }
        return progress;
    }
}

extension FTPDFRenderViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    public func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        }else{
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension FTPDFRenderViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    public func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            print("error : addVoiceShortcutViewController : \(error.debugDescription)")
        }else{
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

//MARK:- FTNotebookMoreOptionsDelegate
extension FTPDFRenderViewController: FTNotebookMoreOptionsDelegate {
    func presentPasswordScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: true) {
                if let notebookDoc = self.pdfDocument as? FTDocument {
                    let storyboard = UIStoryboard(name: "FTPasswordSettings", bundle: nil)
                    if let controller = storyboard.instantiateViewController(withIdentifier: "FTPasswordViewController") as? FTPasswordViewController {
                        controller.delegate = self
                        controller.passwordFlow = (nil != notebookDoc.pin ? .changePassword : .setPassword)
                        if controller.passwordFlow == .changePassword {
                            if let document = self.pdfDocument {
                                controller.isTouchIDEnabledAtPresent = FTBiometricManager.keychainGetIsTouchIDEnabled(forKey: document.documentUUID)
                            }
                            controller.isTouchIDEnabledManually = controller.isTouchIDEnabledAtPresent
                        }
                        let navController = UINavigationController(rootViewController: controller)
                        navController.modalPresentationStyle = .formSheet
                        self.present(navController, animated: true, completion: nil)
                    }
                }
        }
    }

    func didTapBasicOption(option: FTNotebookBasicOption, with page: FTPageProtocol, controller: FTNotebookMoreOptionsViewController) {
        switch option {
        case .bookMark:
            if let thumbnailable = page as? FTThumbnailable {
                self.bookMarkAction(page:thumbnailable)
            }
        case .saveAsTemplate:
            controller.dismiss(animated: true) {[weak self] in
                self?.savePageAsTemplate(with: page)
            }
        case .present:
            self.switchToPresentMode(settingsController: controller)
        case .zoomBox:
            controller.dismiss(animated: true) {[weak self] in
                self?.zoomButtonAction()
            }
        case .gestures:
            self.presentGestureUI(settingsController: controller)
        case .help:
            self.presentHelpScreen(settingsController: controller)
        case .customizeToolBar:
            self.presentCustomizeToolbarScreen(settingsController: controller)
        default:
            break
        }
    }
    func getShareInfo(completion: @escaping (FTShareOptionsInfo) -> Void) {
        self.prepareShareInfo(completion: completion)
    }
    
    func savePageAsTemplate(with page: FTPageProtocol) {
        let target = FTExportTarget()
        let reqItem = self.shelfItemManagedObject.documentItemProtocol
        let item = FTItemToExport(shelfItem: reqItem)
        target.itemsToExport = [item]
        target.notebook = page.parentDocument
        target.pages = [page]
        target.properties = FTExportProperties.getSavedProperties()
        let exportManager = FTExportProgressManager()
        exportManager.exportTarget = target
        exportManager.exportType = .saveAsTemplate
        exportManager.delegate = self
        exportManager.startExportingProcess(onViewController: self)
        self.exportManager = exportManager
    }

    func rotatePage(by angle:UInt) {
        self.executer.execute(type: .rotatePage(angle: angle))
    }
    
    func handleGotoPage(_ pageNumber: Int, controller: UIViewController) {
        controller.dismiss(animated: true) {[weak self] in
            guard let `self` = self else {
                return
            }
            var pageIndex = max(0, Int(pageNumber) - 1)
            pageIndex = min(pageIndex, self.pdfDocument.pages().count - 1)
            self.showPage(at: pageIndex, forceReLayout: false)
        }
    }

    func switchToPresentMode(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: true) {
            if self.currentDeskMode == .deskModeReadOnly,self.view.bounds.size.width <= 375 { // As for screen width less than 375, a seperate tool bar is shown for presenter mode. Hence turning off the readonly mode theme
                NotificationCenter.default.post(name: Notification.Name(rawValue: "FTPDFReadOnlyMode"), object: self.view.window, userInfo: ["isOn" : false])
            }
            self.laserButtonAction()
        }
    }
    func switchToReadOnlyMode(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: true){
            self.readOnlyButtonAction()
        }
    }
    func presentFinderScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: true){
            self.toggleFinder(true)
        }
    }
    func presentChangeTemplateScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: true) {
            self.showPaperTemplateScreen(source: .changeTemplate)
        }
    }
    
    func presentStylusScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: false) {[weak self] in
           self?.showStylusSettings()
        }
    }
    
    @objc func showStylusSettings() {
        let storyboard = UIStoryboard(name: "FTSettings_Stylus", bundle: nil)
        if let stylusController = storyboard.instantiateViewController(withIdentifier: "FTStylusesViewController") as? FTStylusesViewController {
            let navController = UINavigationController(rootViewController: stylusController)
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true, completion: nil);
        }
    }
    
    func presentGestureUI(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            FTGestureHelpViewController.presentGestureHelpScreen(controller: self)
        }
    }
    
    func presentHelpScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: false) {[weak self] in
            guard let self = self else { return }
#if targetEnvironment(macCatalyst)
            FTDiagnosisHandler.sharedDiagnosisHandler().sendSystemLog(onViewController: self)
            FTCLSLog("UI: Send Log")
#elseif BETA
            FTZenDeskManager.shared.showFeedbackSupportScreen(controller: self)
            FTCLSLog("UI: Feeback Support")
#else
            FTZenDeskManager.shared.presentSupportHelpCenterScreen(controller: self)
            FTCLSLog("UI: Knowledge Base")
#endif
        }
    }
    
    func presentCustomizeToolbarScreen(settingsController: FTNotebookMoreOptionsViewController) {
        settingsController.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            FTCustomizeToolbarController.showCustomizeToolbarScreen(controller: self)
            // Track Event
            track(EventName.toolbar_more_customizetoolbar_tap)
        }
    }

    @objc func isStylusOptionsScreenOpen() -> Bool {
        return self.view.window?.visibleViewController is FTStylusesViewController
    }
}

//MARK- Loggging
extension FTPDFRenderViewController {
    @objc
    func logBookInformation(isOpen:Bool) {
        let helper = isOpen ? "Book Opened" : "Book Closed"
        let title = self.shelfItemManagedObject.documentItemProtocol.title;
        if let pageIndex = self.currentlyVisiblePage()?.pageIndex() {
            FTCLSLog("\(helper): \(title), Page \(pageIndex+1)/\(self.pdfDocument.pages().count)")
        }
    }

    @objc
    func logPageTurn(index:Int) {
        FTCLSLog("Page Turn \(index+1)")
    }
}

//MARK:- Split Controller Helper Methods
@objc extension FTPDFRenderViewController {

    func toolbarHorizantalSizeClass() -> UIUserInterfaceSizeClass {
        guard let parentController = self.parent as? FTToolbarElements else { return UIUserInterfaceSizeClass.regular }
        return parentController.toolbarHorizontalSizeClass()
    }

    func isZoomHiddenInToolbar() -> Bool {
        guard let parentController = self.parent as? FTToolbarElements else { return true }
        return parentController.isZoomHidden()
    }
    
    func _scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture
        let captureInterval = 0.1
        
        if timeDiff > captureInterval {
            lastOffset = currentOffset
            lastOffsetCapture = currentTime
        }
    }

    func isLassoHiddenInToolbar() -> Bool {
        guard let parentController = self.parent as? FTToolbarElements else { return true }
        return parentController.isLassoHidden()
    }

    func setToolbarEnabled(_ isEnabled:Bool) {
        guard let parentController = self.parent as? FTToolbarElements else { return }
        parentController.setToolbarEnabled(isEnabled)
    }

    @objc func showCannotImportFile(onCompletion : @escaping () -> Void) {
        let alertController = UIAlertController(title: "",
                                                message: NSLocalizedString("UnlockNotebookToImportMessage", comment: "Unlock notebook"),
                                                preferredStyle: .alert);
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: { _ in
            onCompletion()
        })
        alertController.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil);
    }

}

extension FTPDFRenderViewController: FTOpenCloseDocumentProtocol {

    @objc func openRecentItem(shelfItemManagedObject: FTDocumentItemWrapperObject,
                              addToRecent: Bool)
    {
        (self.openCloseDocumentDelegate as? FTOpenCloseDocumentProtocol)?.openRecentItem(shelfItemManagedObject: shelfItemManagedObject, addToRecent: addToRecent)
    }

    @objc func closeDocument(shelfItemManagedObject: FTDocumentItemWrapperObject,
                             animate: Bool,
                             onCompletion: (() -> Void)?)
    {
        (self.openCloseDocumentDelegate as? FTOpenCloseDocumentProtocol)?.closeDocument(shelfItemManagedObject:shelfItemManagedObject,
                                                      animate:animate,
                                                      onCompletion:onCompletion)
    }
}

extension FTPDFRenderViewController : FTScanDocumentServiceDelegate
{
    func scanDocumentService(_ service: FTScanDocumentService, didFinishWith url: URL) {
        let item = FTImportItem(item: url as AnyObject, onCompletion: nil);
        self.beginImporting(items: [item]);
    }
}

extension FTPDFRenderViewController {
    @objc func canMoveToShelf(_ completion:@escaping (_ completed:Bool) ->Void) {
        FTNotebookUtils.checkIfAudioIsPlaying(forDocument: self.pdfDocument,
                                          alertMessage: NSLocalizedString("AudioRecoring_Message", comment: ""),
                                          onViewController: self, onCompletion: completion)

    }
}

extension FTPDFRenderViewController {
    @objc func removeAudioAnnotation(_ annotaion: FTAudioAnnotation) {
        (annotaion.associatedPage as? FTPageUndoManagement)?.removeAnnotations([annotaion])
    }
}

extension FTPDFRenderViewController {
    func pageControllerFor(activeAnnotationController : FTAnnotationEditController) -> FTPageViewController? {
        var controller: FTPageViewController?;
        let visibleControllers = self.visiblePageViewControllers();
        for eachController in visibleControllers {
            if let annotationController = eachController.activeAnnotationController,activeAnnotationController == annotationController {
                controller = eachController;
                break;
            }
        }
        //For Shapes Editing
        if isInZoomMode(), let zoomController =   self.zoomOverlayController.zoomContentController {
            for eachVC in zoomController.children {
                if let pageVC = eachVC as? FTPageViewController, let activeVC = pageVC.activeAnnotationController, activeAnnotationController == activeVC {
                    controller = pageVC
                    break
                }
            }
        }
        return controller;
    }
    
    func activeAnnotationController() -> FTAnnotationEditController? {
        var controller: FTAnnotationEditController?;
        let visibleControllers = self.visiblePageViewControllers();
        for eachController in visibleControllers {
            if let activeController = eachController.activeAnnotationController{
                controller = activeController;
                break;
            }
        }
        //For Shapes editing
        if isInZoomMode(), let zoomController =   self.zoomOverlayController.zoomContentController, let activeController =  zoomController.activeAnnotationController() {
            controller = activeController
        }
        return controller;
    }
    
    func getInputAccessoryViewForTextAnnotation(_ textAnnotation: FTTextAnnotationViewController) {
        //Remove toolbar before adding new
        self.removeInputAccessoryViewForTextAnnotation()
       
        let storyBoard = UIStoryboard(name: "FTTextInputUI", bundle: nil)
        let textToolbarController = storyBoard.instantiateViewController(withIdentifier: "FTTextToolBarViewController") as? FTTextToolBarViewController
        textToolbarController?.toolBarDelegate = textAnnotation
        textAnnotation.textSelectionDelegate = textToolbarController
        (self.textToolbarDelegate as? FTTextToolbarControllerDelegate)?.didAddTextToolBar?(textToolbarController!)
    }
    
    func removeInputAccessoryViewForTextAnnotation() {
        if let delegate = self.textToolbarDelegate as? FTTextToolbarControllerDelegate {
            delegate.didRemoveTextToolBar?()
        }
    }
}

extension FTPDFRenderViewController {
    @objc func postDocumentUpdateNotification() {
        self.shelfItemManagedObject.setTempFileModificationDate(self.shelfItemManagedObject.URL.fileModificationDate)
        NotificationCenter.default.post(name: NSNotification.Name.shelfItemUpdated, object: self.shelfItemManagedObject.shelfCollection, userInfo: [FTShelfItemsKey: [self.shelfItemManagedObject.documentItem]])
    }
}
extension FTPDFRenderViewController {
    @objc func showQuickCreateInfoTipIfNeeded() {
        if canShowQuickCreateInfoTip() == false {
            return
        }
        
        if let quickCreateInfoTipController = UIStoryboard(name: "FTNotebookMoreOptions", bundle: nil).instantiateViewController(withIdentifier: "FTQuickCreateInfoTipViewController") as? FTQuickCreateInfoTipViewController {
            quickCreateInfoTipController.modalPresentationStyle = .popover
            quickCreateInfoTipController.delegate = self
            let popoverPresentationController = quickCreateInfoTipController.popoverPresentationController;
            popoverPresentationController?.delegate = quickCreateInfoTipController
            if let sourceView = self.rightPanelSource(for: .more) {
                popoverPresentationController?.sourceView = sourceView
                popoverPresentationController?.sourceRect = sourceView.bounds;
            }
            popoverPresentationController?.backgroundColor = UIColor.init(hexString: "3E4652").withAlphaComponent(0.9);
            self.present(quickCreateInfoTipController, animated: true, completion: nil)
        }
    }
    
    private func canShowQuickCreateInfoTip() -> Bool {
        if !UserDefaults.standard.bool(forKey: "IsQuickCreateFirstTimeTap") {
            return false
        }
        if UIDevice.current.isIpad() {
            var visibleSceneCount: Int = 0
            UIApplication.shared.connectedScenes.forEach { (scene) in
                if scene.activationState == .foregroundActive {
                    visibleSceneCount += 1
                }
            }
            return self.isRegularClass() && visibleSceneCount == 1
        }
        //For iPhone
        return true
    }
    
    func showQuickNoteSaveControllerIfNeeded(sourceView: FTBackSourceItem) {
        if self.isRegularClass() {
            if let quickNoteSaveController = UIStoryboard(name: "FTNotebookMoreOptions", bundle: nil).instantiateViewController(withIdentifier: "FTQuickNoteSaveViewController") as? FTQuickNoteSaveViewController {
                quickNoteSaveController.delegate = self
                quickNoteSaveController.quickNoteTitle = self.shelfItemManagedObject.title
                quickNoteSaveController.popoverPresentationController?.backgroundColor = UIColor.appColor(.popoverBgColor)
                #if targetEnvironment(macCatalyst)
                quickNoteSaveController.preferredContentSize = CGSize(width: 300, height: 240);
                quickNoteSaveController.modalPresentationStyle = .popover;
                quickNoteSaveController.popoverPresentationController?.sourceItem = sourceView;
                self.present(quickNoteSaveController, animated: true);
                #else
                quickNoteSaveController.customTransitioningDelegate.sourceView = sourceView
                self.ftPresentModally(quickNoteSaveController, contentSize: CGSize(width: 300, height: 240), animated: true, completion: nil)
                #endif
            }
        } else { // Handled the compact mode Quick note dialogue with alert
            let headerTitle = NSLocalizedString("quickNoteSave.saveQuickNote", comment: "save quick note")
            let title = self.shelfItemManagedObject.title ?? ""

            let alertController = UIAlertController.init(title: headerTitle, message: nil, preferredStyle: .alert)
            weak var weakAlertController = alertController
            let saveAction = UIAlertAction(title: NSLocalizedString("save", comment: "Save"), style: .default, handler: { [weak self] _ in
                guard let self else { return }
                var text = weakAlertController?.textFields?.first?.text
                if(nil != text) {
                    text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
                if let enteredText = text, !enteredText.isEmpty {
                    let save: FTNotebookBackAction = FTSaveAction //Save action
                    self.back(toShelfButtonAction: save, with: enteredText)
                }
            })
            alertController.addAction(saveAction)
            let deleteAction = UIAlertAction(title: NSLocalizedString("quickNoteSave.deleteQuickNote", comment: "Delete Quick Note"), style: .destructive, handler: { [weak self] _ in
                guard let self else { return }
                let delete: FTNotebookBackAction = FTMoveToTrashAction //Save action
                self.back(toShelfButtonAction: delete, with: self.shelfItemManagedObject.title)
            })
            alertController.addAction(deleteAction)

            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: { _ in
                alertController.dismiss(animated: true)
            })
            alertController.addAction(cancelAction)
            cancelAction.setValue(UIColor.appColor(.black50), forKey: "titleTextColor")

            alertController.addTextField(configurationHandler: { (textFiled) in
                textFiled.autocapitalizationType = UITextAutocapitalizationType.words
                textFiled.setDefaultStyle(.defaultStyle)
                textFiled.setStyledPlaceHolder(NSLocalizedString("Untitled", comment: "Untitled"), style: .defaultStyle)
                textFiled.setStyledText(title)
            })
            self.present(alertController, animated: true, completion: nil);
        }
    }
    
    @objc func topPadding() -> CGFloat {
        var yOffSet: CGFloat = 0
    #if !targetEnvironment(macCatalyst)
        if self.pageLayoutHelper.layoutType == .horizontal
            , self.toolBarState() == .normal {
            yOffSet += self.deskToolBarHeight()
            self.contentHolderView.clipsToBounds = false;
        } else if (self.pageLayoutHelper.layoutType == .vertical && self.toolBarState() == .shortCompact) {
            yOffSet += self.deskToolBarHeight()
        }
    #endif
        return yOffSet
    }
}

extension FTPDFRenderViewController: FTQuickNoteSaveDelegate {
    func didSaveQuickCreatedNote(quickNoteVc: FTQuickNoteSaveViewController, noteTitle: String) {
        self.dismiss(animated: false) {
            var backAction: FTNotebookBackAction = FTSaveAction //Save action
            if self.shelfItemManagedObject.title == noteTitle {
                backAction = FTNormalAction //Normal action
            }
            //****************************** AutoBackup & AutoPublish
            if let shelfItem = self.shelfItemManagedObject.documentItem as? FTDocumentItemProtocol {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    FTENPublishManager.applyDefaultBackupPreferences(forItem: shelfItem, documentUUID: self.pdfDocument.documentUUID)
                })
            }
            //******************************
            self.back(toShelfButtonAction: backAction, with: noteTitle)
        }
    }
    
    @objc func renameShelfItem(title: String, onCompletion: @escaping (Bool) -> ()) {
        let shelfItem = self.shelfItemManagedObject.shelfItemProtocol
        let shelfCollection = shelfItem.shelfCollection
        runInMainThread {
            shelfCollection?.renameShelfItem(shelfItem, toTitle: title, onCompletion: {[weak self] (error, updatedShelfItem) in
                if(nil != error) {
                    UIAlertController.showConfirmationDialog(with: error!.description, message: "", from: self, okHandler: {
                    });
                    onCompletion(false);
                }
                else {
                    //**************************
                    if let documentItem = updatedShelfItem as? FTDocumentItemProtocol, let docUUID = documentItem.documentUUID {
                        FTCloudBackUpManager.shared.startPublish();
                        
                        if let shelfItem = updatedShelfItem,
                            FTENPublishManager.shared.isSyncEnabled(forDocumentUUID: docUUID) {
                            FTENPublishManager.recordSyncLog("User renamed notebook: \(String(describing: shelfItem.displayTitle))");
                            
                            let evernotePublishManager = FTENPublishManager.shared;
                            evernotePublishManager.updateSyncRecord(forShelfItem: shelfItem,
                                                                    withDocumentUUID: docUUID);
                            evernotePublishManager.startPublishing();
                        }
                        onCompletion(true);
                    }
                }
            })
        }
    }
    
    func didDeleteQuickCreatedNote(quickNoteVc: FTQuickNoteSaveViewController) {
        self.dismiss(animated: false) {
            self.back(toShelfButtonAction: FTNotebookBackAction.init(rawValue: 3), with: self.shelfItemManagedObject.title)
        }
    }
    
    @objc func deleteShelfItem(_ deletePermanently: Bool) {
        let shelfItem = self.shelfItemManagedObject.shelfItemProtocol
        runInMainThread { [weak self] in
            if let item = shelfItem as? FTDocumentItemProtocol {
                if deletePermanently {
                    shelfItem.shelfCollection.removeShelfItem(shelfItem, onCompletion: { [weak self](error, removedItem) in
                        self?.updatePublishedRecord(item: item,
                                                    isDeleted: true,
                                                    isMoved: false)
                    });
                }
                else {
                    FTNoteshelfDocumentProvider.shared.moveItemstoTrash([shelfItem],
                                                                        onCompletion:
                                                                            { (error, movedItems) in
                        if let item = movedItems.first
                        {
                            self?.updatePublishedRecord(item: item,
                                                        isDeleted: true,
                                                        isMoved: false)
                        }
                    })
                }
            }
        }
    }
    
    func updatePublishedRecord(item movedItem: FTShelfItemProtocol,
                                isDeleted: Bool = false,
                                isMoved: Bool = false)
    {
            guard let documentItem = movedItem as? FTDocumentItemProtocol,
                let documentUUID = documentItem.documentUUID else {
                    return;
            }
            
            let autobackupItem = FTAutoBackupItem(URL: documentItem.URL,
                                                  documentUUID: documentUUID);
            if(isDeleted) {
                FTSiriShortcutManager.shared.removeShortcutSuggestionForUUID(documentUUID)
                FTShortcutStorage.removeShortcutDataForUUID((documentUUID))
                FTCloudBackUpManager.shared.shelfItemDidGetDeleted(autobackupItem);
            }
            else {
                FTCloudBackUpManager.shared.startPublish();
            }
            
            let evernotePublishManager = FTENPublishManager.shared;
            if evernotePublishManager.isSyncEnabled(forDocumentItem: documentItem) {
                if(isDeleted) {
                    FTENPublishManager.recordSyncLog("User deleted notebook: \(String(describing: documentUUID))");
                    evernotePublishManager.disableSync(for: documentItem);
                    evernotePublishManager.disableBackupForShelfItem(withUUID: documentUUID);
                }
                else {
                    evernotePublishManager.updateSyncRecord(forShelfItem: documentItem,
                                                            withDocumentUUID: documentUUID)
                }
            }
    }

}

extension FTPDFRenderViewController: FTQuickNoteChangeTemplateDelegate {
    func didChangeTemplate(from viewController: FTQuickCreateInfoTipViewController) {
    }
}

extension FTPDFRenderViewController: FTLaserAnnotationHandler {
    @objc func clearLaserAnnotationsAction() {
        if let curPage = self.currentlyVisiblePage(),let window = self.view.window {
            self.laserStrokeStorage.clearAllAnnotations()
            NotificationCenter.default.post(name: .didClearLaserAnnotations,
                                            object: curPage,
                                            userInfo: [FTRefreshWindowKey:window]);
        }
    }
    
    func addLaserAnnotation(_ annotation: FTAnnotation, for page: FTPageProtocol) {
        self.laserStrokeStorage.addLaserAnnotation(annotation, for: page);
    }
    
    func laserAnnotations(for page: FTPageProtocol) -> [FTAnnotation] {
        return self.laserStrokeStorage.laserAnnotations(for: page);
    }
}

extension FTPDFRenderViewController {
    @objc func movePages(fromIndexes: [Int], toIndex: Int) {
        if var array = self.eachPageViewArray as? [FTPageViewController?] {
            array.move(fromOffsets: IndexSet(fromIndexes), toOffset: toIndex)
            self.eachPageViewArray = NSMutableArray(array: array)
        }
    }
}

extension UIDevice {
    static var isLandscapeOrientation: Bool {
        var isLandscape = false
        if UIDevice.current.orientation.isValidInterfaceOrientation {
            isLandscape = UIDevice.current.orientation.isLandscape
        } else {
            let screenBounds = UIScreen.main.bounds
            if screenBounds.width > screenBounds.height {
                isLandscape = true
            }
        }
        return isLandscape
    }
}
extension FTPDFRenderViewController: FTPasswordCallbackProtocol {
    func cancelButtonAction() {
        //self.refreshPasswordSetting()
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func didFinishVerification(onController controller: UIViewController, currentPassword: String = "") {
        guard let notebookDoc = self.pdfDocument as? FTDocument else {
            return
        }

        if let passwordController = controller as? FTPasswordViewController {
            if passwordController.passwordFlow == .setPassword {
                let setPassword = passwordController.getRequiredFieldText(field: .setPassword)
                let setHint = passwordController.getRequiredFieldText(field: .setHint)
                notebookDoc.pin = setPassword
                notebookDoc.setHint(setHint)
                if let document = self.pdfDocument {
                    FTBiometricManager.keychainSetIsTouchIDEnabled(passwordController.isTouchIDEnabled, withPin: setPassword, forKey: document.documentUUID);
                }
                self.view.window?.isUserInteractionEnabled = false;
                passwordController.dismiss(animated: true) {
                    let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Saving", comment: "Saving"));
                    notebookDoc.secureDocument(onCompletion: {[weak loadingIndicatorViewController,weak self] _ in
                        //self.refreshPasswordSetting()
                        loadingIndicatorViewController?.hide();
                        self?.view.window?.isUserInteractionEnabled = true;
                    }) //should we consider synchronization?
                };
            } else {
                let userEnteredPin: String! = currentPassword
                if notebookDoc.pin == userEnteredPin {
                    //Auth success
                    if passwordController.toDisablePassword {
                        //Decrypt contents and remove key file
                        notebookDoc.setHint(nil)
                        self.view.window?.isUserInteractionEnabled = false;
                        passwordController.dismiss(animated: true) {
                            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Saving", comment: "Saving"));
                            notebookDoc.deSecureDocument(onCompletion: {[weak loadingIndicatorViewController,weak self] _ in
                                let uuid = (notebookDoc as? FTDocumentProtocol)!.documentUUID
                                FTDocument.keychainRemovPinFroKey(uuid)
                                FTBiometricManager.keychainRemovIsTouchIDEnabledFroKey(uuid)
                                //self.refreshPasswordSetting();
                                self?.view.window?.isUserInteractionEnabled = true
                                loadingIndicatorViewController?.hide()
                            });
                        }
                    } else {
                        //Decypt and re encrypt key file only
                        var newPin: String?;
                        if passwordController.isTouchIDEnabledAtPresent != passwordController.isTouchIDEnabledManually {
                            newPin = userEnteredPin
                        }
                        let newPassword = passwordController.getRequiredFieldText(field: .newPassword)
                        if !newPassword.isEmpty {
                            newPin = newPassword
                        }
                        let newHint = passwordController.getRequiredFieldText(field: .changeHint)
                        notebookDoc.setHint(newHint)
                        self.view.window?.isUserInteractionEnabled = false
                        passwordController.dismiss(animated: true) {
                            let loadingIndicatorViewController = FTLoadingIndicatorViewController.show(onMode: .activityIndicator, from: self, withText: NSLocalizedString("Saving", comment: "Saving"));
                            notebookDoc.updatePin(newPin, onCompletion: {[weak loadingIndicatorViewController,weak self] _ in
                                //self.refreshPasswordSetting();
                                loadingIndicatorViewController?.hide()
                                //update keychain if evernote sync is enabled
                                let evernotePublishManager = FTENPublishManager.shared
                                let uuid = (notebookDoc as? FTDocumentProtocol)!.documentUUID
                                if true == evernotePublishManager.isSyncEnabled(forDocumentUUID: uuid) {
                                    FTDocument.keychainSet(newPin, forKey: uuid)
                                }
                                FTBiometricManager.keychainSetIsTouchIDEnabled(passwordController.isTouchIDEnabled, withPin: newPin, forKey: uuid)
                                self?.view.window?.isUserInteractionEnabled = true
                            })
                        }
                    }
                    //self.refreshPasswordSetting()
                } else {
                    //Auth failed
                    var error: NSError?
                    if let hint = notebookDoc.getHint() {
                        let dict = ["hint": hint]
                        error = NSError(domain: "com.Noteshelf.FluidTouch", code: 0, userInfo: dict)
                    }
                    let notification = Notification(name: Notification.Name(rawValue: "FTDidFailedToAuthenticate"), object: error, userInfo: nil)
                    NotificationCenter.default.post(notification)
                }
            }
        }
    }
}

extension FTPDFRenderViewController : FTExportActivityDelegate{
    func exportActivity(_ manager : FTExportActivityManager, didExportWith mode : RKExportMode) {
        endExport()
    }
    
    func exportActivity(_ manager : FTExportActivityManager, didFailWith error : Error, mode : RKExportMode) {
        endExport()
    }
    
    func exportActivity(_ manager : FTExportActivityManager, didCancelWith mode: RKExportMode) {
        endExport()
    }
    
    private func endExport() {
        self.exportManager = nil
        do {
            let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
            let tempFileLoc = (cacheDirectory)! + "/TEMP_CACHE_DIR"
            try FileManager.default.removeItem(atPath: tempFileLoc)
        }
        catch {
            FTCLSLog("FTSharing failed due to \(error.localizedDescription)")
        }
    }
}

extension FTPDFRenderViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let isUndoRedoGestureRecognized = self.undoRedoGestureDetector.isUndoRedoGestureRecognized(gesture: gestureRecognizer)
        if isUndoRedoGestureRecognized, let firstPageController = self.firstPageController() {
            return firstPageController.shouldAcceptTouch(touch: touch)
        }
        return true
    }
}

@objc extension FTPDFRenderViewController {
    var bookScaleAnim: Bool {
        return FTDeveloperOption.bookScaleAnim
    }
}
