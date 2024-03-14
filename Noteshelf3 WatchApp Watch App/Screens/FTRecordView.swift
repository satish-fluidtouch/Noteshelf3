//
//  FTRecordView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

private let gradientColor = Color(red: 224/255, green: 110/255, blue: 81/255)
private let gradient = AngularGradient(gradient: Gradient(colors:
                                                                   [gradientColor.opacity(0.1),
                                                                   gradientColor.opacity(0.5),
                                                                   gradientColor.opacity(1.0)]), center: .center, angle: .degrees(0))

struct FTRecordView: View {
    @StateObject private var viewModel = FTRecordViewModel()
    @State private var isRecording: Bool = false

    var body: some View {
        if !isRecording {
            FTStartRecordView(isRecording: $isRecording)
                .environmentObject(viewModel)
        } else {
            FTStopRecordView(isRecording: $isRecording)
                .environmentObject(viewModel)
        }
    }
}

struct FTStartRecordView: View {
    @Binding var isRecording: Bool
    @EnvironmentObject var viewModel: FTRecordViewModel

    private let borderWidth: CGFloat = 4.0

    var body: some View {
        ZStack {
            Circle()
                .fill(gradientColor.opacity(0.2))
                .frame(width: 118.0)

            Circle()
                .fill(gradientColor)
                .frame(width: 74)

            Circle()
                .stroke(style: StrokeStyle(lineWidth: borderWidth))
                .foregroundStyle(gradientColor.opacity(0.3))
                .frame(width: 122)
        }
        .onTapGesture {
            self.viewModel.handleRecordTapAction()
            self.isRecording = true
        }
    }
}

struct FTStopRecordView: View {
    @Binding var isRecording: Bool
    @State private var angle: Double = 0.0
    @EnvironmentObject var viewModel: FTRecordViewModel

    private let borderWidth: CGFloat = 4.0

    var body: some View {
        VStack(spacing: 16.0) {
            ZStack {
                Text(viewModel.durationStr)
                    .foregroundColor(.white)
                    .font(Font.system(size: 30.0))

                Circle()
                    .fill(gradientColor.opacity(0.2))
                    .frame(width: 96)

                outerCircle
                    .frame(width: 100)
            }

            Button(action: {
                self.viewModel.handleRecordTapAction()
                self.isRecording = false
            }) {
                Text("Stop")
                    .padding()
                    .foregroundColor(.white)
            }
            .frame(width: 143, height: 45)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }

    var outerCircle: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: borderWidth))
            .foregroundStyle(gradientColor.opacity(0.3))
            .overlay {
                SemiCircleShape(radius: 100/2, cornerRadius: 10)
                    .stroke(gradient, style: StrokeStyle(lineWidth: borderWidth, lineCap: .butt))
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-90))
    }
}

struct SemiCircleShape: Shape {
    let radius: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x + radius, y: center.y))
        path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        return path
    }
}

#Preview {
    FTRecordView()
}
