//
//  FTTextLinkModels.swift
//  Noteshelf3
//
//  Created by Narayana on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTTextLinkViewModel {
    let linkSection = FTLinkSection()
    let textSection = FTTextSection()
}

struct FTLinkSection {
    var header: String = "LINK"
    var options: [FTLinkOption] = FTLinkOption.allCases
}

enum FTLinkOption: String, CaseIterable {
    case goToPage = "Go to Page"
    case linkSettings = "Link Settings"
    case editLinkContent = "Edit Link Content"
    
    var image: UIImage? {
        var img: UIImage?
        switch self {
        case .goToPage:
            img = UIImage(named: "doc.text.magnifyingglass")
        case .linkSettings:
            img = UIImage(named: "doc.text.magnifyingglass")
        case .editLinkContent:
            img = UIImage(named: "doc.text.magnifyingglass")
        }
        return img
    }
}

struct FTTextSection {
    var header: String = "TEXT"
    var options: [FTTextOption] = FTTextOption.allCases
}

enum FTTextOption: String, CaseIterable {
    case editContent = "Edit Content"
    
    var image: UIImage? {
        var img: UIImage?
        switch self {
        case .editContent:
            img = UIImage(named: "doc.text.magnifyingglass")
        }
        return img
    }
}

struct FTLinkSettingsModel {
    var header: String
    var rows: [FTLinkSettings]
}

enum FTLinkSettings {
    case linkTo
    case document
    case page
}

enum FTLinkSettingsOptions: String, CaseIterable {
    case linkTo = "Link To"
    case document = "Document"
    case page = "Page"
}
