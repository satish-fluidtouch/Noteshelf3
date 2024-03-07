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

                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(recordColor)
                    .frame(width: 110, height: 110)
            }

            Spacer()
                .frame(height: 24)

            Button(action: {
                if !isRecording {
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
        Text(viewModel.durationStr)
            .foregroundColor(.white)
    }
}

#Preview {
    FTRecordView()
}
