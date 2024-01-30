//
//  FTTemplateSizeModel.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 01/03/23.
//

import UIKit

public struct FTTemplateSizeModel: Hashable {
    public let size: FTTemplateSize
    public let portraitSize: String
    public let landscapeSize: String
    public init(size: FTTemplateSize, portraitSize: String, landscapeSize: String) {
        self.size = size
        self.portraitSize = portraitSize
        self.landscapeSize = landscapeSize
    }
}

// swiftlint:disable all
public enum FTTemplateSize: String, Codable,CaseIterable {
    case iPad = "iPad"
    case letter = "Letter"
    case a3 = "A3"
    case a4 = "A4"
    case a5 = "A5"
    case mobile = "Mobile"

    public var displayTitle: String {
        if (UIDevice.current.isIpad() && self == .iPad) || (UIDevice.current.isPhone() && self == .mobile){
            return "templateSizes.currentDevice.thisDevice".localized
        }
        return self.rawValue
    }

    public init(rawValue: String?)  {
        guard let rawValue = rawValue else {
            self = .iPad
            return
        }

        if rawValue == FTTemplateSize.a3.rawValue {
            self = .a3
        } else if rawValue == FTTemplateSize.a4.rawValue {
            self = .a4
        } else if rawValue == FTTemplateSize.a5.rawValue {
            self = .a5
        } else if rawValue == FTTemplateSize.mobile.rawValue {
            self = .mobile
        } else if rawValue == FTTemplateSize.letter.rawValue {
            self = .letter
        } else {
            self = .iPad
        }
    }
}
