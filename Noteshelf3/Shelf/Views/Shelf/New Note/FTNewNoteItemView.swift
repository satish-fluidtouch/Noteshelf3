//
//  FTNewNoteItemView.swift
//  Noteshelf3
//
//  Created by Rakesh on 31/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTNewNoteItemView:View{

    let type: FTNewNotePopoverOptions
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject  var delegate:FTShelfViewModel
    @ObservedObject var viewModel: FTNewNotePopoverViewModel

    var body: some View{
        VStack(alignment: .leading){
            Button {
                switch type {
                case .quickNote:
                    self.dismiss()
                    track(EventName.shelf_addmenu_quicknote_tap, params: [EventParameterKey.location: delegate.shelfLocation()], screenName: ScreenName.shelf)
                    runInMainThread(0.01) {
                        viewModel.delegate?.quickCreateNewNotebook()
                    }
                case .newNotebook:
                    track(EventName.shelf_addmenu_newnotebook_tap, params: [EventParameterKey.location: delegate.shelfLocation()], screenName: ScreenName.shelf)
                    self.dismiss()
                    runInMainThread(0.01){
                        viewModel.delegate?.showNewNotebookPopover()
                    }
                case .importFromFiles:
                    track(EventName.shelf_addmenu_importfile_tap, params: [EventParameterKey.location: delegate.shelfLocation()], screenName: ScreenName.shelf)
                    self.dismiss()
                    runInMainThread(0.01){
                        delegate.delegate?.didClickImportNotebook()
                    }
                default:
                    break
                }
            } label: {
                HStack{
                    Image(icon: type.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32.0,height: 32.0)
                        .padding(.leading, 12)

                    LabeledContent {
                        if type == .quickNote {
                            Spacer()

                            Image(icon: .quickCreateSettings)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16.0,height: 24.0)
                                .padding(.trailing,16)
                                .foregroundColor(.label.opacity(0.5))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.dismiss()
                                    runInMainThread(0.01) {
                                        self.delegate.presentPaperTemplateFormsheet()
                                    }
                                }
                        }
                    } label: {
                        Text(type.displayTitle)
                            .foregroundColor(.label)
                            .font(Font.appFont(for: .regular, with: 16))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60.0)
                .background(Color.appColor(.white60))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appColor(.accentBorder), lineWidth: 1.0)
                )
            }
            .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .slow))
        }
    }
}

    struct FTNewNoteItemView_Previews: PreviewProvider {
        static var previews: some View {
            FTNewNoteItemView(type: .quickNote, viewModel: FTNewNotePopoverViewModel())
        }
    }

