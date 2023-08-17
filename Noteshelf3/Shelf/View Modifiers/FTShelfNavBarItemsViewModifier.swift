//
//  FTShelfNavBarItemsViewModifier.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 25/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTShelfNavBarItemsViewModifier: ViewModifier {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showingPopover:Bool = false
    @State private  var isAnyPopoverShown: Bool = false

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var appState : AppState

    private var popOverHeight: CGFloat {
        return horizontalSizeClass == .regular ? 384.0 : 448 // increase the height of 52.0 if apple watch added in the popover view
    }
     func newNoteViewModel() -> FTNewNotePopoverViewModel {
         let shelfNewNoteViewModel =  FTNewNotePopoverViewModel()
        shelfNewNoteViewModel.delegate = shelfViewModel
        return shelfNewNoteViewModel
    }
   
    func body(content: Content) -> some View {
            content
            .if(shelfViewModel.mode == .normal, transform: { view in
                view.toolbar {
                    ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarTrailing) {
                        if shelfViewModel.hasEvernotePublishError() {
                            Button {
                                self.shelfViewModel.delegate?.showEvernoteErrorInfoScreen()
                            } label: {
                                Image("nav-evernote-error")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24.0, height: 24.0)
                            }
                        }

                        if shelfViewModel.hasDropboxPublishError() {
                            Button {
                                self.shelfViewModel.delegate?.showDropboxErrorInfoScreen()
                            } label: {
                                Image("cloud-error")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24.0, height: 24.0)
                            }
                        }

                        if shelfViewModel.canShowNewNoteNavOption {
                            Button {
                                showingPopover = true
                            } label: {
                                Image(icon: .plus)
                                    .font(Font.appFont(for: .regular , with: 15.5))
                                    .foregroundColor(Color.appColor(.accent))
                            }
                                .popover(isPresented: $showingPopover) {
                                    FTShelfNewNotePopoverView(viewModel: newNoteViewModel(), popoverHeight: popOverHeight, appState: AppState(sizeClass: horizontalSizeClass ?? .regular),delegate: shelfViewModel.delegate as? FTShelfNewNoteDelegate)
                                    .presentationDetents([.height(popOverHeight)])
                                    .presentationDragIndicator(.hidden)
                                    .background(.regularMaterial)
                                    .popoverApperanceOperations(popoverIsShown: $isAnyPopoverShown)
                                }
                            }
                            Button {
                                if !shelfMenuOverlayInfo.isMenuShown {
                                    shelfViewModel.searchTapped()
                                }
                            } label: {
                                Image(icon: .search)
                                    .font(Font.appFont(for: .regular , with: 15.5))
                                    .foregroundColor(Color.appColor(.accent))
                            }
                            .frame(width: 44,height: 44,alignment: .center)
                        FTShelfSelectAndSettingsView(viewModel: shelfViewModel)
                            .frame(width: 44,height: 44,alignment: .center)
                    }
                }
            })
                .if(shelfViewModel.mode == .selection, transform: { view in
                    view.toolbar {
                        ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                            Button {
                                shelfViewModel.mode = .normal
                                shelfViewModel.finalizeShelfItemsEdit()
                                shelfMenuOverlayInfo.isMenuShown = false
                                if idiom == .phone {
                                    shelfViewModel.compactDelegate?.didChangeSelectMode(shelfViewModel.mode)
                                }
                            } label: {
                                Text(NSLocalizedString("done", comment: "Done"))
                                    .appFont(for: .regular, with: 17)
                                    .foregroundColor(Color.appColor(.accent))
                            }
                            .frame(height: 44)
                        }
                        ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                            if shelfViewModel.areAllItemsSelected {
                                Button {
                                    shelfViewModel.deselectAllItems()
                                } label: {
                                    Text(NSLocalizedString("shelf.navBar.selectNone", comment: "Select None"))
                                        .appFont(for: .regular, with: 17)
                                        .foregroundColor(Color.appColor(.accent))
                                }
                                .frame(height: 44)
                            } else {
                                Button {
                                    shelfViewModel.selectAllItems()
                                } label: {
                                    Text(NSLocalizedString("shelf.navBar.selectAll", comment: "Select All"))
                                        .appFont(for: .regular, with: 17)
                                        .foregroundColor(Color.appColor(.accent))
                                }
                                .frame(height: 44)
                            }
                        }
                    }
                })
                    .disabled(shelfViewModel.showDropOverlayView)
    }
}
