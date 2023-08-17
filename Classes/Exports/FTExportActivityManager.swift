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
    var targetShareButton : UIView?
    weak var delegate : FTExportActivityDelegate?
    private var activityViewController : UIActivityViewController!
    
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
                self.activityViewController.dismiss(animated: true, completion: nil);
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
            self.activityViewController = UIActivityViewController(activityItems: items, applicationActivities: customActivities);
            let shareNavigationController = UINavigationController(rootViewController: self.activityViewController)
            shareNavigationController.modalPresentationStyle = .formSheet
            shareNavigationController.isNavigationBarHidden = true
            shareNavigationController.presentationController?.delegate = baseViewController as? UIAdaptivePresentationControllerDelegate
            self.activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
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
            baseViewController.present(shareNavigationController, animated: true, completion: nil);
        }
    }
}
