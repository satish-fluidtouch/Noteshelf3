//
//  FTRecordingEditView.swift
//  Noteshelf3 WatchApp
//
//  Created by Narayana on 14/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTRecordingEditView: View {
    let viewModel: FTRecordingEditViewModel
    @Binding var isEditOptionsShowing: Bool
    @Binding var isShowingPlayerView: Bool

    @State private var isShowingDeleteView = false
    @State private  var isShowingRenameView = false
    @FocusState private var keyboardFocused: Bool

    @State private var text: String = ""

    // TODO: Narayana - to uncomment below when rename is completely supported
    var body: some View {
        VStack {
//            Spacer()
//                .frame(height: 16.0)
//
//            ZStack {
//                HStack {
//                    Text(FTRecordingEditOption.rename.title)
//                        .padding(.leading, 4)
//                    Spacer()
//                    Image(systemName: FTRecordingEditOption.rename.imageName)
//                        .padding(.trailing, 4)
//                }
//
//                TextField("", text: $text)
//                    .onSubmit {
//                        self.viewModel.renameRecording(with: text) { _ in
//                            self.isEditOptionsShowing = false
//                        }
//                    }
//            }

            HStack {
                Text(FTRecordingEditOption.delete.title)
                    .padding(.leading, 4)
                Spacer()
                Image(systemName: FTRecordingEditOption.delete.imageName)
                    .foregroundStyle(.red)
                    .padding(.trailing, 4)
            }
            .frame(height: 48.0)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.12)))

            .onTapGesture {
                self.isShowingDeleteView = true
            }
//            Spacer()
        }
        .padding(.horizontal)
        .fullScreenCover(isPresented: $isShowingDeleteView, content: {
            FTRecordingDeleteView(viewModel: viewModel, isShowingPlayerView: $isShowingPlayerView)
        })
    }
}

struct FTRecordingDeleteView: View {
    let viewModel: FTRecordingEditViewModel
    @Binding var isShowingPlayerView: Bool

    var body: some View {
        VStack(spacing: 16.0) {
            Text(viewModel.deleteConfirmInfo)
            Button(action: {
                self.viewModel.deleteRecording { _ in
                    self.isShowingPlayerView = false
                }
            }) {
                Text("Delete")
                    .foregroundColor(.red)
            }
            .frame(width: 143, height: 45)
        }
    }
}

#Preview {
    FTRecordingEditView(viewModel: FTRecordingEditViewModel(recording: FTWatchRecordedAudio(GUID: "12", date: Date(), duration: 2.0)), isEditOptionsShowing: .constant(false), isShowingPlayerView: .constant(false))
}
