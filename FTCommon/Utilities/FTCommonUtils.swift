//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import UIKit

public class FTCommonUtils: NSObject {
    public class func currentLanguage() -> String {
        return Bundle.main.preferredLocalizations[0]
    }
    public class func getUUID() -> String {
        return UUID().uuidString
    }

    public class func aspectFit(_ inRect: CGRect, targetRect maxRect: CGRect) -> CGRect {
        let originalAspectRatio = Float(inRect.size.width / inRect.size.height)
        let maxAspectRatio = Float(maxRect.size.width / maxRect.size.height)

        var newRect = maxRect
        if originalAspectRatio > maxAspectRatio {
            newRect.size.height = CGFloat(maxRect.size.width * inRect.size.height / inRect.size.width)
            newRect.origin.y += CGFloat(maxRect.size.height - newRect.size.height) / 2.0
        } else {
            newRect.size.width = CGFloat(maxRect.size.height * inRect.size.width / inRect.size.height)
            newRect.origin.x += CGFloat(maxRect.size.width - newRect.size.width) / 2.0
        }

        return newRect.integral
    }
}

public enum FTPageFooterOption : Int {
    case show = 0
    case hide
}

public func runInMainThread(_ closure: @escaping () -> Void) {
/* guard !Thread.current.isMainThread else {
        closure()
        return
    }
 Do not uncomment this!
 Reason - Running on sepearate main thread gives ample time to update the UI.This is proven logic.
 One example is undo/redo button enabling.
 */
    DispatchQueue.main.async {
        closure()
    }
}

public func runInMainThread(_ afterDelay: TimeInterval, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * afterDelay)) / Double(NSEC_PER_SEC), execute: {
        closure()
    })
}

public func isInChinaRegion() -> Bool {
    if NSLocale.current.language.region?.identifier.lowercased() == "cn" {
        return true
    }
    return false
}
