//
//  FTRecordingsView.swift
//  Noteshelf3 WatchApp Watch App
//
//  Created by Narayana on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTRecordingsView: View {
    @StateObject private var viewModel = FTRecordingsViewModel()
    @State private var isShowingPlayerView = false
    @EnvironmentObject var recordVm: FTRecordViewModel

    var body: some View {
        ZStack {
            if viewModel.recordings.isEmpty {
                Text("No Recordings!")
                    .font(Font.system(size: 18))
            } else {
                ZStack {
                    NavigationStack {
                        listView
                    }
                }
                .fullScreenCover(isPresented: $isShowingPlayerView) {
                    if let recording = self.viewModel.selectedRecording {
                        FTPlayerView(viewModel: FTPlayerViewModel(recording: recording), isShowingPlayerView: $isShowingPlayerView)
                            .environmentObject(recordVm)
                    }
                }
            }
        }.onAppear {
            self.viewModel.reloadRecordings()
        } .onChange(of: isShowingPlayerView) { newValue in
            if !newValue {
                self.viewModel.reloadRecordings()
            }
        }
    }

    private var listView: some View {
        List {
            ForEach(viewModel.recordings, id: \.GUID) { recording in
                recordingView(for: recording)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedRecording = recording
                        isShowingPlayerView = true
                    }
            }
        }
    }

    private func recordingView(for recording: FTWatchRecording) -> some View {
        VStack {
            HStack {
                Text(recording.audioTitle)
                    .font(Font.system(size: 16))
                    .bold()
                Spacer()
            }
            HStack {
                Text(recording.duration.formatSecondsToString())
                    .font(Font.system(size: 16))
                Spacer()
            }
        }
    }
}

#Preview {
    FTRecordingsView()
}
