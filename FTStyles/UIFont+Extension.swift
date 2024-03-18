//
//  UIFont+Extension.swift
//  FTStyles
//
//  Created by Narayana on 25/03/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

// Fonts with type and size
extension UIFont {
    public static func clearFaceFont(for type: ClearFace, with size: CGFloat) -> UIFont {
        if let font = UIFont(name: type.rawValue, size: size) {
            let style = UIFont.textStyle(for: font.pointSize)
            let scaledFont = UIFont.scaledFont(for: font, with: style)
            return scaledFont
        }
        return UIFont.systemFont(ofSize: size)
    }

    public static func appFont(for weight: UIFont.Weight, with size: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let style = UIFont.textStyle(for: font.pointSize)
        let scaledFont = UIFont.scaledFont(for: font, with: style)
        return scaledFont
//        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    public static func appFont(for weight: UIFont.Weight, with size: CGFloat, trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: size)
    }
}

extension UIFont {
    public static func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        let styles: [UIFont.TextStyle] = [.largeTitle, .title1, .title2, .title3, .headline, .body, .callout, .subheadline, .footnote, .caption1, .caption2, .subHeadLine2, .largeTitle2, .caption3]
        var textStyle = styles.first(where: {$0.size == size}) ?? UIFont.TextStyle.subheadline
        if  !textStyle.isValidTextStyle {
            // If text style is not valid, pick nearest style
            textStyle = textStyle.validTextStyle
        }
        return textStyle
    }
    
    public static func scaledFont(for font: UIFont, with style: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: style)
        let scaledFont = fontMetrics.scaledFont(for: font)
        return scaledFont
    }
}

extension UIFont.TextStyle {
    static var subHeadLine2 = UIFont.TextStyle(rawValue: "subHeadLine2")
    static var largeTitle2 = UIFont.TextStyle(rawValue: "largeTitle2")
    static var caption3 = UIFont.TextStyle(rawValue: "caption3")

    var isValidTextStyle : Bool {
        var isValidStyle = true
        switch self {
        case .subHeadLine2, .caption3, .largeTitle2:
            isValidStyle = false
        default:
            break
        }
        return isValidStyle
    }

    var validTextStyle: UIFont.TextStyle {
        var validStyle = UIFont.TextStyle.subheadline
        switch self {
        case .subHeadLine2:
            validStyle = .subheadline
        case .largeTitle2:
            validStyle = .largeTitle
        case .caption3:
            validStyle = .caption2
        default:
            break
        }
        return validStyle
    }

    var weight: UIFont.Weight {
        switch self {
        case .headline: return .bold
        case .largeTitle: return .medium
        case .title1: return .medium
        case .title2: return .medium
        case .title3: return .medium

        case .body: return .regular
        case .callout: return .regular
        case .subheadline: return .regular

        case .footnote: return .regular
        case .caption1: return .regular
        case .caption2: return .regular
        default:
            fatalError("New Type might have got introduced")
        }
    }

    var size: CGFloat {
        switch self {
        case .largeTitle2: return 36
        case .largeTitle: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20

        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .subHeadLine2 : return 14
        case .footnote: return 13
        case .caption1: return 12
        case .caption2: return 11
        case .caption3: return 10
        default:
            fatalError("New Type might have got introduced")
        }
    }
}

extension UIFont {
    var bold: UIFont { return withWeight(.bold) }
    var medium: UIFont { return withWeight(.medium) }

    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]
        traits[.weight] = weight
        attributes[.name] = nil
        attributes[.traits] = traits
        attributes[.family] = familyName
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
