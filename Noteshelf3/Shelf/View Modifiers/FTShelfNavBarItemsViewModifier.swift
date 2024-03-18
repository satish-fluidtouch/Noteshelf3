//
//  FTShelfNavBarItemsViewModifier.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 25/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTShelfNavBarItemsViewModifier: ViewModifier {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @StateObject var backUpError: FTCloudBackupENPublishError = FTCloudBackupENPublishError(type: .cloudBackup);
    @StateObject var enPublishError: FTCloudBackupENPublishError = FTCloudBackupENPublishError(type: .enPublish);

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var showingPopover:Bool = false
    @State private  var isAnyPopoverShown: Bool = false
    @State private var toolbarID: String = UUID().uuidString

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var appState : AppState

    private var popOverHeight: CGFloat {
        var height = horizontalSizeClass == .regular ? 435.0 : 500 // increase the height of 52.0 if apple watch added in the popover view
        if(NSUbiquitousKeyValueStore.default.isWatchPaired() && NSUbiquitousKeyValueStore.default.isWatchAppInstalled() ) {
            height += 52
        }
        return height
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
                    if enPublishError.hasError {
                        ToolbarItem(id:"ENError" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarTrailing)  {
                            Button {
                                self.shelfViewModel.delegate?.showEvernoteErrorInfoScreen()
                            } label: {
                                Image("nav-evernote-error")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24.0, height: 24.0)
                            }
                        }
                    }

                    if backUpError.hasError {
                        ToolbarItem(id:"Cloud Error" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarTrailing)  {
                            Button {
                                self.shelfViewModel.delegate?.showDropboxErrorInfoScreen()
                            } label: {
                                Image("cloud-error")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24.0, height: 24.0)
                            }
                        }
                    }

                    if shelfViewModel.canShowNewNoteNavOption {
                        ToolbarItem(id:"Add Menu" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarTrailing)  {
                            Button {
                                showingPopover = true
                                track(EventName.shelf_addmenu_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
                            } label: {
                                Image(icon: .plus)
                                    .font(Font.appFont(for: .regular , with: 15.5))
                                    .foregroundColor(Color.appColor(.accent))
                            }
                            .popover(isPresented: $showingPopover) {
                                NavigationStack{
                                    FTShelfNewNotePopoverView(viewModel: newNoteViewModel(), appState: AppState(sizeClass: horizontalSizeClass ?? .regular),delegate: shelfViewModel.delegate as? FTShelfNewNoteDelegate)
                                        .background(.regularMaterial)
                                }
                                .frame(minWidth: 340.0,maxWidth: .infinity)
                                .frame(minHeight: popOverHeight)
                                //.frame(height: popOverHeight)
//                                .presentationDetents([.height(popOverHeight)])
                                .presentationDragIndicator(.hidden)
                                .popoverApperanceOperations(popoverIsShown: $isAnyPopoverShown)
                            }
                        }
                    }
                    ToolbarItem(id:"Search" + toolbarID,
                                placement: ToolbarItemPlacement.navigationBarTrailing)  {
                        Button {
                            if !shelfMenuOverlayInfo.isMenuShown {
                                shelfViewModel.searchTapped()
                                let locationName = shelfViewModel.shelfLocation()
                                track(EventName.shelf_search_tap, params: [EventParameterKey.location: locationName], screenName: ScreenName.shelf)
                            }
                        } label: {
                            Image(icon: .search)
                                .font(Font.appFont(for: .regular , with: 15.5))
                                .foregroundColor(Color.appColor(.accent))
                        }
                        .frame(width: 44,height: 44,alignment: .center)
                    }
                    ToolbarItem(id:"Menu options" + toolbarID,
                                placement: ToolbarItemPlacement.navigationBarTrailing)  {
                        FTShelfSelectAndSettingsView(viewModel: shelfViewModel)
                            .frame(width: 44,height: 44,alignment: .center)
                    }
                }
            })
                .if(shelfViewModel.mode == .selection, transform: { view in
                    view.toolbar {
                        ToolbarItem(id:"Done" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarTrailing) {
                            Button {
                                shelfViewModel.mode = .normal
                                shelfViewModel.finalizeShelfItemsEdit()
                                shelfMenuOverlayInfo.isMenuShown = false
                                if idiom == .phone {
                                    shelfViewModel.compactDelegate?.didChangeSelectMode(shelfViewModel.mode)
                                }
                                // Track Event
                                track(EventName.shelf_select_done_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)

                            } label: {
                                Text(NSLocalizedString("done", comment: "Done"))
                                    .appFont(for: .regular, with: 17)
                                    .foregroundColor(Color.appColor(.accent))
                            }
                            .frame(height: 44)
                        }
                        ToolbarItem(id:"Select" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarLeading) {
                            if shelfViewModel.areAllItemsSelected {
                                Button {
                                    // Track Event
                                    track(EventName.shelf_select_selectnone_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
                                    shelfViewModel.deselectAllItems()
                                } label: {
                                    Text(NSLocalizedString("shelf.navBar.selectNone", comment: "Select None"))
                                        .appFont(for: .regular, with: 17)
                                        .foregroundColor(Color.appColor(.accent))
                                }
                                .frame(height: 44)
                            } else {
                                Button {
                                    // Track Event
                                    track(EventName.shelf_select_selectall_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
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
                .onChange(of: horizontalSizeClass) { _ in
                    toolbarID = UUID().uuidString
                }
                .onChange(of: verticalSizeClass) { _ in
                    toolbarID = UUID().uuidString
                }
    }
}
