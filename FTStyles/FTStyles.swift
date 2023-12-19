import Foundation
import SwiftUI

public struct FTStyles {
    public static var useSystemFont = false

    public init() {
    }

    public static func registerFonts() {
        ClearFace.allCases.forEach {
            registerFont(bundle: .this, fontName: $0.filename, fontExtension:  $0.fileExtension)
        }
        registerFont(bundle: .this, fontName: "SF-Pro-Rounded-Bold", fontExtension:  "otf")
    }

    fileprivate static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {

        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            fatalError("Couldn't create font from data")
        }

        var error: Unmanaged<CFError>?

        CTFontManagerRegisterGraphicsFont(font, &error)
    }

}
