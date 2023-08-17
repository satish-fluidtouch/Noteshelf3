//
//  FTTextBackgroundProtocol.swift
//  Noteshelf
//
//  Created by Mahesh on 07/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTTextBackgroundProtocol {
    var color: String {get}
    var name: String {get}
    var image: UIImage? {get}
    var isCustom: Bool {get}
}

extension FTTextBackgroundProtocol {
    var isCustom: Bool {
        return false
    }
}

struct FTTextBackgroundNone: FTTextBackgroundProtocol {
    var color: String {
        return ""
    }
    
    var name: String {
        return NSLocalizedString("None", comment: "None")
    }
    
    var image: UIImage? {
        return UIImage(named: "textbox-none")
    }
}

struct FTTextBackgroundYellow: FTTextBackgroundProtocol {
    var color: String {
        return "#F2D95D"
    }
    
    var name: String {
        return NSLocalizedString("Yellow", comment: "Yellow")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-yellow")
    }
}

struct FTTextBackgroundGreen: FTTextBackgroundProtocol {
    var color: String {
        return "#A3D488"
    }
    
    var name: String {
        return NSLocalizedString("Green", comment: "Green")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-green")
    }
}

struct FTTextBackgroundBlue: FTTextBackgroundProtocol {
    var color: String {
        return "#9AB6F7"
    }
    
    var name: String {
        return NSLocalizedString("Blue", comment: "Blue")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-blue")
    }
}

struct FTTextBackgroundPink: FTTextBackgroundProtocol {
    var color: String {
        return "#EA9BAF"
    }
    
    var name: String {
        return NSLocalizedString("Pink", comment: "Pink")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-pink")
    }
}

struct FTTextBackgroundPurple: FTTextBackgroundProtocol {
    var color: String {
        return "#BDACF0"
    }
    
    var name: String {
        return NSLocalizedString("Purple", comment: "Purple")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-purple")
    }
}

struct FTTextBackgroundCustom: FTTextBackgroundProtocol {
    var color: String {
        return ""
    }
    
    var name: String {
        return NSLocalizedString("Custom", comment: "Custom")
    }
    var image: UIImage? {
        return UIImage(named: "textbox-custom")
    }
    
    var isCustom: Bool {
        return true
    }
}


class FTTextBackgroundColorManager {
    static func fetchTextModeBackgroundColors() -> [FTTextBackgroundProtocol] {
        return [FTTextBackgroundNone(), FTTextBackgroundYellow(), FTTextBackgroundGreen(), FTTextBackgroundBlue(), FTTextBackgroundPink(), FTTextBackgroundPurple(), FTTextBackgroundCustom()]
    }
}
