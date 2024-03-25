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
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    // Templates New Option
    @AppStorage("isTemplatesNewOptionShown") private var isTemplatesNewOptionShown = false
    
    var body: some View {
        Grid(horizontalSpacing: 8,verticalSpacing: 8 ) {
            if isLargerTextEnabled(for: dynamicTypeSize) {
                GridRow {
                    gridItemFor(sidebarItemForType(.home))
                }
                GridRow {
                    gridItemFor(sidebarItemForType(.starred))
                }
                GridRow {
                    gridItemFor(sidebarItemForType(.unCategorized))
                }
                GridRow {
                    gridItemFor(sidebarItemForType(.trash))
                }
                GridRow{
                    templateGridItem(sidebarItemForType(.templates))
                }
            } else {
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
            isTemplatesNewOptionShown = true
        } label: {
            FTTemplatesSidebarItemView(viewModel: viewModel,delegate:delegate)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .littleslow))
        .accessibilityLabel(accesibilityLabel(item: sideBarItem))
    }
    
    private func gridItemFor(_ sideBarItem: FTSideBarItem) -> some View {
        Button {
            viewModel.endEditingActions()
            viewModel.selectedSideBarItem = sideBarItem
            delegate?.didTapOnSidebarItem(sideBarItem)
        } label: {
            FTSidebarTopSectionGridItemView(viewModel: viewModel,
                                            numberOfChildren: sideBarItem.shelfCollection?.childrens.count ?? 0)
            .environmentObject(sideBarItem)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .littleslow))
        .accessibilityLabel(accesibilityLabel(item: sideBarItem))
        .accessibilityHint(sideBarItem.type.accesibilityHint)
    }
    
    func accesibilityLabel(item: FTSideBarItem) -> String {
        var title = item.type.displayTitle
        if item.type == .templates && !isTemplatesNewOptionShown {
            title += "New Templates added"
        } else if item == viewModel.selectedSideBarItem {
            title = "Selected \(title) \(item.shelfCollection?.childrens.count ?? 0) notebooks"
        }
        return title
    }
}

struct FTSidebarTopSectionGridView_Previews: PreviewProvider {
    static var previews: some View {
        FTSidebarTopSectionGridView(viewModel: FTSidebarViewModel(collection: nil))
    }
}
