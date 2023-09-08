//
//  FTExportProgressManager.swift
//  Noteshelf
//
//  Created by Simhachalam on 10/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum ExportState {
    case notStarted
    case intializationBegan
    case generationBegan
    case generationCompleted
    case exportBegan
    case exportCompleted
}

enum FTExportType {
    case saveAsTemplate
    case shareAsTemplate
}

class FTExportProgressManager: NSObject {
    private var state = ExportState.notStarted;
    var exportTarget : FTExportTarget!
    var targetShareButton: Any?
    var exportType = FTExportType.shareAsTemplate
    var exportItems : [FTExportItem]?
    weak var delegate : FTExportActivityDelegate?
    let activityManager = FTExportActivityManager();
    private var contentGenerator: FTExportContentGenerator!;
    
    private var smartProgress : FTSmartProgressView?;
    
    private weak var presentingController : UIViewController?;
    
    func startExportingProcess(onViewController : UIViewController) {

        self.presentingController = onViewController;
        DispatchQueue.main.async(execute: {
            if nil != self.exportTarget.pages
                || self.exportTarget.properties.exportFormat == kExportFormatNBK {
                self.initialiseExportHandlerAndGenerator(onViewController);
            }
            else {
                if self.exportTarget.notebook == nil {
                    self.initialiseExportHandlerAndGenerator(onViewController);
                }
                else {
                    self.exportTarget.pages = self.exportTarget.notebook?.pages();
                    if nil != self.exportTarget.pages {
                        self.initialiseExportHandlerAndGenerator(onViewController);
                    }
                }
            }
        });
    }
    
    //MARK:- Navigations
    @IBAction func backClicked() {
//        self.completeExport();
    }
    
    @IBAction func closeClicked() {
//        self.completeExport();
        self.dismiss();
    }
    
    @IBAction func shareNow() {
        self.state = .exportBegan;
        _ = self.activityManager.startExportingToActivity()
    }
}

private extension FTExportProgressManager {
    
    func dismiss() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Notification_ExportComplete), object: nil);
        self.smartProgress = nil;
    }
    
    func initialiseExportHandlerAndGenerator(_ viewController : UIViewController) {
        self.state = .intializationBegan;
        
        self.activityManager.delegate = self.delegate;
        //TODO: EXport
        self.activityManager.exportFormat = RKExportFormat(UInt32(self.exportTarget.properties.exportFormat.rawValue));
        
        let exportFormat = self.exportTarget.properties.exportFormat;
        
        if self.exportTarget.pages?.count == 0
            && exportFormat != kExportFormatNBK {
            runInMainThread {
                UIAlertController.showAlert(withTitle: "",
                                            message: NSLocalizedString("NoNotesToExport",
                                                                       comment: "No Notes To Export"),
                                            from: viewController,
                                            withCompletionHandler: {
                                                self.closeClicked();
                });
            };
        }
        else {
            if self.exportType == .shareAsTemplate {
                self.generateContentAndUpload(viewController);
            } else if self.exportType == .saveAsTemplate {
                self.genererateContentAndSaveAsTemplate(viewController)
            }
        }
    }
    
    func generateContentAndUpload(_ viewController : UIViewController)
    {
        self.state = .generationBegan;
        
        self.contentGenerator = FTExportContentGenerator.init(target: self.exportTarget,
                                                              onViewController: self.presentingController);
        self.contentGenerator.clearCache()
        self.smartProgress = FTSmartProgressView.init(progress: self.contentGenerator.progress);
        self.smartProgress?.showProgressIndicator(NSLocalizedString("Generating", comment: "Generating"),
                                                  onViewController: viewController);
        
        self.contentGenerator.generateContents { (cancelled, error,contents) in
                runInMainThread {
                    self.smartProgress?.hideProgressIndicator();
                    self.smartProgress = nil;
                    if self.exportTarget.pagesaveType == .share{
                        if(cancelled) {
                            self.delegate?.exportActivity(self.activityManager, didCancelWith: kExportModeNone)
                        }
                        else if(nil != error) {
                            self.state = .generationCompleted;
                            error?.showAlert(from: self.presentingController)
                        } else {
                            self.state = .generationCompleted;
                            self.activityManager.exportItems = contents;
                            self.exportItems = contents
                            self.activityManager.targetShareButton = self.targetShareButton
                            self.activityManager.baseViewController = viewController;
                            self.shareNow();
                        }
                    }else{
                        if self.exportTarget.pagesaveType == .savetoCameraRoll{
                            var title = "shortcut.toast.savePageAsPhoto".localized
                            if self.exportTarget.shareOption == .allPages {
                                title = "shortcut.toast.saveAllPagesAsPhotos".localized
                            }
                            let config = FTToastConfiguration(title: title)
                            FTToastHostController.showToast(from: self.presentingController ?? UIViewController(), toastConfig: config)
                        }
                    }
            }
        }
    }
    
    func genererateContentAndSaveAsTemplate(_ viewController : UIViewController) {
        self.state = .generationBegan;
        self.contentGenerator = FTExportContentGenerator.init(target: self.exportTarget,
                                                              onViewController: self.presentingController);
        self.contentGenerator.clearCache()
        self.smartProgress = FTSmartProgressView.init(progress: Progress());
        self.smartProgress?.showProgressIndicator(NSLocalizedString("Saving", comment: "Saving"),
                                                  onViewController: viewController);
        self.contentGenerator.generateContents { (cancelled, error,contents) in
            runInMainThread {
                if(cancelled) {
                    self.smartProgress?.hideProgressIndicator()
                    self.delegate?.exportActivity(self.activityManager, didCancelWith: kExportModeNone)
                }
                else if let error {
                    self.smartProgress?.hideProgressIndicator()
                    self.state = .generationCompleted;
                    self.delegate?.exportActivity(self.activityManager, didFailWith: error, mode: kExportModeNone)
                    error.showAlert(from: self.presentingController)
                } else {
                    self.state = .generationCompleted;
                    self.exportItems = contents
                    self.saveTemplates(self.exportItems, items: nil)
                }
            }
        }
    }
    
    private func saveTemplates(_ exportItems: [FTExportItem]?, items: [FTExportItem]?) {
        var mutableExportItems = exportItems
        var generatedItems = items
        if generatedItems == nil {
            generatedItems = [FTExportItem]()
        }
        if let item = mutableExportItems?.first {
            let contentGenerator = FTNSTemplateContentGenerator()
            contentGenerator.generateTemplateContent(forItem: item) { [weak self]  (item, error, result) in
                if let err = error {
                    self?.didFailExportWithError(err, withMessage: "");
                }
                else {
                    generatedItems?.append(item!)
                    mutableExportItems?.removeFirst()
                    self?.didEndExport(withMessage: "ExportComplete".localized);
                }
            }
        } else {
            self.didEndExport(withMessage: "ExportComplete".localized);
        }
    }
}

extension FTExportProgressManager {
    func pauseExportOperation() {
        self.contentGenerator?.progress.pause()
    }
    
    func resumeExportOperation() {
        self.contentGenerator?.progress.resume()
    }
}

extension FTExportProgressManager: FTExporterDelegate {
    func didEndExport(withMessage message: String!) {
        self.smartProgress?.hideProgressWithSuccessIndicator()
        self.delegate?.exportActivity(self.activityManager, didExportWith: kExportModeNone)
    }
    
    func didFailExportWithError(_ error: Error!, withMessage message: String!) {
        self.smartProgress?.hideProgressIndicator()
        if let vc = self.presentingController,
            let errorToShow = error  {
            (errorToShow as NSError).showAlert(from: vc);
        }
        self.delegate?.exportActivity(self.activityManager, didFailWith: error, mode: kExportModeNone)
    }
    
    func didCancelExport() {
        self.smartProgress?.hideProgressIndicator()
        self.delegate?.exportActivity(self.activityManager, didCancelWith: kExportModeNone)
    }
    
}
