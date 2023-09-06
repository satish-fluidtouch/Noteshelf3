//
//  FTShelfBottomBarMoreOptionsView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 19/05/22.
//

import SwiftUI

struct FTShelfBottomBarMoreOptionsView: View {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var toolBarViewModel: FTShelfBottomToolbarViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var orientation = UIDevice.current.orientation

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var body: some View {
        Menu {
            let options = shelfViewModel.getMoreOptionsBasedOnCurrentCollection()
            ForEach(options, id: \.self) { option in
                Button(action: {
                    // Track Event
                    shelfViewModel.trackEventForShelfBottombar(option: option)
                    switch option {
                    case .createGroup:
                        toolBarViewModel.delegate?.createGroup()
                    case .changeCover:
                        toolBarViewModel.delegate?.changeCover()
                    case .rename:
                        toolBarViewModel.delegate?.renameShelfItems()
                    case .duplicate:
                        toolBarViewModel.delegate?.duplicateShelfItems()
                    case .tags:
                        toolBarViewModel.delegate?.tagsShelfItems()
                    default: break
                    }
                }, label: {
                    Label {
                        Text(option.displayTitle)
                            .fontWeight(.regular)
                            .appFont(for: .regular, with: 15)
                            .foregroundColor(Color.black)
                    } icon: {
                        Image(icon: option.icon)
                            .frame(width: 16, height: 24, alignment: SwiftUI.Alignment.center)
                            .foregroundColor(Color.black)
                            .font(Font.appFont(for: .regular , with: 15))
                    }
                })
                .disabled(!shelfViewModel.shouldSupportBottomBarOption(option))
            }
        } label: {
            if toShowCompactModeView() {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 44,height: 30,alignment: .center)
                        .if(!shelfViewModel.disableBottomBarItems) { view in
                            view.foregroundColor(.appColor(.accent))
                        }
                        .font(Font.appFont(for: .regular , with: 15))
                }else {
                    HStack(alignment: .center,spacing: 0.0) {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: 44,height: 30,alignment: .center)
                            .font(Font.appFont(for: .regular , with: 15))
                        Text("more".localized)
                            .appFont(for: .regular, with: 15)
                    }
                    .if(!shelfViewModel.disableBottomBarItems) { view in
                        view.foregroundColor(Color.appColor(.accent))
                    }
                }
        }
    }

    private func toShowCompactModeView() -> Bool {
        var toShow = false
#if !targetEnvironment(macCatalyst)
        if idiom == .phone || horizontalSizeClass == .compact || shelfViewModel.showCompactBottombar {
            toShow = true
        }
#endif
        return toShow
    }
}

struct FTShelfBottomBarMoreOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfBottomBarMoreOptionsView()
    }
}
