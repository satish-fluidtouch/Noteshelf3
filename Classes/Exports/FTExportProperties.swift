//
//  FTExportProperties.swift
//  Noteshelf
//
//  Created by Siva on 16/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTExportProperties {
    var exportFormat: RKExportFormat = kExportFormatImage

    var includesPageFooter: Bool = true
    var includeCoverPage: Bool = true
    var hidePageTemplate: Bool = false

    static func getSavedProperties() -> FTExportProperties {
        let properties = FTExportProperties()
        properties.exportFormat =  RKExportFormat(rawValue: UInt32(FTUserDefaults.exportFormat()))
        properties.hidePageTemplate = !FTUserDefaults.showPageTemplate
        properties.includeCoverPage = FTUserDefaults.exportCoverPage
        properties.includesPageFooter = FTUserDefaults.exportPageFooter
        return properties
    }

    static func saveAsTemplateProperties() -> FTExportProperties {
        let properties = FTExportProperties()
        properties.exportFormat =  kExportFormatNBK
        properties.hidePageTemplate = false
        properties.includeCoverPage = true
        properties.includesPageFooter = true
        return properties
    }

    
}
