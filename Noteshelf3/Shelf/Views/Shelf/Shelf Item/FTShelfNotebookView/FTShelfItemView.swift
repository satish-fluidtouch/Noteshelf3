//
//  FTShelfItemView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 25/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTCommon

struct FTShelfItemView: View {

    @State private var selectedShelfItem: FTShelfItemViewModel?

    @State var activateNavigation = false
    @State var isAnyNBActionPopoverShown: Bool = false

    @ObservedObject var shelfItem: FTShelfItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var shelfItemWidth: CGFloat = 212
    var shelfItemHeight: CGFloat = 334

    var body: some View {
        //debugPrintChanges()
        ZStack(alignment: .init(horizontal: .center, vertical: .bottom)) {
            if let group = shelfItem as? FTGroupItemViewModel {
                groupViewFor(groupItem: group)
                    .frame(width: shelfItemWidth , height: shelfItemHeight , alignment: Alignment(horizontal: .center, vertical: .bottom))
            } else {
                notebookView(item: shelfItem)
                    .frame(width: shelfItemWidth , height: shelfItemHeight , alignment: Alignment(horizontal: .center, vertical: .bottom))
            }
        }
    }
    
    @ViewBuilder
    func groupView() -> some View {
        if(shelfViewModel.displayStlye == .List) {
            FTGroupListView(shelfItemWidth: shelfItemWidth,
                            shelfItemHeight: shelfItemHeight, isAnyNBActionPopoverShown: $isAnyNBActionPopoverShown)
        }
        else {
            FTGroupItemView(groupItemWidth: shelfItemWidth,
                            groupItemHeight: shelfItemHeight)
        }
    }
    
    @ViewBuilder
    func groupViewFor(groupItem: FTGroupItemViewModel) -> some View {
        groupView()
            .environmentObject(groupItem)
            .onTapGesture(perform: {
                if(self.shelfViewModel.mode == .selection) {
                    groupItem.isSelected.toggle();
                }
                else {
                    self.shelfViewModel.delegate?.setLastOpenedGroup(groupItem.model.URL)
                    self.shelfViewModel.groupViewOpenDelegate?.didTapOnShelfItem(groupItem.model);
                }
            })
            .onDrop(of: [.content],
                    delegate: FTShelfItemViewDropDelegate(item: groupItem, viewModel: shelfViewModel, shelfItemSize: shelfItemSize, dropRect: groupDropRect))
            .if(shelfViewModel.fadeDraggedShelfItem == groupItem, transform: { view in
                withAnimation(.easeInOut(duration: 1)) {
                    view.opacity(0.2)}})
                .if(shelfViewModel.fadeDraggedShelfItem == nil || shelfItem.isFavorited, transform: { view in
                    withAnimation(.default) {
                        view.opacity(1.0)}})
    }
    
    
    @ViewBuilder
    func notebookView() ->  some View {
        if(shelfViewModel.displayStlye == .List) {
            FTNotebookViewList(shelfItemWidth: shelfItemWidth, isAnyNBActionPopoverShown: $isAnyNBActionPopoverShown)
        }
        else {
            FTNotebookItemView(shelfItemWidth: shelfItemWidth,shelfItemHeight: shelfItemHeight,isAnyNBActionPopoverShown: $isAnyNBActionPopoverShown)
        }
    }
    
    @ViewBuilder
    func notebookView(item: FTShelfItemViewModel) -> some View
    {
        notebookView()
            .frame(width:shelfItemWidth, height: shelfItemHeight , alignment: .center)
            .environmentObject(item)
            .opacity(1.0)
            .onDrop(of: [.data],
                        delegate: FTShelfItemViewDropDelegate(item: shelfItem,
                                                              viewModel: shelfViewModel,
                                                              shelfItemSize: thumbnailSize,
                                                              dropRect: NotebookDropRect))
            .onTapGesture {
                if(shelfViewModel.mode == .selection) {
                    shelfItem.isSelected.toggle()
                }
                else {
                    shelfViewModel.openShelfItem(shelfItem, animate: true, isQuickCreatedBook: false)
                }
            }
            .if(shelfViewModel.fadeDraggedShelfItem == shelfItem, transform: { view in
                withAnimation(.easeInOut(duration: 1)) {
                    view.opacity(0.2)}
            })
            .if(shelfViewModel.fadeDraggedShelfItem == nil || shelfItem.isFavorited, transform: { view in
                    withAnimation(.default) {
                    view.opacity(1.0)}
            })
                .popover(item: $shelfItem.popoverType) { type in
                    if type == .getInfo {
                        FTShelfItemInfoView(shelfItemInfo: FTShelfItemInfo(title: shelfItem.title, location: shelfItemLocation, modifiedDate: shelfItem.model.fileModificationDate.shelfShortStyleFormat() , createdDate: shelfItem.model.fileCreationDate.shelfItemCreatedDateFormat()))
                            .frame(minWidth: 330,
                                   idealWidth: 330,
                                   maxWidth: .infinity,
                                   minHeight: 238,
                                   maxHeight: .infinity,
                                   alignment: SwiftUI.Alignment.top)
                            .popoverApperanceOperations(popoverIsShown: $isAnyNBActionPopoverShown)
                    } else {
                        FTShelfTagsRepresentableView(tags: shelfViewModel.tagsForThisBook, delegate: shelfViewModel.tagsControllerDelegate)
                            .frame(minWidth: 330,
                                   idealWidth: 330,
                                   maxWidth: .infinity,
                                   minHeight: 360,
                                   maxHeight: .infinity,
                                   alignment: SwiftUI.Alignment.top)
                            .popoverApperanceOperations(popoverIsShown: $isAnyNBActionPopoverShown)
                    }
                }
    }
    
    private var thumbnailSize: CGSize {
        let notebookWidth = shelfItemWidth - totalHorizontalPadding
        return CGSize(width: notebookWidth, height: (shelfItemHeight - titleRectHeight))
    }
    private var shelfItemSize: CGSize {
        CGSize(width: shelfItemWidth, height: shelfItemHeight)
    }
    private var groupCoverProperties: FTShelfItemCoverViewProperties {
        if horizontalSizeClass == .regular {
            return .large
        } else {
            return .medium
        }
    }
    private var titleRectHeight: CGFloat {
        FTShelfItemProperties.Constants.Notebook.titleRectHeight
    }
    private var totalHorizontalPadding: CGFloat {
        FTShelfItemProperties.Constants.Notebook.totalHorizontalPadding
    }
    
    private var NotebookDropRect: CGRect {
        var dropRect: CGRect = .zero
        if shelfItemWidth > 0 && shelfItemHeight > 0 {
            dropRect = CGRect(
                x: 0
                , y: 0
                , width: shelfItemWidth
                , height: (shelfItemHeight - ((shelfViewModel.displayStlye == .List) ? 0.0 : titleRectHeight))
            )//.insetBy(dx: 15, dy: 15)
        }
        return dropRect
    }
    
    private var groupDropRect: CGRect {
        CGRect(
            x: 0
            , y: 0
            , width: shelfItemWidth
            , height: shelfItemHeight - ((shelfViewModel.displayStlye == .List) ? 0.0 : titleRectHeight)
        )
    }
    private var landscapeCoverHeightPercnt: CGFloat {
        FTShelfItemProperties.Constants.Notebook.landscapeCoverHeightPercnt
    }
    private var landCoverCornerRadius: CGFloat {
        FTShelfItemProperties.Constants.Notebook.landCoverCornerRadius
    }
    private var shelfItemLocation: String {
        var location: String = shelfItem.model.URL.displayRelativePathWRTCollection().deletingLastPathComponent
        if shelfItem.model.shelfCollection.isUnfiledNotesShelfItemCollection {
            location = location.replacingOccurrences(of: uncategorizedShefItemCollectionTitle, with: "sidebar.topSection.unfiled".localized)
        }
        return location
    }
}
