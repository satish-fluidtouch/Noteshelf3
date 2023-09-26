//
//  FTFavoritebarPresenter.swift
//  Noteshelf3
//
//  Created by Narayana on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

private var offset: CGFloat = 8.0
@objcMembers class FTFavoritebarPresenter: NSObject {
    private(set) var toolbarOffset = FTToolbarConfig.Height.regular + offset
    private(set) weak var parentVC: UIViewController?
    private(set) var rackType: FTRackType = .pen
    var mode: FTScreenMode = .normal

    private(set) weak var favbarController: FTFavoritebarViewController?
}
