//
//  FTWrittingAndStylusModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 08/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum WrittingSyle:CaseIterable{
    case leftdown
    case rightDown
    case leftStrait
    case rightStrait
    case leftTop
    case rightTop
    
    var normalModeImageName:String{
        switch self{
        case .leftdown:
            return "leftdownNormal"
        case .rightDown:
            return "rightDownNormal"
        case .leftStrait:
            return "leftStraitNormal"
        case .rightStrait:
            return "rightStraitNormal"
        case .leftTop:
            return "leftTopNormal"
        case .rightTop:
            return "rightTopNormal"
        }
    }
    var selectedModeImageName:String{
        switch self{
        case .leftdown:
            return "leftdownselected"
        case .rightDown:
            return "rightDownselected"
        case .leftStrait:
            return "leftStraitselected"
        case .rightStrait:
            return "rightStraitselected"
        case .leftTop:
            return "leftTopselected"
        case .rightTop:
            return "rightTopselected"
        }
    }
}
