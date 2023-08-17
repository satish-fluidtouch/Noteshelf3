//
//  FTSaveAsTemplateActivity.swift
//  Noteshelf
//
//  Created by Amar on 28/10/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSaveAsTemplateActivity: FTCustomActivity {
    private var progress = Progress();
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType.init(rawValue: "kExportModeSaveAsTemplate")
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("SaveAsTemplate", comment: "Save As Template")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "Targets/Activity/save_as_template_alt")
    }
    
    override func perform() {
        if self.exportItems.isEmpty {
            self.didCancelExport();
        }
        else {
            self.progress.totalUnitCount = Int64(self.exportItems.count);
            startExportingWith("Saving", progress: progress);
            saveTemplates(self.exportItems, items: nil)
        }
    }
}


extension FTSaveAsTemplateActivity
{
    private func saveTemplates(_ exportItems: [FTExportItem]?, items: [FTExportItem]?) {
        var mutableExportItems = exportItems
        var generatedItems = items
        if generatedItems == nil {
            generatedItems = [FTExportItem]()
        }
        
        if let item = mutableExportItems?.first {
            let contentGenerator = FTNSTemplateContentGenerator()
            contentGenerator.generateTemplateContent(forItem: item) { [weak self] (item, error, result) in
                self?.progress.completedUnitCount += 1;
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
