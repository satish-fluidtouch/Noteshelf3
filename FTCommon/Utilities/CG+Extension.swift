//
//  CGFloat+Extension.swift
//  FTCommon
//
//  Created by Narayana on 25/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import CoreGraphics

extension CGFloat {
    public func roundToDecimal(_ fractionDigits: Int) -> CGFloat {
        let multiplier = pow(10, CGFloat(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }

    public var formattedValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.1f", self) : String(format: "%.1f", self)
    }
}

extension Int {
    public var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}
extension FloatingPoint {
    public var degreesToRadians: Self { return self * .pi / 180 }
    public var radiansToDegrees: Self { return self * 180 / .pi }
}

