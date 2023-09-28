//
//  FTSidebarTopSectionGridView.swift
//  NewShelfSidebar
//
//  Created by Ramakrishna on 13/04/23.
//

import SwiftUI
import FTCommon

struct FTSidebarTopSectionGridView: View {

    weak var delegate: FTSidebarViewDelegate?

    @ObservedObject var viewModel: FTSidebarViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Grid(horizontalSpacing: 8,verticalSpacing: 8 ) {
            GridRow {
                gridItemFor(sidebarItemForType(.home))
                gridItemFor(sidebarItemForType(.starred))
            }
            GridRow {
                gridItemFor(sidebarItemForType(.unCategorized))
                gridItemFor(sidebarItemForType(.trash))
            }
            GridRow{
                templateGridItem(sidebarItemForType(.templates))
                    .gridCellColumns(2)
            }
        }.macOnlyPlainButtonStyle()
    }
    private func sidebarItemForType(_ type: FTSideBarItemType) -> FTSideBarItem{
        viewModel.sidebarItemOfType(type)
    }
    private func templateGridItem(_ sideBarItem: FTSideBarItem) -> some View {
        Button {
            viewModel.endEditingActions()
            viewModel.selectedSideBarItem = sideBarItem
            delegate?.didTapOnSidebarItem(sideBarItem)
        } label: {
            FTTemplatesSidebarItemView(viewModel: viewModel,delegate:delegate)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .littleslow))
    }

    private func gridItemFor(_ sideBarItem: FTSideBarItem) -> some View {
        Button {
            viewModel.endEditingActions()
            viewModel.selectedSideBarItem = sideBarItem
            delegate?.didTapOnSidebarItem(sideBarItem)
        } label: {
            FTSidebarTopSectionGridItemView(viewModel: viewModel)
                .environmentObject(sideBarItem)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .littleslow))
    }
}

struct FTSidebarTopSectionGridView_Previews: PreviewProvider {
    static var previews: some View {
        FTSidebarTopSectionGridView(viewModel: FTSidebarViewModel(collection: nil))
    }
}
