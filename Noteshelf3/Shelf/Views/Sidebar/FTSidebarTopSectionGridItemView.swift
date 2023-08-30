//
//  FTSidebarTopSectionGridView.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import SwiftUI

struct FTSidebarTopSectionGridItemView: View {

    @ObservedObject var viewModel: FTSidebarViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @Environment(\.colorScheme) var colorScheme
    @State private var showTrashAlert: Bool = false
    @State private var alertInfo: TrashAlertInfo?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var item: FTSideBarItem

    var body: some View {
        FTSideBarItemContextMenuPreview(preview: {
            gridItemView
                .ignoresSafeArea()
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true
            let eventName = viewModel.eventNameForlongpress(item: item)
            track(eventName, screenName: ScreenName.sidebar)
        }, onDisappearActon: {
            shelfMenuOverlayInfo.isMenuShown = false
        }, cornerRadius: 16,alertInfo: $alertInfo, showTrashAlert: $showTrashAlert,sidebarItem:item,contextualMenuViewModel: viewModel.sidebarItemContexualMenuVM)
        .frame(height: 80)
        .environmentObject(viewModel)
    }
    private var gridItemView: some View {
        VStack(alignment: .leading,spacing:10) {
            HStack(alignment: .top, content: {
                icon
                    .frame(width: 24,height: 24,alignment: .top)
                    .foregroundColor(getIconTintColorForTopSectionItem(item))
                    .font(.appFont(for: .regular, with: 20))
                Spacer()
                if (canShowNoOfBooksForItem(item) && item.numberOfChildren > 0) {
                    Text("\(item.numberOfChildren)")
                        .foregroundColor(.white)
                }else {
                    EmptyView()
                }
            })
            .padding(.top,14)
            .padding(.horizontal,12)
            HStack(alignment: .top, content: {
                Text(item.type.displayTitle)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .font(titleFontForItem(item))
                    .foregroundColor(titleColorForTopSectionItem(item))
            })
            .padding(.horizontal,12)
            .padding(.bottom,10)
        }
        .frame(maxWidth: .infinity,maxHeight: 80)
        .background(getBGColorTopSectionItem(item))
        .cornerRadius(16)
        .if(item == viewModel.selectedSideBarItem, transform: { view in
            view.shadow(color:item.type.shadowColor, radius: 12,x: 0,y:8)
        })
        .onDrop(of: [.data],
                    delegate: SideBarItemDropDelegate(viewModel: viewModel,
                                                      droppedItem: item))
        .contentShape([.contextMenuPreview],RoundedRectangle(cornerRadius: 16))
        .alert(alertInfo?.title ?? "", isPresented: $showTrashAlert, presenting: alertInfo) { _ in
            let title = NSLocalizedString("shelf.emptyTrash", comment: "Empty Trash")
            Button(title, role: .destructive) {
                viewModel.emptyTrash(item)
            }
        } message: { info in
            Text(info.message)
        }
    }
    @ViewBuilder
    private var icon: some View {
        if item.type != .home {
            Image(systemName: item.type.iconName)
        } else {
            Image(item.type.iconName)
        }
    }
    private func getBGColorTopSectionItem(_ item: FTSideBarItem) -> Color {
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == item.type {
            return item.type.activeBGColor
        }
        return item.type.bgColor
    }
    
    private func titleColorForTopSectionItem(_ item: FTSideBarItem) -> Color {
        var color = Color.white
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == item.type {
            color = Color.white
        } else {
            color = (colorScheme == .dark) ? .white : .black
        }
        return color
    }
    
    private func getIconTintColorForTopSectionItem(_ item: FTSideBarItem) -> Color {
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == item.type {
            return Color.white
        }
        return item.type.iconTint
    }
    private func canShowNoOfBooksForItem(_ item: FTSideBarItem) -> Bool{
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == item.type {
            return true
        }
        return false
    }
    private func titleFontForItem(_ item: FTSideBarItem) -> Font {
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == item.type {
            return Font.appFont(for: .medium, with: 17)
        }
        return Font.appFont(for: .regular, with: 17)
    }
}
struct FTSidebarTopSectionGridItemView_Previews: PreviewProvider {
    static var previews: some View {
        FTSidebarTopSectionGridItemView(viewModel: FTSidebarViewModel(collection: nil), item: FTSideBarItem())
    }
}
