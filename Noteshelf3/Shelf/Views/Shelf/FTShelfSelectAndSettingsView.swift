//
//  FTShelfSelectAndSettingsView.swift
//  Noteshelf3
//
//  Created by Rakesh on 28/04/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfSelectAndSettingsView: View {
    @ObservedObject var viewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let sortOptions = FTShelfSortOrder.supportedSortOptions()
    
    var body: some View {
        Menu(content: {
            VStack{
                getMoreSectionitem(.selectNotes, viewmodel: viewModel)
                .disabled(viewModel.shelfItems.isEmpty)
                Divider()
                sortView
                Divider()
                FTShelfDisplayStyleView()
                    .environmentObject(viewModel)
                Divider()
                getMoreSectionitem(.settings,viewmodel: viewModel)
            }
        }, label: {
            Image(icon: .ellipsis)
                .foregroundColor(Color.appColor(.accent))
                .font(Font.appFont(for: .regular , with: 15.5))
        })
        .onTapGesture {
            if(!shelfMenuOverlayInfo.isMenuShown) {
                shelfMenuOverlayInfo.isMenuShown = true;
            }
        }
    }
    
    var sortView: some View{
        ForEach(sortOptions, id: \.displayTitle) { sortOption in
            Button(action: {
                shelfMenuOverlayInfo.isMenuShown = false
                withAnimation {
                    viewModel.sortOption = sortOption;
                }
            }, label: {
                Toggle(isOn: .constant(viewModel.sortOption == sortOption)) {
                    Label {
                        Text(sortOption.displayTitle)
                            .font(Font.appFont(for: .regular , with: 17))
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName:sortOption.iconName)
                            .frame(width: 16,height: 24,alignment: .center)
                            .font(Font.appFont(for: .regular , with: 20))
                            .foregroundColor(.primary)
                    }
                }
            })
        }
        
    }
    
    private func getMoreSectionitem(_ type: FTHomeNavItemFilteredItemsModel,viewmodel:FTShelfViewModel) -> some View {
        FTMoreItemView(type: type,viewModel:viewmodel)
    }
}
struct FTMoreItemView:View{
    var type:FTHomeNavItemFilteredItemsModel
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let viewModel:FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    var body: some View{
        Button {
            shelfMenuOverlayInfo.isMenuShown = false
            switch type {
            case .selectNotes:
                if idiom == .phone {
                    viewModel.compactDelegate?.didChangeSelectMode(.selection)
                }
                viewModel.mode = .selection
            case .settings:
                viewModel.delegate?.showSettings()
            }
        } label: {
            Label {
                Text(type.displayTitle)
                    .font(Font.appFont(for: .regular , with: 17))
                    .foregroundColor(.primary)
            } icon: {
                Image(type.iconName)
                    .frame(width: 16,height: 24,alignment: .center)
                    .font(Font.appFont(for: .regular , with: 20))
                    .foregroundColor(.primary)
            }
        }
    }
}

//struct FTShelfSelectAndSettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        FTShelfSelectAndSettingsView(viewModel: FTShelfViewModel())
//    }
//}

enum FTHomeNavItemFilteredItemsModel: CaseIterable {
    case selectNotes
    case settings
    
    var displayTitle: String {
        let title: String
        switch self {
        case .selectNotes:
            title = NSLocalizedString("shelf.navmenu.selectNotes", comment: "Select Notes")
        case .settings:
            title = NSLocalizedString("Settings", comment: "Settings")
        }
        return title
    }
    
    var iconName: String {
        let name: String
        switch self {
        case .selectNotes:
            name = FTIcon.selectnotes.name
        case .settings:
            name = FTIcon.settings.name
        }
        return name
    }
    #if targetEnvironment(macCatalyst)
    var menuIdenfier: UIAction.Identifier? {
        switch self {
        case .selectNotes:
            return UIAction.Identifier("shelfSelectNotes")
        case .settings:
            return UIAction.Identifier("shelfSettings")
        }
    }
    #endif
}

private struct FTShelfDisplayStyleView : View {
    @EnvironmentObject var viewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    let displayOptions = FTShelfDisplayStyle.supportedStyles;
    var body: some View {
        ForEach(displayOptions, id: \.displayTitle) { newValue in
            Button(action: {
                shelfMenuOverlayInfo.isMenuShown = false
                withAnimation {
                    viewModel.displayStlye = newValue;
                }
            }, label: {
                Toggle(isOn: .constant(viewModel.displayStlye == newValue)) {
                    Label {
                        Text(newValue.displayTitle)
                            .font(Font.appFont(for: .regular , with: 17))
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName:newValue.iconName)
                            .frame(width: 16,height: 24,alignment: .center)
                            .font(Font.appFont(for: .regular , with: 20))
                            .foregroundColor(.primary)
                    }
                }
            })
        }
    }
}
