//
//  FTFeatureConfigHelper.swift
//  Noteshelf3
//
//  Created by Fluid Touch on 11/06/24.
//  Copyrighst © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTConfigurationType: String {
    case eGurkul
}

enum FTDisabledFeature: String {
    case NotebookCreation = "Notebook Creation"
    case Supports_NBEditing = "Supports NB Editing"
    case CategoryCreation = "Category Creation"
    case ImportDocument = "Import Document"
    case ScanDocument  = "Scan Document"
    case Import_Apple_Watch  = "Import from Apple Watch"
    case Duplicate  = "Duplicate"
    case Share  = "Share"
    case Delete  = "Delete"
    case ChangeCover  = "Change Cover"
    case Autobackup  = "Auto backup"
    case Templates  = "Templates"
    case Import_Custom_Templates  = "Import Custom Templates"
    case Noteshelf_AI  = "Noteshelf AI"
    case Export  = "Export"
    case AddSiri  = "Add to Siri"
    case EvernoteSync  = "Evernote Sync"
    case Allow_hyperlinks  = "Allow hyperlinks"
    case Widgets  = "Widgets"
    case Siri_shortcuts  = "Siri shortcuts"
    case SupportsPassword  = "Supports Password"
    case SupportsUnfiled  = "Supports Unfiled"    
}

class FTFeatureConfigHelper: NSObject {
    static let shared = FTFeatureConfigHelper()
    
    private var featuresConfig: [String: Any]?
    
    private override init() {
        super.init()
    }
    
    public func configure() {
        if let url = Bundle.main.url(forResource: "ConfigurableFeatures", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let config = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            featuresConfig = config
        }
    }
    
    func isFeatureEnabled(_ feature: FTDisabledFeature, forConfig config: FTConfigurationType = FTConfigurationType.eGurkul) -> Bool {
        guard let config = featuresConfig?[config.rawValue] as? [String: Any],
              let isEnabled = config[feature.rawValue] as? Bool else {
            return false
        }
        return isEnabled
    }

}
