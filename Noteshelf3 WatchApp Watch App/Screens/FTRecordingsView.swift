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

    var body: some View {
        ZStack {
            if viewModel.recordings.isEmpty {
                Text("No Recordings!")
                    .font(Font.system(size: 18))
            } else {
                VStack {
                    HStack {
                        Text(viewModel.title)
                            .font(Font.system(size: 14))
                            .padding(.leading, 12)
                        Spacer()
                    }

                    List {
                        ForEach(viewModel.recordings, id: \.GUID) { recording in
                            recordingView(for: recording)
                                .onTapGesture {
                                    viewModel.selectedRecording = recording
                                    isShowingPlayerView = true
                                }
                        }
                        .onDelete(perform: deleteItem)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                            } label: {
                                Image(systemName: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .fullScreenCover(isPresented: $isShowingPlayerView) {
                    if let recording = self.viewModel.selectedRecording {
                        FTPlayerView(viewModel: FTPlayerViewModel(recording: recording), isShowingPlayerView: $isShowingPlayerView)
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

    private func deleteItem(at offsets: IndexSet) {
        if let recordingToDelete = offsets.map({ self.viewModel.recordings[$0] }).first {
            self.viewModel.deleteRecording(recordingToDelete)
        }
    }

    private func recordingView(for recording: FTWatchRecording) -> some View {
        VStack {
            HStack {
                Text(recording.duration.formatSecondsToString())
                    .font(Font.system(size: 16))
                    .bold()
                Spacer()
            }
            HStack {
                Text(recording.audioTitle)
                    .font(Font.system(size: 16))
                Spacer()
            }
        }
    }
}

#Preview {
    FTRecordingsView()
}
