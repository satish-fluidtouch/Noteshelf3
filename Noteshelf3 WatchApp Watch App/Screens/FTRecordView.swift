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
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    private let recordColor = Color(red: 224/255, green: 110/255, blue: 81/255)
    var viewModel: FTRecordViewModel

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

                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(recordColor)
                    .frame(width: 110, height: 110)
            }

            Spacer()
                .frame(height: 24)

            Button(action: {
                if !isRecording {
                    self.elapsedTime = 0
                    self.viewModel.recordAudio()
                }
                self.isRecording.toggle()
            }) {
                Text(isRecording ? "Pause" : "Record")
                    .padding()
                    .foregroundColor(.white)
            }
            .frame(width: 143, height: 45)
        }
        .padding()
    }

    private var timerView: some View {
        Text(formattedTime)
            .foregroundColor(.white)
            .onAppear {
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.elapsedTime += 1
                }
            }
            .onDisappear {
                self.timer?.invalidate()
            }
    }

    private var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        var formattedString = formatter.string(from: elapsedTime) ?? "00:00:00"
        if elapsedTime <= 3600 {
            let index = formattedString.startIndex
            formattedString.remove(at: index)
            formattedString.remove(at: index)
            formattedString.remove(at: index)
        }
        return formattedString
    }
}

#Preview {
    FTRecordView(viewModel: FTRecordViewModel())
}
