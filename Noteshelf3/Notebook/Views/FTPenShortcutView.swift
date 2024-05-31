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
    static var sliderRadius : CGFloat = 220
    static var spacingAngle : Int = 14
    static var penShortCutItems : Int = 7
    static var highlighterShortCutItems : Int = 7
    static var penShortcutColorItems : Int = 4
    static var highlighterShortcutColorItems : Int = 4
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
    let startAngle : Angle = .degrees(4)
    var body: some View {
        ZStack {
            CircularBorderShape(startAngle: startAngle, endAngle: startAngle + Angle(degrees: Double(FTPenSliderConstants.spacingAngle * (FTPenSliderConstants.penShortCutItems - 1))), radius: FTPenSliderConstants.sliderRadius)
                .stroke(.black, style: StrokeStyle(lineWidth: 52, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-170))
            CircularBorderShape(startAngle: startAngle, endAngle: startAngle + Angle(degrees: Double(FTPenSliderConstants.spacingAngle * (FTPenSliderConstants.penShortCutItems - 1))), radius: FTPenSliderConstants.sliderRadius)
                .stroke(Color.appColor(.finderBgColor), style: StrokeStyle(lineWidth: 50, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(-170))
            FTPenSliderColorShortcutView()
                .environmentObject(colorModel)
            FTPenSliderSizeShortcutView()
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
