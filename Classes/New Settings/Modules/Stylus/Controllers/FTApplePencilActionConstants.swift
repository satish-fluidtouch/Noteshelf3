//
//  FTApplePencilActionConstants.swift
//  Noteshelf
//
//  Created by Amar on 02/11/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
@objc protocol FTApplePencilInteractionProtocol: NSObjectProtocol {
        @objc optional func didReceivePencilInteraction(_ action: FTApplePencilInteractionType);
}

@objc enum FTApplePencilInteractionType: Int, CaseIterable {
    case systemDefault
    case previousTool
    case eraser
    case showColors
    case distractionFree

    func localizedString() -> String {
        switch self {
        case .systemDefault:
            return NSLocalizedString("OptionSystemDefault", comment: "Default");
        case .previousTool:
            return NSLocalizedString("OptionLastUsedTool", comment: "Previous Tool");
        case .eraser:
            return NSLocalizedString("OptionEraser", comment: "Eraser");
        case .showColors:
            return NSLocalizedString("OptionColorPalette", comment: "Show Colors");
        case .distractionFree:
            return "stylus.switch.focusmode".localized
        }
    }
};
