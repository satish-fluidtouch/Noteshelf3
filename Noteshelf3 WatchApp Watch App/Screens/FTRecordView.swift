//
//  FTRecordView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTRecordView: View {
    @State private var isRecording: Bool = false
    @StateObject private var viewModel = FTRecordViewModel()

    private let recordColor = Color(red: 224/255, green: 110/255, blue: 81/255)

    var body: some View {
        VStack {
            ZStack {
                if !isRecording {
                    Circle()
                        .fill(recordColor)
                        .frame(width: 74, height: 74)
                } else {
                    timerView
                }

                RoundedDashedCircle()
                    .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [1, 10]))
                    .foregroundStyle(recordColor)
                    .frame(width: 110, height: 110)
            }

            Spacer()
                .frame(height: 24)

            Button(action: {
                self.viewModel.handleRecordTapAction()
                self.isRecording.toggle()
            }) {
                Text(isRecording ? "Stop" : "Record")
                    .padding()
                    .foregroundColor(.white)
            }
            .frame(width: 143, height: 45)
        }
        .padding()
    }

    private var timerView: some View {
        Text(viewModel.durationStr)
            .foregroundColor(.white)
    }
}

struct RoundedDashedCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.size.width, rect.size.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for angle in stride(from: 0, to: CGFloat.pi * 2, by: CGFloat.pi / 20) {
            let start = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let end = CGPoint(x: center.x + (radius - 4) * cos(angle), y: center.y + (radius - 4) * sin(angle))
            path.move(to: start)
            path.addArc(tangent1End: start, tangent2End: end, radius: 2)
            path.addLine(to: end)
        }
        return path
    }
}
 
#Preview {
    FTRecordView()
}
