//
//  Shadows.swift
//

import SwiftUI

public extension View {
    /// This Shadow was designed for the book covers.
    /// - Shadow 1: `X: 0, Y: 1 B: 1 S: 0`
    /// - Shadow 2: `X: 0, Y: 2 B: 4 S: 0`
    /// - Shadow 3: `X: 0, Y: 0 B: 1 S: 0`
    func threeLayerShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
    }
}
