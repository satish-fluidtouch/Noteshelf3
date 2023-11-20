//
//  FTConstants.swift
//  Noteshelf3
//
//  Created by Narayana on 22/04/22.
//

import Foundation
import SwiftUI

let blackColorHex: String = "000000"
let minScreenWidthForPopover: CGFloat = 450
let webClipDefaultURL = "https://www.wikipedia.org"

// Note: Carefully update the below constants if required must, If changed - ncecessary changes must be done in the used areas.
// ----- Shortcut Views Constants ----- //
let shortcutHeight: CGFloat = 38.0
let penShortcutWidth: CGFloat = UIDevice.current.isPhone() ? 153.0 : 249.0
let shapeShortcutWidth: CGFloat = UIDevice.current.isPhone() ? 182.0 : 298.0
let presenterShortcutWidth: CGFloat = 200.0
let favoritesShortcutWidth: CGFloat = 293.0

let penShortcutSize = CGSize(width: penShortcutWidth, height: shortcutHeight)
let shapeShortcutSize = CGSize(width: shapeShortcutWidth, height: shortcutHeight)
let presenterShortcutSize = CGSize(width: presenterShortcutWidth, height: shortcutHeight)
let favoriteShortcutSize = CGSize(width: favoritesShortcutWidth, height: shortcutHeight)

let supplimentaryFinderVcWidth: CGFloat = UIDevice.isLandscapeOrientation ? 280 : 240
let primaryCategoriesWidth: CGFloat = 280
let defaultPopoverWidth: CGFloat = 343 // as per figma

#if targetEnvironment(macCatalyst)
let supportsHWRecognition = true;
#else
let supportsHWRecognition = true;
#endif

