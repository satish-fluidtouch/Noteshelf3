//
//  FTGeneralSettingsModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 04/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTGeneralSettingsModel: String {
    // Section - 0
    case lockwithfaceidandPasscode = "Lock with Face ID & Passcode"
    case require = "Require"
    
    // Section - 1
    case notebookScrolling = "Notebook Scrolling"
    case toolbarplacement = "Toolbar Placement"
    case hideAppinPresentMode = "Hide App UI in Present Mode"
    case allowHyperlinks = "Allow Hyperlinks"

    // Section - 2
    case coverStyle = "Cover Style"
    case paperTemplate = "Paper Template"
    
    
    var detailType: FTSettingDetailType {
        var type: FTSettingDetailType = .empty
        
        switch self {
        case .lockwithfaceidandPasscode:
            type = .toggle
        case .require:
            type = .navigation
        case .notebookScrolling:
            type = .segment
        case .toolbarplacement:
            type = .segment
        case .hideAppinPresentMode:
            type = .toggle
        case .allowHyperlinks:
            type = .toggle
        case .coverStyle:
            type = .navigation
        case .paperTemplate:
            type = .navigation
        }
        return type
    }
}
enum FTSettingDetailType {
    case navigation
    case toggle
    case segment
    case empty
}
enum FTGeneralSettingsSectionModel:CaseIterable {
    case privacy
    case notebook
    case quicknote
    
    var sectionTitle:String{
        let title:String
        switch self{
        case .privacy:
            title = "PRIVACY"
        case .notebook:
            title = "NOTEBOOK"
        case .quicknote:
            title = "QUICK NOTE"
        }
        return title
    }
    
    var rowData: [FTGeneralSettingsModel] {
        switch self {
        case .privacy:
          return [FTGeneralSettingsModel.lockwithfaceidandPasscode, FTGeneralSettingsModel.require]
        case .notebook:
            return  [FTGeneralSettingsModel.notebookScrolling, FTGeneralSettingsModel.toolbarplacement,FTGeneralSettingsModel.hideAppinPresentMode,FTGeneralSettingsModel.allowHyperlinks]
        case .quicknote:
            return  [FTGeneralSettingsModel.coverStyle, FTGeneralSettingsModel.paperTemplate]

        }
    }
}
