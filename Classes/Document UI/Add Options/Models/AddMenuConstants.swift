//
//  AddMenuConstants.swift
//  Noteshelf3
//
//  Created by Narayana on 04/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTAddMenuConfig {
    static let footerHeightNormal: CGFloat = 16.0
    static let footerHeightSmall: CGFloat = 4.0
    static let rowHeightNormal: CGFloat = 44.0
    static let rowHeightLarge: CGFloat = 60.0
    static let imageSize = CGSize(width: 24.0, height: 24.0)
    static let rowFont = UIFont.appFont(for: .regular, with: 17.0)
    static let contentBgColor = UIColor.appColor(.white40)
    static let cellReuseId = "Cell"
    static let addMenuTopsegmentHeight: CGFloat = 86
}
