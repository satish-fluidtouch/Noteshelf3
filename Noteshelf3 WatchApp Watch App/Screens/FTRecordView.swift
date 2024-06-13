//
//  FTRecordView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

private let gradientColor = Color(red: 255/255, green: 113/255, blue: 83/255)
private let gradient = AngularGradient(gradient: Gradient(colors:
                                                                   [gradientColor.opacity(0.1),
                                                                    gradientColor.opacity(0.4),
                                                                   gradientColor.opacity(0.7),
                                                                   gradientColor.opacity(1.0)]), center: .center, angle: .degrees(0))

struct FTRecordView: View {
    @ObservedObject var viewModel: FTRecordViewModel
    @State private var size: CGFloat = 0.0
    @State private var angle: Double = 0.0

    private let borderWidth: CGFloat = 4.0
    private let animDuration: CGFloat = 0.3

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: viewModel.isRecording ? 22 : 0) {
                if viewModel.isRecording {
                    Spacer()
                }

                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? .clear : gradientColor.opacity(0.3))
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.2), lineWidth: borderWidth)
                                .background(Circle().foregroundColor(gradientColor.opacity(0.3)))
                                .opacity(viewModel.isRecording ? 1.0 : 0.0)
                        )
                        .overlay {
                            SemiCircleShape(radius: (size - borderWidth)/2)
                                .stroke(gradient, style: StrokeStyle(lineWidth: borderWidth))
                                .frame(width: size - borderWidth)
                                .rotationEffect(.degrees(angle))
                                .opacity(viewModel.isRecording ? 1.0 : 0.0)
                        }
                        .rotationEffect(.degrees(viewModel.isRecording ? -90 : 0))
                        .onChange(of: viewModel.isRecording) { newValue in
                            if newValue {
                                withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                                    angle = 360
                                }
                            }
                        }

                    Circle()
                        .fill(gradientColor)
                        .frame(width: proxy.size.width * 0.45)
                        .opacity(viewModel.isRecording ? 0.0 : 1.0)

                    Text(viewModel.durationStr)
                        .foregroundColor(.white)
                        .font(Font.system(size: 30.0))
                        .opacity(viewModel.isRecording ? 1.0 : 0.0)
                }
                .frame(width: self.size)

                Button(action: {
                    self.viewModel.handleRecordTapAction()
                    self.size = proxy.size.width * 0.75
                }) {
                    Text("Stop")
                        .padding()
                        .foregroundColor(.white)
                }
                .frame(width: viewModel.isRecording ? 143 : 0, height: viewModel.isRecording ? 45 : 0)
                .opacity(viewModel.isRecording ? 1.0 : 0.0)

                Spacer()
                    .frame(height: viewModel.isRecording ? 17.0 : 0.0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(Animation.easeInOut(duration: animDuration), value: self.size)

            .onAppear {
                if !viewModel.isRecording {
                    // Initial setup
                    self.size = proxy.size.width * 0.75
                }
            }
            .onTapGesture {
                if !viewModel.isRecording {
                    // To record
                    self.size = proxy.size.height * 0.38
                    self.viewModel.handleRecordTapAction()
                }
            }
            .onChange(of: self.viewModel.isRecording) { newValue in
                // due to interpption, if recording is stopped, size needs to be updated
                if !newValue {
                    self.size = proxy.size.width * 0.75
                }
            }
            .alert(isPresented:self.viewModel.showCustomAlert) {
                Alert(
                    title: Text(""),
                    message: Text("Allow microphone access to continue..."),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK"))) {
                        self.viewModel.showPermissionAlert = false
                        self.size = proxy.size.width * 0.75
                    }
                )
            }
        }.ignoresSafeArea()
    }
}

struct SemiCircleShape: Shape {
    let radius: CGFloat

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
    FTRecordView(viewModel: FTRecordViewModel())
}
