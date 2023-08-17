//
//  FTFilesDriveActivity.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 11/11/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFilesDriveActivity: FTCustomActivity {
    private var progress = Progress();
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType.init(rawValue: "kExportModeFilesDrive")
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("Finder", comment: "Files")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "doc-icon-folder")
    }
    override func activityDidFinish(_ completed: Bool) {
        super.activityDidFinish(completed)
    }
    override func perform() {
        if self.exportItems.isEmpty {
            self.didCancelExport();
        }
        else {
            if let exporter = FTFilesDriveExporter.init(delegate: self) {
                exporter.exportItems = self.exportItems;
                exporter.exportFormat = self.exportFormat
                exporter.baseViewController = self.baseViewController;
                exporter.export();
            }
        }
    }
}
