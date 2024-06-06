//
//  FTPenShortcutView.swift
//  Noteshelf3
//
//  Created by Narayana on 14/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenSliderConstants {
    static var startAngle: Angle = .degrees(0)
    static var sliderRadius : CGFloat = 250
    static var spacingAngle : Int = 10
    static var penShortCutItems : Int = 7
    static var highlighterShortCutItems : Int = 7
    static var penShortcutColorItems : Int = 4
    static var shapeTypeShortcutItems : Int = 3
    static var shapeShortcutItems : Int = 8
    static var presenterShortcutItems : Int = 5
    static var highlighterShortcutColorItems : Int = 4
    static var shapeShortcutColorItems : Int = 4
    static var rotationAngle : Int = 180 - spacingAngle
}

enum FTShortcutbarMode {
    case rectangle
    case arc
}

struct FTPenShortcutView: View {
    @StateObject var colorModel: FTFavoriteColorViewModel
    @StateObject var sizeModel: FTFavoriteSizeViewModel

    var body: some View {
        ZStack {
            FTShortcutBarVisualEffectView()
                .cornerRadius(100.0)
            HStack(spacing: 0.0) {
                FTPenColorShortcutView()
                    .environmentObject(colorModel)
                    .padding(.horizontal, 8.0)
                FTToolSeperator()
                    .padding(.horizontal, 2.0)
                FTPenSizeShortcutView()
                    .environmentObject(sizeModel)
                    .padding(.horizontal, 6.0)
            }
        }
        .toolbarOverlay()
    }
}

struct FTPenShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // test preview here
        }
    }
}

struct FTPenSliderShortcutView: View {
    @StateObject var colorModel: FTFavoriteColorViewModel
    @StateObject var sizeModel: FTFavoriteSizeViewModel
    var body: some View {
        ZStack {
            FTPenSliderColorShortcutView(startAngle: FTPenSliderConstants.startAngle)
                .environmentObject(colorModel)
            FTPenSliderSizeShortcutView(startAngle: .degrees(Double(FTPenSliderConstants.penShortcutColorItems * FTPenSliderConstants.spacingAngle)))
                .environmentObject(sizeModel)
        }
    }
}

struct CircularBorderShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        return path
    }
}
