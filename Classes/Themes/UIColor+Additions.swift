//
//  UIColor+Additions.swift
//  Noteshelf for iOS
//
//  Generated on Zeplin. (10/3/2018).
//  Copyright (c) 2018 Fluid Touch Pte Ltd. All rights reserved.
//

//#if !NOTESHELF_ACTION
extension UIColor {
    var hexString: String {
        let comps = self.components()
        let r = Float(comps.red)
        let g = Float(comps.green)
        let b = Float(comps.blue)

        let hex = String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hex
    }
}
//#endif
