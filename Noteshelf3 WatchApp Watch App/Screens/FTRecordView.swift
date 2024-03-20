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
                                                                    gradientColor.opacity(0.4),
                                                                   gradientColor.opacity(0.7),
                                                                   gradientColor.opacity(1.0)]), center: .center, angle: .degrees(0))

struct FTRecordView: View {
    @ObservedObject var viewModel: FTRecordViewModel

    var body: some View {
        ZStack {
            FTStartRecordView()
                .environmentObject(viewModel)
                .opacity(viewModel.isRecording ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isRecording)
            FTStopRecordView()
                .environmentObject(viewModel)
                .opacity(viewModel.isRecording ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isRecording)
         }
    }
}

struct FTStartRecordView: View {
    @EnvironmentObject var viewModel: FTRecordViewModel
    private let borderWidth: CGFloat = 4.0

    var body: some View {
        ZStack {
            Circle()
                .fill(gradientColor.opacity(0.3))
                .frame(width: 134)

            Circle()
                .fill(gradientColor)
                .frame(width: 82)
        }
        .onTapGesture {
            self.viewModel.handleRecordTapAction()
        }
        .alert(isPresented:self.viewModel.showCustomAlert) {
            Alert(
                title: Text(""),
                message: Text("Allow microphone access to continue..."),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK"))) {
                    self.viewModel.showPermissionAlert = false
                }
            )
        }
    }
}

struct FTStopRecordView: View {
    @State private var angle: Double = 0.0
    @EnvironmentObject var viewModel: FTRecordViewModel

    private let borderWidth: CGFloat = 4.0

    var body: some View {
        VStack(spacing: 22.0) {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.2), lineWidth: borderWidth)
                    .background(Circle().foregroundColor(gradientColor.opacity(0.3)))
                    .frame(width: 96)
                    .overlay {
                        SemiCircleShape(radius: 92/2)
                            .stroke(gradient, style: StrokeStyle(lineWidth: borderWidth))
                            .frame(width: 92)
                            .rotationEffect(.degrees(angle))
                    }
                    .rotationEffect(.degrees(-90))

                Text(viewModel.durationStr)
                    .foregroundColor(.white)
                    .font(Font.system(size: 30.0))
            }

            Button(action: {
                self.viewModel.handleRecordTapAction()
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
