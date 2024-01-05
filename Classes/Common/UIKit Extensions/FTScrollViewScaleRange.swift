//
//  FTScrollViewScaleRange.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private class FTScrollScaleRange: NSObject {
    var minZoomScale: CGFloat = 1;
    var maxZoomScale: CGFloat = 6;
}

@objcMembers class FTDocumentScrollViewZoomScale: NSObject {
    static let shared  = FTDocumentScrollViewZoomScale()
    
    private var zoomScaleOptions = [Int : FTScrollScaleRange]();
    
    override init() {
        zoomScaleOptions[FTRenderModeDefault.rawValue] = FTScrollScaleRange();
        zoomScaleOptions[FTRenderModeZoom.rawValue] = FTScrollScaleRange();
        zoomScaleOptions[FTRenderModeExternalScreen.rawValue] = FTScrollScaleRange();
    }
    
    func setMinimumZoomScale(_ scale: CGFloat,mode: FTRenderMode) {
        if let options = zoomScaleOptions[mode.rawValue] {
            options.minZoomScale = scale;
        }
        else {
            let newRange = FTScrollScaleRange();
            newRange.minZoomScale = scale;
            zoomScaleOptions[mode.rawValue] = newRange;
        }
    }
    
    func setMaximumZoomScale(_ scale: CGFloat,mode: FTRenderMode) {
        if let options = zoomScaleOptions[mode.rawValue] {
            options.maxZoomScale = scale;
        }
        else {
            let newRange = FTScrollScaleRange();
            newRange.maxZoomScale = scale;
            zoomScaleOptions[mode.rawValue] = newRange;
        }
    }

    func minimumZoomScale(_ mode: FTRenderMode) -> CGFloat {
        let options = zoomScaleOptions[mode.rawValue] ?? FTScrollScaleRange();
        return options.minZoomScale;
    }
    
    func maximumZoomScale(_ mode: FTRenderMode) -> CGFloat {
        let options = zoomScaleOptions[mode.rawValue] ?? FTScrollScaleRange();
        return options.maxZoomScale;
    }

}
