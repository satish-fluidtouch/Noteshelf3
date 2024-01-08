//
//  FTCircularProgressView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 27/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTCircularProgressView: View {
    @Binding var progress: CGFloat
    var progressBGColor: Color = Color.appColor(.accent)
    var progressColor: Color = Color.appColor(.accent)
    var lineWidth: CGFloat = 5.0
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    progressBGColor.opacity(0.3),
                    lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                                        ))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}
struct FTCircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FTCircularProgressView(progress: .constant(0.5))
    }
}
