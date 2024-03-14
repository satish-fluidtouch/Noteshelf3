//
//  FTRecordView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

private let opacityValues: [Double] = [1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0]
private let gradientColors: [Color] = opacityValues.map { opacity in
    Color(red: 224/255, green: 110/255, blue: 81/255)
        .opacity(opacity)
}
private let gradient = AngularGradient(gradient: Gradient(colors: gradientColors), center: .center, angle: .degrees(0))

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
    private let gradient = AngularGradient(gradient: Gradient(colors: gradientColors), center: .center, angle: .degrees(0))

    var body: some View {
        ZStack {
            Circle()
                .fill(gradientColors[8])
                .frame(width: 118.0)

            Circle()
                .fill(gradientColors[0])
                .frame(width: 74)

            Circle()
                .stroke(style: StrokeStyle(lineWidth: borderWidth))
                .foregroundStyle(gradientColors[7])
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
                    .fill(gradientColors[8])
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
            .foregroundStyle(gradientColors[7])
            .overlay {
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(gradient, style: StrokeStyle(lineWidth: borderWidth))
                    .rotationEffect(.degrees(angle))
            }
            .rotationEffect(.degrees(-90))
    }
}

#Preview {
    FTRecordView()
}
