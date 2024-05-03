//
//  FTPenColorSegment.swift
//  Noteshelf3
//
//  Created by Narayana on 15/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTColorsFlowType {
    case penType(FTPenType)
    case lasso
    case shape
    case text

    var typeKey: String {
        let key: String
        switch self {
        case .penType(let ftPenType):
            key = ftPenType.name
        case .lasso:
            key = "Lasso"
        case .shape:
            key = "Shape"
        case .text:
            key = "Text"
        }
        return key
    }
}

enum FTPenColorSegment: String {
    case presets
    case grid
    case spectrum
    
    func saveSelection(for flow: FTColorsFlowType) {
        let key = "SegmentType" + "_" + flow.typeKey
        UserDefaults.standard.set(self.rawValue, forKey: key)
    }

    static func savedSegment(for flow: FTColorsFlowType) -> FTPenColorSegment {
        var mode: FTPenColorSegment = .presets
        let key = "SegmentType" + "_" + flow.typeKey
        if let savedSegment = UserDefaults.standard.string(forKey: key), let colorEditSegment = FTPenColorSegment(rawValue: savedSegment) {
            mode = colorEditSegment
        }
        return mode
    }
}

enum FTPresenterType : Int {
    case pointer = 6
    case pen = 7

    var presenterColors : [String] {
        switch self {
        case .pointer:
            return FTRackData(type: .presenter, userActivity: nil).laserPointerColors
        case .pen:
            return FTRackData(type: .presenter, userActivity: nil).laserPenColors
        }
    }
}

enum FTPenColorMode: String {
    case select
    case presetEdit
}

@objc enum FTZoomShortcutMode: Int {
    case auto
    case manual
}

enum FTPresenterModeOption: String, CaseIterable {
    case clearAnnotations
    case exitPresentation

    var localizedString: String {
        let str: String
        if self == .clearAnnotations {
            str = "presentation.clearAnnotations".localized
        } else {
            str = "presentation.exit".localized
        }
        return str
    }

    var imageName: String {
        let str: String
        if self == .clearAnnotations {
            str = "eraser"
        } else {
            str = "xmark.circle"
        }
        return str
    }
}
