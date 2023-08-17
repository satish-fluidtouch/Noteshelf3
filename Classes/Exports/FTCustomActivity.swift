//
//  FTCustomActivity.swift
//  Noteshelf
//
//  Created by Matra on 14/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCustomActivity: UIActivity {
    private var smartProgress : FTSmartProgressView?;

    private(set) var exportItems : [FTExportItem] = [FTExportItem]();
    private(set) weak var baseViewController : UIViewController?
    private(set) var exportFormat : RKExportFormat = kExportFormatNBK;

    static func activity(type : RKExportMode,
                         format : RKExportFormat,
                         items : [FTExportItem],
                         baseViewController : UIViewController) -> FTCustomActivity
    {
        let activity : FTCustomActivity;
        switch type {
        case kExportModeSaveAsTemplate:
            activity = FTSaveAsTemplateActivity(format: format,
                                                baseViewController: baseViewController);
        case kExportModeEvernote:
            activity = FTEvernoteActivity(format: format,
                                          baseViewController: baseViewController);
        case kExportModeFilesDrive:
                activity = FTFilesDriveActivity(format: format,
                                                baseViewController: baseViewController);
        default:
            activity = FTCustomActivity(format: format, baseViewController: baseViewController);
            fatalError("Activity should be created")
        }
        activity.exportItems = items;
        return activity;
    }

    required init(format: RKExportFormat,
                  baseViewController inBaseVC : UIViewController) {
        baseViewController = inBaseVC;
        exportFormat = format;
        super.init()
    }

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType.init(rawValue: self.activityTitle ?? "")
    }
    
    override var activityTitle: String? {
        return "No name";
    }
    
    override var activityImage: UIImage? {
        return nil;
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func perform() {
        activityDidFinish(true)
    }
}

extension FTCustomActivity : FTExporterDelegate
{
    func didEndExport(withMessage message: String!) {
        self.smartProgress?.hideProgressWithSuccessIndicator();
        activityDidFinish(true);
    }
    
    func didCancelExport() {
        self.smartProgress?.hideProgressIndicator();
        activityDidFinish(false);
    }
    
    func didFailExportWithError(_ error: Error!, withMessage message: String!) {
        self.smartProgress?.hideProgressIndicator();
        if let vc = self.baseViewController,
            let errorToShow = error  {
            (errorToShow as NSError).showAlert(from: vc);
        }
        activityDidFinish(false);
    }
}

 extension FTCustomActivity
{
    func startExportingWith(_ message: String,progress : Progress) {
        self.smartProgress = FTSmartProgressView(progress: progress);
        if let vc = self.baseViewController {
            self.smartProgress?.showProgressIndicator(NSLocalizedString(message, comment: "Saving..."),
                                               onViewController: vc);
        }
    }
}
