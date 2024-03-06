//
//  FTRecordingsView.swift
//  Noteshelf3 WatchApp Watch App
//
//  Created by Narayana on 28/02/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTRecordingsView: View {
    @ObservedObject var viewModel: FTRecordingsViewModel

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text(viewModel.title)
                        .font(Font.system(size: 14))
                        .padding(.leading, 12)
                    Spacer()
                }

                List {
                    ForEach(viewModel.recordings, id: \.uuid) { recording in
                        NavigationLink(destination: FTPlayerView(recording: recording)) {
                            recordingView(for: recording)
                        }
                    }
                }
            }
        }
    }

    private func recordingView(for recording: FTRecording) -> some View {
        VStack {
            HStack {
                Text(recording.duration)
                    .font(Font.system(size: 16))
                    .bold()
                Spacer()
            }
            HStack {
                Text(recording.dateTimeInfo)
                    .font(Font.system(size: 16))
                Spacer()
            }
        }
    }
}

#Preview {
    FTRecordingsView(viewModel: FTRecordingsViewModel())
}
