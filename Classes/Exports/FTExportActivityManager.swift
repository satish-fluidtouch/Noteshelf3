//
//  FTShareManager.swift
//  Noteshelf
//
//  Created by Matra on 06/08/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

protocol FTExportActivityDelegate: AnyObject {
    func exportActivity(_ manager : FTExportActivityManager, didExportWith mode : RKExportMode)
    func exportActivity(_ manager : FTExportActivityManager, didFailWith error : Error, mode : RKExportMode)
    func exportActivity(_ manager : FTExportActivityManager, didCancelWith mode: RKExportMode)
}

class FTExportActivityManager: NSObject {

    var exportFormat : RKExportFormat = kExportFormatNBK;
    var exportItems : [FTExportItem]?
    var baseViewController : UIViewController?
    var targetShareButton: Any?
    weak var delegate : FTExportActivityDelegate?
    private var activityViewController : UIActivityViewController!
    
#if targetEnvironment(macCatalyst)
    private var onCompletion: ((Error?,RKExportMode)->())?;
    private var FilesExporter: FTFilesDriveExporter?;
#endif
    
    private func mappingActivity(_ name : String) -> RKExportMode {
        var deskMode : RKExportMode = kExportModeNone;
        switch name {
        case "kExportModeSaveAsTemplate":
            deskMode = kExportModeSaveAsTemplate;
        case "kExportModeEvernote":
            deskMode = kExportModeEvernote;
        case "kExportModeSchoolwork":
            deskMode = kExportModeSchoolwork
        case "kExportModeFilesDrive":
            deskMode = kExportModeFilesDrive
        default:
            break;
        }
        return deskMode;
    }
    
    @nonobjc private func supportedTargets() -> [RKExportMode] {
        var targets = [RKExportMode]();
        switch exportFormat {
        case kExportFormatPDF, kExportFormatImage:
            #if !targetEnvironment(macCatalyst)
            targets = [kExportModeEvernote];
            #endif
        case kExportFormatNBK:
            targets = [kExportModeSaveAsTemplate]            
        default:
            print("Default");
        }
        #if targetEnvironment(macCatalyst)
            targets.append(kExportModeFilesDrive)
        #endif
        
        return targets
    }
        
    func startExportingToActivity() -> Progress {
        let progress : Progress = Progress.init()
        progress.totalUnitCount = 1
        self.exportFile { (error, mode) in
            runInMainThread {
#if targetEnvironment(macCatalyst)
                self.onCompletion = nil;
                self.baseViewController?.dismiss(animated: true);
#else
                self.activityViewController.dismiss(animated: true, completion: nil);
#endif
                if nil != error {
                    self.delegate?.exportActivity(self, didFailWith: error!, mode: mode)
                } else {
                    progress.completedUnitCount += 1
                    self.delegate?.exportActivity(self, didExportWith: mode)
                }
            }
        }
        
        return progress
    }
    private func exportFile(onCompletion : @escaping (Error?,RKExportMode)->()) {
        guard let baseViewController = self.baseViewController else {
            onCompletion(NSError.init(domain: "Noteshelf", code: 1012, userInfo: [NSLocalizedDescriptionKey: "missing baseview controller"]),kExportModeNone)
            return
        }

        if let ftExportItems = self.exportItems {
            let supportedTargets = self.supportedTargets()
            var customActivities = [FTCustomActivity]();
            
            var items = [URL]();
            items = ftExportItems.map({ (exportItem) -> URL in
                if let url = exportItem.representedObject as? URL {
                    return url;
                }
                return URL(fileURLWithPath: exportItem.representedObject as! String);
            });
            
            var hasAgroupItem : Bool = false
            for item in ftExportItems where item.isGroupItem {
                hasAgroupItem = true
            }
            for activityMode in supportedTargets {
                if hasAgroupItem && activityMode == kExportModeEvernote {
                    continue
                }
                let activity = FTCustomActivity.activity(type: activityMode,
                                                         format: self.exportFormat,
                                                         items : ftExportItems,
                                                         baseViewController: baseViewController);
                customActivities.append(activity);
                
            }
            if ftExportItems.count == 1,
               let exportItem = ftExportItems.first,
               let childItems = exportItem.childItems {
                var exportItemurl : URL;
                if let urlString = exportItem.representedObject as? URL {
                    exportItemurl = urlString;
                }
                else {
                    exportItemurl = URL(fileURLWithPath: exportItem.representedObject as! String);
                }
                if(exportItemurl.pathExtension.lowercased() != "zip") {
                    items = childItems.map({ (exportItem) -> URL in
                        if let url = exportItem.representedObject as? URL {
                            return url
                        }
                        return URL(fileURLWithPath: exportItem.representedObject as! String);
                    });
                }
            }
            let actController = UIActivityViewController(activityItems: items, applicationActivities: customActivities);
            self.activityViewController = actController
            self.activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
#if targetEnvironment(macCatalyst)
                if nil == error
                    , let str = activityType?.rawValue
                    , str == "kExportModeFilesDrive" {
                    self?.exportToFinder(onCompletion);
                    return;
                }
#endif
                if(nil != error) {
                    onCompletion(error,kExportModeNone);
                }
                else {
                    var typeToReturn = kExportModeNone;
                    if let activityName = activityType?.rawValue {
                        typeToReturn = self?.mappingActivity(activityName) ?? kExportModeNone;
                    }
                    onCompletion(nil,typeToReturn);
                }
            }
#if targetEnvironment(macCatalyst)
            actController.modalPresentationStyle = .popover;
            actController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.none
            // To have popover visible on top(during shortcut action from toolbar)
            if let item = self.targetShareButton as? NSToolbarItem {
                actController.popoverPresentationController?.sourceItem = item
            } else {
                actController.popoverPresentationController?.sourceView = baseViewController.view;
                var rect = CGRect(x: baseViewController.view.bounds.midX, y: baseViewController.view.bounds.height - 44 - 20, width: 1, height: 1)
                if let shareFormatHostingVc = baseViewController as? FTShareFormatHostingController, shareFormatHostingVc.canShowSaveToCameraRollButton {
                    rect.origin.x += (0.5 * rect.origin.x)
                }
                actController.popoverPresentationController?.sourceRect = rect
            }
            baseViewController.present(actController, animated: true, completion: nil)
#else
            let shareNavigationController = UINavigationController(rootViewController: self.activityViewController)
            shareNavigationController.modalPresentationStyle = .formSheet
            shareNavigationController.isNavigationBarHidden = true
            shareNavigationController.presentationController?.delegate = baseViewController as? UIAdaptivePresentationControllerDelegate
            baseViewController.present(shareNavigationController, animated: true, completion: nil);
#endif
        }
    }
}



#if targetEnvironment(macCatalyst)
extension FTExportActivityManager: FTExporterDelegate {
    func exportToFinder(_ onCompeltion: @escaping ((Error?,RKExportMode)->())) {
        if let exporter = FTFilesDriveExporter.init(delegate: self) {
            self.FilesExporter = exporter;
            exporter.exportItems = self.exportItems;
            exporter.exportFormat = self.exportFormat
            exporter.baseViewController = self.baseViewController;
            exporter.export();
            self.onCompletion = onCompeltion;
        }
    }
    
    func didCancelExport() {
        onCompletion?(NSError.exportCancelError(),kExportModeFilesDrive);
    }
    
    func didFailExportWithError(_ error: Error!, withMessage message: String!) {
        onCompletion?(error,kExportModeFilesDrive);
    }
    
    func didEndExport(withMessage message: String!) {
        onCompletion?(nil,kExportModeFilesDrive);
    }
}

#endif

