//
//  FTGroupViewList.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 19/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI


struct FTGroupListView: View {

    var shelfItemWidth: CGFloat = 212
    var shelfItemHeight: CGFloat = 80
    private let listGridViewHorizontalPadding: CGFloat = 12

    @EnvironmentObject var groupItem: FTGroupItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    var body: some View {
        VStack {
            Spacer()
        FTShelfItemContextMenuPreview(preview: {
            contentView
                .padding(.horizontal, listGridViewHorizontalPadding)
                .overlay(content: {
                    if(shelfViewModel.highlightItem == groupItem) {
                        FTShelfItemDropOverlayView()
                            .cornerRadius(10, corners: .allCorners)
                    }
                })
                .ignoresSafeArea()
        }, notebookShape: {
            return FTNotebookShape(raidus: 10);
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true;
        }, onDisappearActon: {
            shelfMenuOverlayInfo.isMenuShown = false;
        }, shelfItem: groupItem)
            Spacer()
            Divider()
                .frame(height: 1.0)
                .background(Color.appColor(.black10))
                .padding(.horizontal, listGridViewHorizontalPadding)
        }

    }
    
    @ViewBuilder
    private var contentView: some View {
            HStack(alignment: .center,spacing: 0) {
                if shelfViewModel.mode == .selection {
                    FTShelfItemSelectionIndicator(isSelected: $groupItem.isSelected)
                        .padding(.trailing,16)
                }
                HStack(alignment: .center,spacing: 16) {
                    FTGroupCoverViewNew(groupModel: groupItemProtocol,
                                        groupCoverViewModel: groupCoverViewModel,
                                        groupWidth: coverSize.width,
                                        groupHeight: coverSize.height,
                                        coverViewPurpose:.shelf)
                    .environmentObject(groupItem)
                    .frame(width: 52,height: shelfItemHeight,alignment: .center)
                    titleView
                }
                Image(icon: FTIcon.rightArrow)
                    .font(Font.appFont(for: .regular, with: 17))
                    .foregroundColor(Color.appColor(.accent))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24,alignment: .center)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
    @ViewBuilder private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(groupItem.title)
                    .appFont(for: .medium, with: 16)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: false)
                    .lineLimit(2)
                Spacer()
            }
            HStack(alignment: .top) {
                Text(groupItem.noOfNotes)
                    .fontWeight(.regular)
                    .appFont(for: .regular, with: 13)
                    .foregroundColor(Color.appColor(.groupNotesCountTint))
                Spacer()
            }
        }
        .frame(height: 60)
    }
    private var coverSize: CGSize {
        let height = shelfItemHeight - 16;
        return CGSize(width: 52, height: height)
    }
    private var groupCoverViewModel: FTGroupCoverViewModel {
        groupItem.groupCoverViewModel.groupItem = (groupItem.model as? FTGroupItemProtocol) as? FTGroupItem
        return groupItem.groupCoverViewModel
    }
    private var groupItemProtocol: FTGroupItemProtocol? {
        (groupItem.model as? FTGroupItemProtocol)
    }
}
