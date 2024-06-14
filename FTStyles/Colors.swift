import SwiftUI
import UIKit

class BundleClass: NSObject {}

extension Bundle {
    static var this: Bundle {
        Bundle(for: BundleClass.classForCoder())
    }
}

// Naming convention of color names here should be w.r.to light mode, corresponding dark mode color should be available in color assets
public enum AssetsColor: String, CaseIterable {
    // Brand
    case ftBlue
    case ftPink
    case darkBlack
    case darkBlue
    case lines
    case darkRed
    case accent
    case secondaryBG
    case panelBgColor
    case secondaryLight
    case toolSeperator
    case popoverBgColor
    case formSheetBgColor
    case popOverOptionsBG
    case sidebarBG
    case groupNotesCountTint
    case sideBarSelectedTint
    case shelfViewBG
    case seeAllBtnBG
    case secondaryAccent
    case signoutBtnColor
    case welcomeBtnColor
    case welcometopGradiantColor
    case welcomeBottonGradiantColor
    case WelcomeContentShadowColor
    case neroColor
    case readOnlyModePageNumberBG
    case readOnlyModePageNumberTint
    case pageBGColor
    case shareGroupCovernBg
    case paperThemeBorderTint
    case passwordDefaultTint
    case passwordSelectedTint
    case createNotebookTitleViewShadow
    case createNotebookButtonShadow
    case createNotebookViewBG
    case cellBackgroundColor
    case buttonShadow
    case homeBG
    case homeIconTint
    case homeShadow
    case homeSelectedBG
    case starredShadow
    case templatesShadow
    case trashShadow
    case unfiledShadow
    case starredBG
    case starredIconTint
    case starredSelectedBG
    case templatesBG
    case templatesSelectedBG
    case templatesTitleTint
    case trashBG
    case trashIconTint
    case trashSelectedBG
    case unfiledBG
    case unfiledIconTint
    case unfiledSelectedBG
    case finderBgColor
    case moreTemplatesBorderTint
    case migrationHeaderBG
    case migrationHeaderBorderBG
    case templatesIconSelectedTint
    case templatesIconTint
    case templatesSelectedTitleTint
    case pencilProMenuBgColor
    
    //AccentNew
    case accentBg
    case accentBorder
    case neutral
    
    // Gray
    case gray1
    case gray2
    case gray3
    case gray5
    case gray6
    case gray9
    case gray75
    case grayDim
    case gray60
    case gray94
    case toolbarOutline
    case hModeToolbarBgColor
    case regularToolbarBgColor
    case macTextToolbarBgColor
    case eraserBtnUnselected
    case toastBgColor
    case globalSearchBgColor
    case groupBGColor
    case shortcutSlotHighlightColor
    case shortcutSlotBgColor
    case shortcutSlotBorderColor
    case shortcutSlotHighlightBorderColor
    case favoriteEmptySlotColor
    case lock_icon_bgcolor
    case creationWidgetButtonTint
    case creationWidgetButtonBG
    case pinnedBookOptionBgColor
    case discount_percentage_color

    // System
    case black1
    case black2
    case black3
    case black4
    case black5
    case black8
    case black20
    case black70
    case black50
    case black10
    case black90
    case black16
    case black30
    case black40
    case black28

    //White
    case white40
    case white70
    case white60
    case white90
    case white100
    case white20
    case white50
    case watchViewBg

    //Red
    case destructiveRed
}

public extension Color {
    static func appColor(_ name: AssetsColor) -> Color {
        Color(name.rawValue, bundle: Bundle.this)
    }
}

extension UIColor {
    public static func appColor(_ name: AssetsColor) -> UIColor {
        UIColor(named: name.rawValue, in: Bundle.this, compatibleWith: nil) ?? .yellow
    }
}

// Translation between Color and UIColor
public extension Color {
    // MARK: - Text Colors
    static let lightText = Color(UIColor.lightText)
    static let darkText = Color(UIColor.darkText)
    static let placeholderText = Color(UIColor.placeholderText)

    // MARK: - Label Colors
    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)

    // MARK: - Background Colors
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)

    // MARK: - Fill Colors
    static let systemFill = Color(UIColor.systemFill)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)

    // MARK: - Grouped Background Colors
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)

    // MARK: - Gray Colors
    static let systemGray = Color(UIColor.systemGray)
    static let systemGray2 = Color(UIColor.systemGray2)
    static let systemGray3 = Color(UIColor.systemGray3)
    static let systemGray4 = Color(UIColor.systemGray4)
    static let systemGray5 = Color(UIColor.systemGray5)
    static let systemGray6 = Color(UIColor.systemGray6)

    // MARK: - Other Colors
    static let separator = Color(UIColor.separator)
    static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    static let link = Color(UIColor.link)

    // MARK: System Colors
    static let systemBlue = Color(UIColor.systemBlue)
    static let systemPurple = Color(UIColor.systemPurple)
    static let systemGreen = Color(UIColor.systemGreen)
    static let systemYellow = Color(UIColor.systemYellow)
    static let systemOrange = Color(UIColor.systemOrange)
    static let systemPink = Color(UIColor.systemPink)
    static let systemRed = Color(UIColor.systemRed)
    static let systemTeal = Color(UIColor.systemTeal)

}
