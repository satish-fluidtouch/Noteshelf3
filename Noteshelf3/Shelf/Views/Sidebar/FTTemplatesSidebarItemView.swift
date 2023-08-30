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

    weak var delegate: FTSidebarViewDelegate?
    var body: some View {
        FTSideBarItemContextMenuPreview(preview: {
//            Button {
//                viewModel.endEditingActions()
//                viewModel.selectedSideBarItem = templatesSidebarItem
//                delegate?.didTapOnSidebarItem(templatesSidebarItem)
//            } label: {
//                templatesView
//            }
            FTAnimateButton {
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
        .frame(height: 80)
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
        VStack(alignment: .leading,spacing:10) {
            HStack(alignment: .top, content: {
                Image(icon: .templates)
                    .foregroundColor(iconTintColor)
                    .font(.appFont(for: .regular, with: 22))
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
    private var templatesView1: some View {
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
        .frame(maxWidth: .infinity,maxHeight: 80, alignment: .leading)

    }
}
struct FTTemplatesSidebarItemView_Previews: PreviewProvider {
    static var previews: some View {
        FTTemplatesSidebarItemView(viewModel: FTSidebarViewModel(collection: nil))
    }
}
