//
//  FTTemplatesSidebarItemView.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import SwiftUI

struct FTTemplatesSidebarItemView: View {
    @ObservedObject var viewModel: FTSidebarViewModel
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isTemplatesNewOptionShown") private var isNewOptionShown = false

    weak var delegate: FTSidebarViewDelegate?
    var body: some View {
        FTSideBarItemContextMenuPreview(preview: {
            templatesView
            .ignoresSafeArea()
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true
            viewModel.trackEventForlongpress(item: templatesSidebarItem)
        }, onDisappearActon: {
            shelfMenuOverlayInfo.isMenuShown = false
        }, cornerRadius: 16,alertInfo: .constant(nil), showTrashAlert: .constant(false))
        .frame(height: 80)
        .environmentObject(viewModel)
        .environmentObject(templatesSidebarItem)
        .environmentObject(viewModel.sidebarItemContexualMenuVM)
    }
    private func getBGColorTemplateItem() -> Color {
        let templatesSidebarItem = templatesSidebarItem
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == templatesSidebarItem.type {
            return Color.appColor(.templatesSelectedBG)
        }
        return Color.appColor(.templatesBG)
    }
    private func getTintColorForTopSectionItem() -> Color {
        let templatesSidebarItem = templatesSidebarItem
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == templatesSidebarItem.type {
            return Color.white
        }
        return Color.appColor(.accent)
    }
    private var templatesSidebarItem: FTSideBarItem {
        viewModel.sidebarItemOfType(.templates)
    }
    private var templatesView: some View {
        VStack(alignment: .leading,spacing:10) {
            HStack(alignment: .top, content: {
                Image(icon: .templates)
                    .foregroundColor(iconTintColor)
                    .font(.appFont(for: .regular, with: 22))
                Spacer()
                // once the user taps on templates do not show this
                NewBadgeView()
                    .background(iconTintColor.opacity(0.60))
                    .cornerRadius(4)
                    .isHidden(isNewOptionShown)
            })
            .padding(.top,14)
            .padding(.horizontal,12)
            HStack(alignment: .top, content: {
                Text("Templates")
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .font(titleFont)
                    .foregroundColor(titleTint)
            })
            .padding(.horizontal,12)
            .padding(.bottom,10)
        }
        .frame(maxWidth: .infinity,maxHeight: 80)
        .background(getBGColorTemplateItem())
        .cornerRadius(16)
        .if(templatesSidebarItem.type == viewModel.selectedSideBarItem?.type) { view in
            view.shadow(color: templatesSidebarItem.type.shadowColor, radius: 12,x: 0,y:8)
        }
        .contentShape([.contextMenuPreview],RoundedRectangle(cornerRadius: 16))
    }
    private var titleFont: Font {
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == templatesSidebarItem.type {
            return Font.appFont(for: .medium, with: 17)
        }
        return Font.appFont(for: .regular, with: 17)
    }
    private var iconTintColor: Color {
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == templatesSidebarItem.type {
            return Color.appColor(.templatesIconSelectedTint)
        }
        return Color.appColor(.templatesIconTint)
    }
    private var titleTint: Color {
        var color = Color.white
        if let selectedSideBarItem = viewModel.selectedSideBarItem,selectedSideBarItem.type == templatesSidebarItem.type {
            color = Color.white
        } else {
            color = (colorScheme == .dark) ? .white : .black
        }
        return color
    }
}
struct FTTemplatesSidebarItemView_Previews: PreviewProvider {
    static var previews: some View {
        FTTemplatesSidebarItemView(viewModel: FTSidebarViewModel(collection: nil))
    }
}

private struct NewBadgeView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("New")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .frame(height: 20, alignment: .center)
    }
}
