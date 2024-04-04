//
//  FTTemplateLineheightsModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 01/03/23.
//

import Foundation

public struct FTTemplateLineHeightModel: Hashable {
    public let lineHeight: FTTemplateLineHeight
    public init(lineHeight: FTTemplateLineHeight) {
        self.lineHeight = lineHeight
    }
}

public enum FTTemplateLineHeight: String, CaseIterable, Codable {
    case extraNarrow = "Extra Narrow"
    case narrow = "Narrow"
    case standard = "Standard"
    case wide = "Wide"

    public var displayTitle: String {
        let title: String
        switch self {
        case .extraNarrow:
            title = "lineHeight.extraNarrow".localized
        case .narrow:
            title = "lineHeight.narrow".localized
        case .standard:
            title = "lineHeight.standard".localized
        case .wide:
            title = "lineHeight.wide".localized
        }
        return title
    }

    var rawTitle: String {
        return self.rawValue
    }

    var iconPath: String {
        let path: String
        switch self {
        case .extraNarrow:
            path = "lineHeightExtraNarrow"
        case .narrow:
            path = "lineHeightNarrow"
        case .standard:
            path = "lineHeightStandard"
        case .wide:
            path = "lineHeightWide"
        }
        return path
    }
    
    var thumbImgPrefix: String {
        let prefix: String
        switch self {
        case .extraNarrow:
            prefix = "extraNarrow"
        case .narrow:
            prefix = "narrow"
        case .standard:
            prefix = "standard"
        case .wide:
            prefix = "wide"
        }
        return prefix
    }

    public init(rawValue: String?)  {
        guard let rawValue = rawValue else {
            self = .standard
            return
        }
        if rawValue == FTTemplateLineHeight.extraNarrow.rawTitle {
            self = .extraNarrow
        } else if rawValue == FTTemplateLineHeight.narrow.rawTitle {
            self =  .narrow
        } else if rawValue == FTTemplateLineHeight.wide.rawTitle {
            self =  .wide
        } else {
            self =  .standard
        }
    }
}
