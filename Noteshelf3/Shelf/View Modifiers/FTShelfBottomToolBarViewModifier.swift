//
//  FTShelfBottomToolBarView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 18/05/22.
//

import SwiftUI

struct FTShelfBottomToolBarViewModifier: ViewModifier {
    @EnvironmentObject var viewModel: FTShelfBottomToolbarViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @State private var orientation = UIDevice.current.orientation

    func body(content: Content) -> some View {
//        let _ = Self._printChanges()
            content
            .if(!shelfViewModel.collection.isTrash && shelfViewModel.mode == .selection, transform: { view in
                view
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar){
                            Spacer()
                            Button {
                                viewModel.delegate?.shareShelfItems()
                            } label: {
                                self.getBottomToolBarLabelWith(icon: .share, title:FTShelfBottomBarOption.share.displayTitle)
                            }.disabled(!shelfViewModel.shouldSupportBottomBarOption(.share))
                                .if(shelfViewModel.shouldSupportBottomBarOption(.share)) { view in
                                    view.foregroundColor(Color.appColor(.accent))
                            }

                            Spacer()

                            Button {
                                viewModel.delegate?.moveShelfItems()
                            } label: {
                                self.getBottomToolBarLabelWith(icon: .folder, title:FTShelfBottomBarOption.move.displayTitle)
                            }.disabled(!shelfViewModel.shouldSupportBottomBarOption(.move))
                                .if(shelfViewModel.shouldSupportBottomBarOption(.move)) { view in
                                    view.foregroundColor(Color.appColor(.accent))
                            }

                            Spacer()

                            Button {
                                viewModel.delegate?.trashShelfItems()
                            } label: {
                                self.getBottomToolBarLabelWith(icon: .trash, title:FTShelfBottomBarOption.trash.displayTitle)
                            }.disabled(!shelfViewModel.shouldSupportBottomBarOption(.trash))
                                .if(shelfViewModel.shouldSupportBottomBarOption(.trash)) { view in
                                    view.foregroundColor(Color.appColor(.accent))
                            }

                            Spacer()

                            FTShelfBottomBarMoreOptionsView()
                                .environmentObject(shelfViewModel)
                                .disabled(shelfViewModel.disableBottomBarItems)
                                .onTapGesture {
                                    shelfMenuOverlayInfo.isMenuShown = true
                                }
                                .onDisappear {
                                    shelfMenuOverlayInfo.isMenuShown = false
                                }
                            Spacer()
                    }
                    }.macOnlyPlainButtonStyle()
                    .detectOrientation($orientation)
            })
                .if(shelfViewModel.collection.isTrash && shelfViewModel.mode == .selection, transform: { view in
                    view
                        .toolbar {
                            ToolbarItemGroup(placement: .bottomBar){
                                Spacer()
                                Button {
                                    viewModel.delegate?.restoreShelfItems()
                                } label: {
                                    self.getBottomToolBarLabelWith(icon: .restore, title:FTShelfBottomBarOption.restore.displayTitle)
                                }.disabled(shelfViewModel.disableBottomBarItems)
                                    .if(!shelfViewModel.disableBottomBarItems) { view in
                                        view.foregroundColor(Color.appColor(.accent))
                                }

                                Spacer()

                                Button {
                                    viewModel.delegate?.deleteShelfItems()
                                } label: {
                                    self.getBottomToolBarLabelWith(icon: .trash, title:FTShelfBottomBarOption.delete.displayTitle)
                                }.disabled(shelfViewModel.disableBottomBarItems)
                                    .if(!shelfViewModel.disableBottomBarItems) { view in
                                        view.foregroundColor(Color.appColor(.destructiveRed))
                                }
                                Spacer()
                        }
                        } .macOnlyPlainButtonStyle()
                        .detectOrientation($orientation)
                })
        }
    private func getBottomToolBarLabelWith(icon: FTIcon, title:String) -> some View {
        return  HStack(alignment: .center, spacing:0.0) {
            if self.toShowCompactModeView() {
                Image(icon: icon)
                    .font(Font.appFont(for: .regular , with: 15))
                    .frame(width: 44,height: 30,alignment: .center)

            }else {
                Image(icon: icon)
                    .font(Font.appFont(for: .regular , with: 15))
                    .frame(width: 44,height: 30,alignment: .center)
                Text(title)
                    .appFont(for: .regular, with: 17)
            }
        }
    }

        private func toShowCompactModeView() -> Bool {
            var toShow = false
#if !targetEnvironment(macCatalyst)
            if idiom == .phone || horizontalSizeClass == .compact  || (horizontalSizeClass == .regular && shelfViewModel.showCompactBottombar) {
                toShow = true
            }
#endif
            return toShow
    }
}
