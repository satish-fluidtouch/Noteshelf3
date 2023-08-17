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

    weak var delegate: FTSidebarViewDelegate?
    var body: some View {
        FTSideBarItemContextMenuPreview(preview: {
            Button {
                viewModel.endEditingActions()
                viewModel.selectedSideBarItem = templatesSidebarItem
                delegate?.didTapOnSidebarItem(templatesSidebarItem)
            } label: {
                templatesView
            }
            .ignoresSafeArea()
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true
        }, onDisappearActon: {
            shelfMenuOverlayInfo.isMenuShown = false
        }, cornerRadius: 16,alertInfo: .constant(nil), showTrashAlert: .constant(false),sidebarItem:templatesSidebarItem,contextualMenuViewModel: viewModel.sidebarItemContexualMenuVM)
        .frame(height: 71)
        .environmentObject(viewModel)
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
        HStack(alignment:.center, spacing:0) {
                ZStack(alignment: .bottomLeading) {
                    Image("templatePaperIcon")   
                }.padding(.top,1)
                VStack(alignment: .leading,spacing: 0) {
                    Text("Templates")
                        .frame(height:22, alignment: .top)
                        .font(.clearFaceFont(for: .medium, with: 18))
                        .foregroundColor(getTintColorForTopSectionItem())
                        .padding(.top,3)
                    Text("shelf.sidebar.templates.subtitle")
                        .frame(height:16,alignment: .top)
                        .font(Font.appFont(for: .regular, with: 13))
                        .foregroundColor(getTintColorForTopSectionItem().opacity(0.8))
                }
        }
        .frame(maxWidth: .infinity,maxHeight: 71, alignment: .leading)
        .background(getBGColorTemplateItem())
        .cornerRadius(16)
        .if(templatesSidebarItem.type == viewModel.selectedSideBarItem?.type) { view in
            view.shadow(color: templatesSidebarItem.type.shadowColor, radius: 12,x: 0,y:8)
        }
        .contentShape([.contextMenuPreview],RoundedRectangle(cornerRadius: 16))
    }
}
struct FTTemplatesSidebarItemView_Previews: PreviewProvider {
    static var previews: some View {
        FTTemplatesSidebarItemView(viewModel: FTSidebarViewModel(collection: nil))
    }
}
