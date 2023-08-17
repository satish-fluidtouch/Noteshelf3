//
//  FTEvernoteActivity.swift
//  Noteshelf
//
//  Created by Amar on 28/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import ZipArchive
import FTCommon

class FTEvernoteActivity: FTCustomActivity {
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType.init(rawValue: "kExportModeEvernote")
    }
    
    override var activityTitle: String? {
        return "Evernote"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "Targets/Activity/Evernote")
    }
    
    override func perform() {
        let account = FTAccountInfoRequestEvernote.init()
        let isLoggedIn = account.isLoggedIn()
        if isLoggedIn {
            exportToEvernote()
        } else {
            if let vc = self.baseViewController {
                account.showLoginView(withViewController: vc) { [weak self] (success) in
                    if success {
                        self?.exportToEvernote()
                    } else {
                        self?.activityDidFinish(false);
                        UIAlertController.showAlert(withTitle: "", message: NSLocalizedString("AuthenticationFailed", comment: "Unable to authenticate"),
                                                    from: vc,
                                                    withCompletionHandler: nil);
                    }
                }
            }
        }
    }

    private func exportToEvernote() {
        if let exporter = FTEvernoteExporter.init(delegate: self) {
            startExportingWith("Exporting",progress: exporter.progress);
            runInMainThread {
                exporter.exportItems = self.exportItems
                exporter.exportFormat = self.exportFormat
                exporter.export()
            }
        }
    }
}
