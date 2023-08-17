//
//  FTTemplateBasicColors.swift
//  FTNewNotebook
//
//  Created by Ramakrishna on 27/02/23.
//

import UIKit

public struct FTTemplateColorModel: Hashable {
    public let color: FTTemplateColor
    public let hex: String

    public init(color: FTTemplateColor, hex: String) {
        self.color = color
        self.hex = hex
    }
}
public enum FTTemplateColor: String, Codable {
    case white = "White"
    case ivory = "Ivory"
    case legal = "Legal"
    case midnight = "Midnight"
    case custom = "Custom"

    public var displayTitle: String {
        return self.rawValue
    }

    public init(rawValue: String?) {
        guard let rawValue = rawValue else {
            self = .white
            return
        }
        if rawValue == FTTemplateColor.ivory.displayTitle {
            self =  .ivory
        } else if rawValue == FTTemplateColor.legal.displayTitle {
            self =  .legal
        } else if rawValue == FTTemplateColor.midnight.displayTitle {
            self = .midnight
        } else if rawValue == FTTemplateColor.custom.displayTitle {
            self = .custom
        } else {
            self =  .white
        }
    }
    public var isCustom: Bool {
        self == .custom
    }
}
