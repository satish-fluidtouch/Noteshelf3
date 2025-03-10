//
//  FTTrashNavBarItemsViewModifier.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 05/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTTrashNavBarItemsViewModifier: ViewModifier {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var toolbarID: String = UUID().uuidString
    func body(content: Content) -> some View {
            content
            .if(shelfViewModel.mode == .normal, transform: { view in
                view.toolbar {
                    ToolbarItem(id:"Empty Trash" + toolbarID,
                                placement: ToolbarItemPlacement.navigationBarLeading)  {
                        Button {
                            shelfViewModel.emptyTrash()
                            // Track Event
                            track(EventName.shelf_select_trash_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)

                        } label: {
                            Text(NSLocalizedString("shelf.emptyTrash", comment: "Empty Trash"))
                                .appFont(for: .regular, with: 17)
                        }
                        .disabled(shelfViewModel.shelfItems.isEmpty)
                        .if(!shelfViewModel.shelfItems.isEmpty, transform: { view in
                            view.foregroundColor(Color.appColor(.destructiveRed))
                        })
                    }
                    ToolbarItem(id:"Select" + toolbarID,
                                placement: ToolbarItemPlacement.navigationBarTrailing) {
                        Button {
                            shelfViewModel.mode = .selection
                        } label: {
                            Text(NSLocalizedString("shelf.navBar.select", comment: "Select"))
                                .appFont(for: .regular, with: 17)
                        }
                        .frame(height: 44)
                        .disabled(shelfViewModel.shelfItems.isEmpty)
                        .if(!shelfViewModel.shelfItems.isEmpty, transform: { view in
                                view.foregroundColor(Color.appColor(.accent))
                        })
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
                                // Track Event
                                track(EventName.shelf_select_done_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
                            } label: {
                                Text(NSLocalizedString("done", comment: "Done"))
                                    .appFont(for: .regular, with: 17)
                                    .foregroundColor(Color.appColor(.accent))
                            }
                            .frame(height: 44)
                        }
                        ToolbarItem(id:"SelectAllOrNone" + toolbarID,
                                    placement: ToolbarItemPlacement.navigationBarLeading) {
                            if shelfViewModel.areAllItemsSelected {
                                Button {
                                    shelfViewModel.deselectAllItems()
                                    // Track Event
                                    track(EventName.shelf_select_selectnone_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
                                } label: {
                                    Text(NSLocalizedString("shelf.navBar.selectNone", comment: "Select None"))
                                        .appFont(for: .regular, with: 17)
                                        .foregroundColor(Color.appColor(.accent))
                                }
                                .frame(height: 44)
                            } else {
                                Button {
                                    shelfViewModel.selectAllItems()
                                    // Track Event
                                    track(EventName.shelf_select_selectall_tap, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
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
                .onChange(of: horizontalSizeClass) { _ in
                    toolbarID = UUID().uuidString
                }
                .onChange(of: verticalSizeClass) { _ in
                    toolbarID = UUID().uuidString
                }
    }
}
