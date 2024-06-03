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
    static var sliderRadius : CGFloat = 260
    static var spacingAngle : Int = 10
    static var penShortCutItems : Int = 7
    static var highlighterShortCutItems : Int = 7
    static var penShortcutColorItems : Int = 4
    static var shapeTypeShortcutItems : Int = 3
    static var shapeShortcutItems : Int = 8
    static var highlighterShortcutColorItems : Int = 4
    static var shapeShortcutColorItems : Int = 4
    static var rotationAngle : Int = 180 - spacingAngle
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
            CircularBorderShape(startAngle:FTPenSliderConstants.startAngle, endAngle: FTPenSliderConstants.startAngle + Angle(degrees: Double(FTPenSliderConstants.spacingAngle * (FTPenSliderConstants.penShortCutItems - 1))), radius: FTPenSliderConstants.sliderRadius)
                .stroke(.black, style: StrokeStyle(lineWidth: 42, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-170))
            CircularBorderShape(startAngle: FTPenSliderConstants.startAngle, endAngle: FTPenSliderConstants.startAngle + Angle(degrees: Double(FTPenSliderConstants.spacingAngle * (FTPenSliderConstants.penShortCutItems - 1))), radius: FTPenSliderConstants.sliderRadius)
                .stroke(Color.appColor(.finderBgColor), style: StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-170))
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
