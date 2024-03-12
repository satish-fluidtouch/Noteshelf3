//
//  FTPlayerView.swift
//  Noteshelf3 WatchApp Watch App
//
//  Created by Narayana on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTPlayerView: View {
    @ObservedObject var viewModel: FTPlayerViewModel

    var body: some View {
        VStack {
            Spacer()

            Text(self.viewModel.playDurationStr)
            Text(recording.date.nsAudioFormatTitle())

            Spacer()

            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 12.0)

                Button {
                    self.viewModel.backwardPlayBy(15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 36, height: 36)
                .background(Color(red: 29/255, green: 29/255, blue: 29/255))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .buttonStyle(.plain)

                Spacer()

                playPauseProgressView
                    .buttonStyle(.plain)

                Spacer()

                Button {
                    self.viewModel.forwardPlayBy(15)
                } label: {
                    Image(systemName: "goforward.15")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 36, height: 36)
                .background(Color(red: 29/255, green: 29/255, blue: 29/255))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .buttonStyle(.plain)

                Spacer()
                .frame(width: 12.0)
            }
        }.toolbar {
            toolBar()
        }.onDisappear {
            self.viewModel.resetPlay()
        }
    }

    private var recording: FTWatchRecording {
        self.viewModel.recording
    }

    private func toolBar() -> some ToolbarContent {
        if #available(watchOS 10.0, *) {
            return ToolbarItem(placement: .automatic) {
                Text("Playing")
                    .foregroundStyle(Color.white)
            }
        } else {
            return ToolbarItem(placement: .automatic) {
                Text("Playing")
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
                    .trim(from: 0, to: self.viewModel.progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))

                Button(action: {
                    self.viewModel.handlePlayTapAction()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause" : "play")
                        .resizable()
                        .frame(width: 18, height: 20)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
