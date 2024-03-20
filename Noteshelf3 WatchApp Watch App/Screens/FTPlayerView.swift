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
    @Binding var isShowingPlayerView: Bool

    @State private var isEditOptionsShowing = false
    @EnvironmentObject var recordVm: FTRecordViewModel
    @State private var showInProgressRecordAlert = false

    private let progressColor = Color(red: 224/255, green: 110/255, blue: 81/255)

    var body: some View {
        VStack {
            Spacer()

            Text(recording.audioTitle)
                .font(Font.system(size: 17))
                .bold()
            Text(self.viewModel.playDurationStr)
                .font(Font.system(size: 17))

            Spacer()

            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 12.0)

                Button {
                    if self.recordVm.isRecording {
                        self.showInProgressRecordAlert = true
                    } else {
                        self.viewModel.backwardPlayBy(15)
                    }
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
                    if self.recordVm.isRecording {
                        self.showInProgressRecordAlert = true
                    } else {
                        self.viewModel.forwardPlayBy(15)
                    }
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
        }
        .padding(.vertical)
        .toolbar {
            toolBar()
        }
        .fullScreenCover(isPresented: $isEditOptionsShowing, content: {
            FTRecordingEditView(viewModel: FTRecordingEditViewModel(recording: self.recording), isEditOptionsShowing: $isEditOptionsShowing, isShowingPlayerView: $isShowingPlayerView)
                .onDisappear {
                    self.viewModel.updateRecording(self.recording)
                }
        })
        .alert(isPresented: $showInProgressRecordAlert) {
            Alert(
                title: Text(""),
                message: Text("Recording is in progress..."),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK"))) {
                }
            )
        }
        .onDisappear {
            self.viewModel.resetPlay()
        }
    }

    private var recording: FTWatchRecording {
        self.viewModel.recording
    }

    private func toolBar() -> some ToolbarContent {
        if #available(watchOS 10.0, *) {
            return ToolbarItem(placement: .topBarTrailing) {
                editOptionsButton
            }
        } else {
            return ToolbarItem(placement: .automatic) {
                editOptionsButton
            }
        }
    }

    private var editOptionsButton: some View {
        Button {
            if self.recordVm.isRecording {
                self.showInProgressRecordAlert = true
            } else {
                self.isEditOptionsShowing = true
            }
        } label: {
            Image(systemName: "ellipsis")
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
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))

                Button(action: {
                    if self.recordVm.isRecording {
                        self.showInProgressRecordAlert = true
                    } else {
                        self.viewModel.handlePlayTapAction()
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause" : "play.fill")
                        .resizable()
                        .frame(width: 18, height: 20)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
