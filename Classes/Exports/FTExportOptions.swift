//
//  FTExportSettings.swift
//  Noteshelf
//
//  Created by Siva on 22/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTExportOptions: Int, Identifiable {
    var id: RawValue { self.rawValue }

    case pageFooter
    case pageTemplate
    case exportFormat
    case coverPage

    var title: String {
        let reqTitle: String

        switch self {
        case .pageFooter:
            reqTitle = "Title&PageNo"
        case .pageTemplate:
            reqTitle = "PageTemplate"
        case .exportFormat:
            reqTitle = "Format"
        case .coverPage:
            reqTitle = "coverPage"
        }
        return reqTitle.localized
    }
}
