//
//  FTPresenterColorCircleView.swift
//  Noteshelf3
//
//  Created by Narayana on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

struct FTPresenterColorCircleView: View {
    let hexColor: String
    var isSelected: Bool

    let circleDiam: CGFloat = 24.0

    var body: some View {
        ZStack {
            Circle()
                .frame(width: isSelected ? (circleDiam+2.0) : circleDiam, height: isSelected ? (circleDiam+2.0) : circleDiam)
                .foregroundColor(Color(hex: hexColor))
//                .shadow(color: isSelected ? Color.black.opacity(0.16) : .clear, radius: 8, x: 0.0, y: 4.0)
                .blur(radius: 2.0)

            if isSelected {
                Image("whiteCircle")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: circleDiam+1.0, height: circleDiam+1.0)
            }
        }
    }
}

struct FTPresenterColorCircleView_Previews: PreviewProvider {
    static var previews: some View {
        FTPresenterColorCircleView(hexColor: "000000", isSelected: true)
    }
}
