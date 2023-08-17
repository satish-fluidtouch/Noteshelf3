//
//  FTExportTarget.swift
//  Noteshelf
//
//  Created by Matra on 24/07/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTExportDelegate: AnyObject {
    func didExport()
    func cancelExport()
}

class FTExportTarget: NSObject {

    var pages: [FTPageProtocol]?
    var notebook: FTDocumentProtocol?;
    var shouldHideNBK = false;
    var pagesaveType: FTShareType = .share
    var shareOption: FTShareOption = .currentPage
    var supportingExportFormats: [RKExportFormat] {
        return [kExportFormatImage, kExportFormatPDF, kExportFormatNBK];
    }
    
    var properties = FTExportProperties()
    
    var itemsToExport: [FTItemToExport] = [FTItemToExport]() {
        didSet {
            self.properties.hidePageTemplate = FTUserDefaults.showPageTemplate;
            self.properties.includesPageFooter = FTUserDefaults.exportPageFooter

            let formatIndex = FTUserDefaults.exportFormat();
            
            for exportFormatIteration in self.supportingExportFormats {
                if Int(exportFormatIteration.rawValue) == formatIndex {
                    self.properties.exportFormat = exportFormatIteration;
                }
            }
        }
    }
    
    //Methods
    func supportedOptions(forExportFormat exportFormat: RKExportFormat) -> [FTExportOptions] {
        switch exportFormat {
        case kExportFormatImage, kExportFormatPDF:
            return [.pageTemplate, .coverPage, .pageFooter];
        default:
            return [];
        }
    }
}
