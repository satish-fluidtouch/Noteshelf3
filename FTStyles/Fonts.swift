//
//  Fonts.swift
//
//
//  Created by Akshay on 06/06/22.
//

import SwiftUI
import UIKit

public enum ClearFace: String, CaseIterable {
    case regular = "Clearface-Serial-Regular"
    case medium = "Clearface-Serial-Medium"
    case regularItalic = "Clearface-Serial-RegularItalic"
}

extension View {
    public func appFont(for weight: Font.Weight, with size: CGFloat) -> some View {
        let ftFont = Font.system(size: size, weight: weight)
        return self.font(ftFont)
    }
}

extension Text {
    public func appFont(for weight: Font.Weight, with size: CGFloat) -> Text {
        let ftFont = Font.system(size: size, weight: weight)
        return self.font(ftFont)
    }
}

extension Font {
    public static func textStyle(for size: CGFloat) -> Font.TextStyle {
        let styles: [Font.TextStyle] = [.largeTitle, .title, .title2, .title3, .headline, .body, .callout, .subheadline, .footnote, .caption, .caption2,]
        let textStyle = styles.first(where: {$0.size == size}) ?? Font.TextStyle.subheadline
        return textStyle
    }

    public static func appFont(for weight: Font.Weight, with size: CGFloat) -> Font {
        return Font.system(size: size, weight: weight)
    }

    public static func clearFaceFont(for type: ClearFace, with size: CGFloat) -> Font {
        return Font.custom(type.rawValue, size: size)
    }
}

extension Font.TextStyle {
    var weight: Font.Weight {
        switch self {
        case .headline: return .bold
        case .largeTitle: return .medium
        case .title: return .medium
        case .title2: return .medium
        case .title3: return .medium

        case .body: return .regular
        case .callout: return .regular
        case .subheadline: return .regular

        case .footnote: return .regular
        case .caption: return .regular
        case .caption2: return .regular
        @unknown default:
            fatalError("New Type might have got introduced")
        }
    }

    var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20

        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15

        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default:
            fatalError("New Type might have got introduced")
        }
    }
}
