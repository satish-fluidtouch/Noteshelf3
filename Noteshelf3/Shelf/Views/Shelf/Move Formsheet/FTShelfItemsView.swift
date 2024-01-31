//
//  FTShelfItemsView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

enum FTShelfItemsPurpose {
    case shelf
    case finder
    case linking
}

protocol FTShelfItemsViewDelegate: AnyObject{
    func openShelfItemsOf(collection: FTShelfItemCollection?,group:FTGroupItemProtocol?)
    func dismisspopover()
    func didSelectShelfItem(_ item: FTShelfItemProtocol)
}

extension FTShelfItemsViewDelegate {
    func didSelectShelfItem(_ item: FTShelfItemProtocol) {
        print("Implement if needed")
    }
}

struct FTShelfItemsView: View {
    @ObservedObject var viewModel: FTShelfItemsViewModel

    weak var viewDelegate: FTShelfItemsViewDelegate?
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing:0.0) {
                    ForEach(viewModel.shelfItems.indices,id: \.self) { index in
                        let shelfItem = viewModel.shelfItems[index]
                        let islastItemInList = index == viewModel.shelfItems.count - 1
                        switch shelfItem.shelfItemType {
                        case .collection:
                            FTShelfItemCategoryView(shelfItem: shelfItem, isLastItemInList: islastItemInList).onTapGesture {
                                self.viewDelegate?.openShelfItemsOf(collection: shelfItem.collection, group: shelfItem.group)
                            }
                        case .group:
                            if let groupItem = shelfItem as? FTShelfGroupItem {
                                FTShelfItemGroupView(groupItem: groupItem, isLastItemInList: islastItemInList)
                                    .onTapGesture {
                                        if viewModel.isGroupItemEligibleForMoving(groupItem) {
                                            self.viewDelegate?.openShelfItemsOf(collection: shelfItem.collection, group: shelfItem.group)
                                        }
                                    }
                            }else {
                                EmptyView()
                            }
                        case .notebook:
                            if let notebookItem = shelfItem as? FTShelfNotebookItem {
                                FTShelfItemNotebookView(isLastItemInList: islastItemInList, notebookItem: notebookItem)
                                    .environmentObject(viewModel)
                                    .onTapGesture {
                                        if let item = notebookItem.notebook {
                                            if notebookItem.notDownloaded {
                                                notebookItem.downloadNotebook()
                                            } else if item.URL.downloadStatus() == .downloaded {
                                                viewModel.selectedShelfItemToMove = notebookItem.notebook
                                                self.viewDelegate?.didSelectShelfItem(item)
                                            }
                                        }
                                    }
                            }else {
                                EmptyView()
                            }
                        }
                    }
                }
                .background(Color.appColor(.cellBackgroundColor))
                .cornerRadius(10)
                .padding(.top,6)
                .padding(.trailing,24)
                .padding(.leading,24)
            }
            .safeAreaInset(edge: .bottom,spacing: 0) {
                if viewModel.showMoveButton {
                    moveButton
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.navigationItemTitle)
                        .font(Font.clearFaceFont(for: .medium, with: 20))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.purpose != .linking {
                        if viewModel.collection == nil && viewModel.purpose == .shelf {
                            Button {
                                viewModel.showNewCategoryCreationAlert()
                            } label: {
                                Image(systemName: "folder.badge.plus")
                                    .frame(width:44,height: 44,alignment: .center)
                                    .font(Font.appFont(for: .regular, with: 16))
                                    .foregroundColor(Color.appColor(.accent))
                            }
                        } else if viewModel.collection != nil {
                            Button {
                                if viewModel.purpose == .finder {
                                    viewModel.showNewNoteBookCreationAlert()
                                } else {
                                    viewModel.showNewGroupCreationAlert()
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width:44,height: 44,alignment: .center)
                                    .font(Font.appFont(for: .regular, with: 16))
                                    .foregroundColor(Color.appColor(.accent))
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.collection == nil {
                        Button {
                            viewDelegate?.dismisspopover()
                        } label: {
                            Text(NSLocalizedString("cancel", comment: "Cancel"))
                                .frame(alignment: .center)
                                .font(Font.appFont(for: .regular, with: 17))
                                .foregroundColor(Color.appColor(.accent))
                        }.isHidden(viewModel.purpose == .linking)
                    }
                }
            }
        }
        .onFirstAppear {
            Task {
                await viewModel.fetchUserCreatedCategories()
            }
        }

    }
    private var moveButton: some View {
        HStack {
            HStack {
                Spacer()
                Button {
                    viewModel.performMoveOperation()
                } label: {
                    Text(NSLocalizedString("shelf.MovePopover.MoveHere", comment: "Move Here"))
                        .foregroundColor(Color.white)
                        .appFont(for: .medium, with: 15)
                        .frame(maxWidth: .infinity,maxHeight: 36)
                }
                .disabled(viewModel.disableMoveButton)
                .contentShape(RoundedRectangle(cornerRadius: 10.0))
                .frame(maxWidth: .infinity,maxHeight: 36,alignment: .center)
                .background(viewModel.disableMoveButton ? Color.gray.opacity(0.2) : Color.appColor(.accent))
                .cornerRadius(10, corners: UIRectCorner.allCorners)
                .shadow(color: Color("moveHereShadowTint"), radius: 8,x: 0, y: 4)
                Spacer()
            }
            .padding(.top,16)
            .padding(.trailing,24)
            .padding(.leading,24)
            .padding(.bottom,24)
            .macOnlyPlainButtonStyle()
        }
        .background(Color.appColor(.formSheetBgColor))
    }
}

struct FTShelfItemsView_Previews: PreviewProvider {
    static var previews: some View {
        FTShelfItemsView(viewModel: FTShelfItemsViewModel(selectedShelfItems: []))
    }
}
