//
//  FTShelfNewNotePopoverView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/05/22.
//

import FTStyles
import SwiftUI

protocol FTShelfNewNotePopoverViewDelegate: AnyObject {
    func dismissPopover()
    func didTapOnWatchRecordings()
}

struct FTShelfNewNotePopoverView: View {
    @ObservedObject var viewModel: FTNewNotePopoverViewModel

    var appState : AppState
    weak var delegate: FTShelfNewNoteDelegate?
    weak var viewDelegate: FTShelfNewNotePopoverViewDelegate?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var shelfViewModel: FTShelfViewModel

    var body: some View {
        VStack {
            if appState.sizeClass == .compact {
                Spacer()
            }
            contentView
                .if(appState.sizeClass == .compact, transform: { view in
                    view .padding(.horizontal, 16)
                        .padding(.top,16)
                })
        }
        .macOnlyColorSchemeFixer()
    }
    private var contentView: some View {
        VStack(spacing:16.0) {
            FTNewNoteTopSectionView(viewModel: viewModel, delegate: delegate)
                .padding(.top,10)
            LazyVGrid(columns: gridItemLayout(), spacing: 0.0, content: {
                newNoteSection
            })
            .background(Color.appColor(.white60))
            .cornerRadius(16.0, corners: .allCorners)
            if appState.sizeClass == .compact {
                cancelView
            }
        }
        .padding(.horizontal,appState.sizeClass == .compact ? 0 : 16)
        .padding(.bottom,16)
        .listRowBackground(Color.clear)
        .background(Color.clear)
        .cornerRadius(16, corners: .allCorners)
    }
    private func gridItemLayout() -> [GridItem] {
        let spacing = 0.0
        let width: CGFloat = 320.0
        return [GridItem(GridItem.Size.adaptive(minimum: width), spacing: spacing, alignment: .bottom)]
    }
    private var newNoteSection: some View {
        ForEach(viewModel.displayableOptions.indices, id: \.self) { index in
            VStack(alignment:.center,spacing: 0.0) {
                if viewModel.displayableOptions[index].newNoteOption == .appleWatch {
                    NavigationLink(destination: FTWatchRecordedListReprasentableView(delegate: shelfViewModel.delegate).navigationBarBackButtonHidden(true)){
                        newNoteSectionitem(index: index)
                    }
                }else{
                    newNoteSectionitem(index: index)
                }
            }
                .contentShape(Rectangle())
                .onTapGesture {
                    self.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){
                        self.performActionBasedOn(option: viewModel.displayableOptions[index])
                    }
                }
                .disabled(shouldDisableRow(for: index))
                .opacity(shouldDisableRow(for: index) ? 0.4 : 1)
        
                if index != (viewModel.displayableOptions.count - 1) {
                    FTDividerLine()
                }
            }
        }

    private func newNoteSectionitem(index: Int) -> some View {
        HStack(alignment: .center){
            getLabelWithTitle(viewModel.displayableOptions[index].newNoteOption.displayTitle,
                              image: viewModel.displayableOptions[index].newNoteOption.icon.name,
                              foregroundColor: Color.appColor(.accent),
                              isSystemImage: viewModel.displayableOptions[index].newNoteOption.icon.isSystemIcon)
            Spacer()
            if viewModel.displayableOptions[index].newNoteOption.showChevron {
                Image(systemName: "chevron.right")
                    .frame(width: 10, height: 24, alignment: SwiftUI.Alignment.center)
                    .padding(.trailing,16)
                    .font(Font.appFont(for: .regular, with: 15))
                    .foregroundColor(Color.appColor(.black50))
            }

        }
    }
    private func performActionBasedOn(option: FTNewNotePopoverModel){

//        if option.newNoteOption != .appleWatch { // only incase of watch recordings we are showing the recordings inside popover itself.
//            viewDelegate?.dismissPopover()
//        }

        // Track Event
        shelfViewModel.trackEventForAddMenuoption(option: option.newNoteOption)
        switch option.newNoteOption {
        case .newNotebook:
            viewModel.delegate?.showNewNotebookPopover()
            track(EventName.shelf_addmenu_tap, screenName: ScreenName.shelf)
        case .photoLibrary:
            delegate?.didTapPhotoLibrary()
        case .takePhoto:
            delegate?.didTapTakePhoto()
        case .importFromFiles:
            delegate?.didClickImportNotebook()
        case .scanDocument:
            delegate?.didClickScanDocument()
        case .quickNote:
            viewModel.delegate?.quickCreateNewNotebook()
        case .audioNote:
            delegate?.didTapAudioNote()
        case .newGroup:
            delegate?.didTapOnNewGroup()
        case .appleWatch:
            viewDelegate?.didTapOnWatchRecordings()
        }
    }
    private var cancelView: some View {
        HStack {
            Button {
                self.dismiss()
            } label: {
                Spacer()
                Text("Cancel".localized)
                Spacer()
            }
        }
        .frame(minWidth: 298, idealWidth: 298, maxWidth: .infinity,minHeight: 44, maxHeight: 44, alignment: Alignment.center)
        .foregroundColor(.primary)
        .background(Color.appColor(.white70))
        .cornerRadius(10.0)
        .contentShape(Rectangle())
        .padding(.bottom,24)
    }
    private func getLabelWithTitle(_ title: String, image:String, foregroundColor color: Color, isSystemImage: Bool = true) -> some View {
        Label {
            Text(title)
                .frame(alignment: .leading)
                .font(Font.appFont(for: .regular, with: 17))
                .foregroundColor(Color.label)
        } icon: {
            ZStack {
                if isSystemImage {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(color)
                        .font(Font.appFont(for: .regular, with: 20))
                } else{
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(color)
                        .font(Font.appFont(for: .regular, with: 20))
                }
            }
            .frame(width: 24, height: 24, alignment: .center)
            .padding(.leading,16)
            .padding(.trailing,10)
        }
        .frame(height:52.0)
    }
    
    private func shouldDisableRow(for index: Int) -> Bool {
        return (viewModel.displayableOptions[index].newNoteOption == .newGroup && shelfViewModel.isAllNotesCollection())
    }
}

struct FTShelfNewNotePopoverView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Image("orangeBand")
            FTShelfNewNotePopoverView(viewModel: FTNewNotePopoverViewModel(), appState: AppState(sizeClass: UserInterfaceSizeClass.regular))
                .environmentObject(FTNewNotePopoverViewModel())
        }
    }
}
