//
//  FTTrashNavBarItemsViewModifier.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 05/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTTrashNavBarItemsViewModifier: ViewModifier {
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    func body(content: Content) -> some View {
            content
            .if(shelfViewModel.mode == .normal, transform: { view in
                view.toolbar {
                    ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarLeading) {
                        Button {
                            shelfViewModel.emptyTrash()
                        } label: {
                            Text(NSLocalizedString("shelf.emptyTrash", comment: "Empty Trash"))
                                .appFont(for: .regular, with: 17)
                        }
                        .disabled(shelfViewModel.shelfItems.isEmpty)
                        .if(!shelfViewModel.shelfItems.isEmpty, transform: { view in
                            view.foregroundColor(Color.appColor(.destructiveRed))
                        })
                    }
                    ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarTrailing) {
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
                        ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                            Button {
                                shelfViewModel.mode = .normal
                                shelfViewModel.finalizeShelfItemsEdit()
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
    }
}
