//
//  FTBulletConstants.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
let CHECKBOX_WIDTH = 18
let CHECKBOX_HEIGHT = 18
let CHECK_BOX_OFFSET_Y = -2

let SUPPORTS_BULLETS = true
let indentOffset: CGFloat = 32

let BULLET_FORMAT = "%@\t"
let AUTO_COMPLETE_BULLET_FORMAT = "\n%@\t"

enum FTBulletIndentationType : Int {
    case increase
    case decrease
}

enum FTBulletType : Int {
    case none = 100
    case one
    case two
    case numbers
    case checkBox
}
