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
    @State var isShowingDeleteView: Bool = false
    @State var isShowingRenameView: Bool = false

    var body: some View {
        List {
            ForEach(FTRecordingEditOption.allCases, id: \.rawValue) { option in
                HStack {
                    Text(option.title)
                    Spacer()
                    Image(systemName: option.imageName)
                        .tint(option == .delete ? .red : .white)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if option == .delete {
                        self.isShowingDeleteView = true
                    } else if option == .rename {
                        self.isShowingRenameView = true
                    }
                }
                .fullScreenCover(isPresented: $isShowingDeleteView, content: {
                    FTRecordingDeleteView(viewModel: viewModel)
                })
                .fullScreenCover(isPresented: $isShowingRenameView, content: {
                    FTRecordingRenameView(viewModel: viewModel)
                })
            }
        }
    }
}

struct FTRecordingDeleteView: View {
    let viewModel: FTRecordingEditViewModel

    var body: some View {
        VStack {
            Text(viewModel.deleteConfirmInfo)
            Spacer()
            Button(action: {
                self.viewModel.handleAction(for: .delete)
            }) {
                Text("Delete")
                    .foregroundColor(.white)
            }
            .frame(width: 143, height: 45)
        }
    }
}

struct FTRecordingRenameView: View {
    let viewModel: FTRecordingEditViewModel
    @State var text: String = ""

    var body: some View {
        TextField("", text: $text)
            .onSubmit {
                print("zzzz - Rename")
            }
    }
}

#Preview {
    FTRecordingEditView(viewModel: FTRecordingEditViewModel(recording: FTWatchRecordedAudio(GUID: "12", date: Date(), duration: 2.0)))
}
