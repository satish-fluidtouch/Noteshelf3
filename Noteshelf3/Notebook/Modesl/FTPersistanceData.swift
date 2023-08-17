//
//  FTPersistanceData.swift
//  Noteshelf3
//
//  Created by Narayana on 18/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public enum FTRackPersistanceKey: String {
    case defaultColors
    case currentColors
    case currentSelection

    // Presenter
    case defaultLaserPenColors
    case defaultLaserPointerColors

    public enum PenSet: String {
        case type
        case color
        case size
        case preciseSize
    }

    public enum PresenterSet: String {
        case presenterType
        case pointerColor
        case penColor
    }
}
