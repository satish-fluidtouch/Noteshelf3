//
//  FTDeskModeHelper.swift
//  Noteshelf3
//
//  Created by Narayana on 04/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

struct FTDeskModeHelper {
    static func isToSelectDeskTool(mode: RKDeskMode, toolType: FTDeskCenterPanelTool) -> Bool {
        var selected: Bool = false

        if toolType.toolMode == .deskModeTool {
            if mode == .deskModePen && toolType == .pen || mode == .deskModeMarker && toolType == .highlighter || mode == .deskModeEraser && toolType == .eraser || mode == .deskModeShape && toolType == .shapes || mode == .deskModeText && toolType == .textMode || mode == .deskModeLaser && toolType == .presenter || mode == .deskModeReadOnly && toolType == .hand || mode == .deskModeClipboard && toolType == .lasso {
                selected = true
            }
        }
        return selected
    }

    static func getCurrentToolColor(toolType: FTDeskCenterPanelTool, userActivity: NSUserActivity?) -> UIColor {
        var color = UIColor.clear

        if toolType == .pen {
            let penRack = FTRackData(type: FTRackType.pen, userActivity: userActivity)
            let currentPenSet = penRack.getCurrentPenSet()
            color = UIColor(hexString: currentPenSet.color)
        } else if toolType == .highlighter {
            let penRack = FTRackData(type: FTRackType.highlighter, userActivity: userActivity)
            let currentPenSet = penRack.getCurrentPenSet()
            color = UIColor(hexString: currentPenSet.color)
        } else if  toolType == .shapes {
            let penRack = FTRackData(type: FTRackType.shape, userActivity: userActivity)
            let currentPenSet = penRack.getCurrentPenSet()
            color = UIColor(hexString: currentPenSet.color)
        }
        return color
    }

    static func getEquivalentTool(for mode: RKDeskMode) -> FTDeskCenterPanelTool {
        var reqTool = FTDeskCenterPanelTool.pen
        if mode == .deskModeMarker {
            reqTool = .highlighter
        } else if mode == .deskModeEraser {
            reqTool = .eraser
        } else if mode == .deskModeShape {
            reqTool = .shapes
        } else if mode == .deskModeClipboard {
            reqTool = .lasso
        } else if mode == .deskModeText {
            reqTool = .textMode
        } else if mode == .deskModeView {
            reqTool = .hand
        }
        return reqTool
    }
}
