//
//  UIFonts+Custom.swift
//  Noteshelf3
//
//  Created by Sameer on 11/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public enum Hanuman: String, CaseIterable {
    case regular = "Hanuman-Regular"
    case bold = "Hanuman-Bold"
}

public enum Montserrat: String, CaseIterable {
    case regular = "Montserrat-Regular" // ttf
    case semibold = "Montserrat-SemiBold"
    case bold = "Montserrat-Bold"
    case extraBold = "Montserrat-ExtraBold" // ttf
    case light = "Montserrat-Light"
    case extraLight = "Montserrat-ExtraLight"

    var isttfExtension: Bool {
        var status = false
        if self == .regular || self == .extraBold {
            status = true
        }
        return status
    }
}

extension UIFont {
    public static func hanumanFont(for type: Hanuman, with size: CGFloat) -> UIFont {
        if let font = UIFont(name: type.rawValue, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }

    public static func montserratFont(for type: Montserrat, with size: CGFloat) -> UIFont {
        if let font = UIFont(name: type.rawValue, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }

}
