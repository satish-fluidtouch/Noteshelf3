//
//  FTGroupItemView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 12/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
import FTStyles
import SwiftUI

struct FTGroupItemView: View {

    @EnvironmentObject var groupItem: FTGroupItemViewModel
    @EnvironmentObject var shelfViewModel: FTShelfViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var isPressed: Bool = false

    var groupItemWidth: CGFloat = 212
    var groupItemHeight: CGFloat = 334

    var body: some View {
        //let _ = Self._printChanges()
        VStack(alignment: .center,spacing: 12) {
            FTShelfItemContextMenuPreview(preview: {
                coverView
                    .ignoresSafeArea()
            }, notebookShape: {
                return FTPreviewShape(raidus: 10)
            }, onAppearActon: {
                shelfMenuOverlayInfo.isMenuShown = true;
                // Track event
                track(EventName.shelf_group_longpress, params: [EventParameterKey.location: shelfViewModel.shelfLocation()], screenName: ScreenName.shelf)
            }, onDisappearActon: {
                shelfMenuOverlayInfo.isMenuShown = false;
            },shelfItem: groupItem)
            .frame(width: groupItemWidth-24)
            titleView
        }
    }

    @ViewBuilder private var coverView: some View {
        FTGroupCoverViewNew(groupModel: groupItem.model as? FTGroupItemProtocol,
                            groupCoverViewModel: groupCoverViewModel,
                            groupWidth: groupItemWidth > 0 ? groupItemWidth : 0,
                            groupHeight: groupItemHeight > 0 ? (groupItemHeight - titleRectHeight) : 0)
        .environmentObject(groupItem)
        .overlay(alignment: .bottom) {
            if shelfViewModel.mode == .selection, shelfViewModel.displayStlye != .List {
                FTShelfItemSelectionIndicator()
                    .padding(.bottom, 4)
            }
        }
        .onTapGesture(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                shelfViewModel.didTapGroupItem(groupItem)
            }
        })
        .onLongPressGesture(perform: {

        }, onPressingChanged: { _ in
            withAnimation {
                isPressed.toggle()
            }
        })
        .scaleEffect(isPressed ? 0.8 : 1.0)
        .animation(Animation.easeInOut(duration: 0.3), value: isPressed)
    }

    @ViewBuilder private var titleView: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(alignment: .center) {
                Text(groupItem.title)
                    .appFont(for: .medium, with: 16)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: false)
                    .lineLimit(2)
                    .padding(.top,2)
            }
            HStack(alignment: .center) {
                Text(groupItem.noOfNotes)
                    .fontWeight(.regular)
                    .appFont(for: .regular, with: 13)
                    .foregroundColor(Color.appColor(.groupNotesCountTint))
            }
        }
        .padding(.horizontal,12)
        .frame(width: groupTitleViewSize.width, height: groupTitleViewSize.height,alignment: .top)
        .onTapGesture {
            shelfViewModel.renameShelfItem(groupItem)
        }
    }
    
    private var coverProperties : FTShelfItemCoverViewProperties {
        if horizontalSizeClass == .regular {
            return .large
        }else {
            return .medium
        }
    }
    private var groupTitleViewSize: CGSize {
        CGSize(width: groupItemWidth, height: 60)
    }
    private var titleRectHeight: CGFloat {
       FTShelfItemProperties.Constants.Notebook.titleRectHeight
    }
    private var groupCoverViewModel: FTGroupCoverViewModel {
        groupItem.groupCoverViewModel.groupItem = (groupItem.model as? FTGroupItemProtocol) as? FTGroupItem
        return groupItem.groupCoverViewModel
    }
}
