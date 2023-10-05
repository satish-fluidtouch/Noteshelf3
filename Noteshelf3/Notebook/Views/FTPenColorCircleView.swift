//
//  FTPenColorCircleView.swift
//  Noteshelf3
//
//  Created by Narayana on 15/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPenColorCircleView: View {
    let hexColor: String
    var circleDiam: CGFloat = 24.0
    var isSelected: Bool

    var body: some View {
        if hexColor.isEmpty {
            Circle()
                .frame(width: circleDiam, height: circleDiam)
                .foregroundColor(Color.primary.opacity(0.08))
        } else {
            ZStack {
                Circle()
                    .frame(width: isSelected ? (circleDiam+2.0) : circleDiam, height: isSelected ? (circleDiam+2.0) : circleDiam)
                    .foregroundColor(Color(hex: hexColor))
//                    .shadow(color: isSelected ? Color.primary.opacity(0.16) : .clear, radius: 8, x: 0.0, y: 4.0)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: circleDiam)
//                            .stroke(Color.appColor(.black20), lineWidth: 1.0))
                if isSelected {
                    Image("whiteCircle")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: circleDiam+1.5, height: circleDiam+1.5)
                }
            }
        }
    }
}

struct FTPenPresetColorCircleView: View {
    let hexColor: String
    let circleDiam: CGFloat = 36.0
    var isSelected: Bool

    var body: some View {
        FTPenColorCircleView(hexColor: hexColor, circleDiam: 36, isSelected: isSelected);
    }
}

struct FTPenColorCircleView_Previews: PreviewProvider {
    static var previews: some View {        
        VStack {
            FTPenColorCircleView(hexColor: "000000", isSelected: true)
            FTPenColorCircleView(hexColor: "FF0000", isSelected: true)
            FTPenColorCircleView(hexColor: "00FF00", isSelected: true)
            FTPenColorCircleView(hexColor: "FFFF00", isSelected: true)
        }
    }
}
