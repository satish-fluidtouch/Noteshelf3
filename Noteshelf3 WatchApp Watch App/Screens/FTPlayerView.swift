//
//  FTPlayerView.swift
//  Noteshelf3 WatchApp Watch App
//
//  Created by Narayana on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTPlayerView: View {
    let recording: FTWatchRecording
    var progress: CGFloat = 0.3

    var body: some View {
        VStack {
            Spacer()

            Text(FTWatchUtils.timeFormatted(totalSeconds: UInt(recording.duration)))
            Text(recording.date.nsAudioFormatTitle())

            Spacer()

            HStack {
                Button {

                } label: {
                    Image("backward15")
                        .resizable()
                        .frame(width: 36, height: 36)
                }
                .padding(.leading, 10)

                Spacer()

                playPauseProgressView
                    .background(.clear)

                Spacer()

                Button {

                } label: {
                    Image("forward15")
                        .resizable()
                        .frame(width: 36, height: 36)
                }
                .padding(.trailing, 10)
            }
        }
    }

    private var playPauseProgressView: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 54, height: 54)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))

                Button(action: {
                    //                    withAnimation {
                    //                        self.progress =
                    //                    }
                }) {
                    Image(systemName: "pause")
                        .resizable()
                        .frame(width: 18, height: 20)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
