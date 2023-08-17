//
//  FTSideBarItemView.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 26/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
import FTStyles
import SwiftUI
import MobileCoreServices

struct FTSideBarItemView: View {
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @ObservedObject var viewModel: FTSidebarViewModel
    @ObservedObject var section: FTSidebarSection
    @ObservedObject var item: FTSideBarItem
    // alerts
    @State private var showTrashAlert: Bool = false
    @State private var alertInfo: TrashAlertInfo?

    weak var delegate: FTSidebarViewDelegate?
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some View {
       // let _ = Self._printChanges()
        FTSideBarItemContextMenuPreview(preview: {
            SideBarItemView(viewModel: viewModel,
                            section: section,
                            item: item,
                            delegate:delegate)
        }, onAppearActon: {
            shelfMenuOverlayInfo.isMenuShown = true
        }, onDisappearActon: {
            shelfMenuOverlayInfo.isMenuShown = false
        }, cornerRadius: 10,alertInfo: $alertInfo, showTrashAlert: $showTrashAlert,sidebarItem:item,contextualMenuViewModel: viewModel.sidebarItemContexualMenuVM)
        .frame(height: 44)
        .environmentObject(viewModel)
        //.ignoresSafeArea()
    }
}

struct SideBarItemView : View {
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @ObservedObject var viewModel: FTSidebarViewModel
    @ObservedObject var section: FTSidebarSection
    @ObservedObject var item: FTSideBarItem
    // alerts
    @State private var showTrashAlert: Bool = false
    @State private var alertInfo: TrashAlertInfo?

    weak var delegate: FTSidebarViewDelegate?
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var viewWidth: CGFloat = 0.0
    var body: some View {
        VStack(spacing:0) {
            HStack(alignment: .center) {
                Label {
                    Text(item.title)
                        .font(.appFont(for: .regular, with: 17))
                } icon: {
                    Image(icon: item.icon)
                        .frame(width: 24, height: 24, alignment: SwiftUI.Alignment.center)
                        .padding(.leading,8)
                        .padding(.trailing, 4)
                        .font(Font.appFont(for: .regular, with: 20))
                }
                Spacer()
                if viewModel.shouldShowNumberOfNotebooksCountFor(item: item) && item.numberOfChildren > 0 {
                    Text("\(item.numberOfChildren)")
                        .fontWeight(.medium)
                        .appFont(for: .regular, with: 15)
                        .foregroundColor(viewModel.getRowForegroundColorFor(item: item))
                        .padding(.trailing,12)
                        .padding(.leading,8)
                }
            }
            .frame(height: 44.0, alignment: .leading)
            .contentShape(Rectangle())
            .onDrop(of: [.data],
                    delegate: SideBarItemDropDelegate(viewModel: viewModel,
                                                      droppedItem: item))
            
            .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 10))
            .if(section.supportsRearrangeOfItems, transform: { view in
                view.onDrag {
                    self.viewModel.currentDraggedSidebarItem = item
                    self.viewModel.activeReorderingSidebarSectionType = section.type
                    return NSItemProvider(item: nil, typeIdentifier: item.shelfCollection?.uuid)
                }
            preview: {
                    HStack {
                        SideBarItemView(viewModel: viewModel,
                                          section: section,
                                          item: item,
                                          delegate:delegate)
                        .frame(height: 44.0, alignment: .leading)
                        Spacer(minLength: 140)
                    }
                    .frame(maxWidth: .infinity,maxHeight: 44)
                    .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 10))
                }
            })
            .if(viewModel.fadeDraggedSidebarItem == item, transform: { view in
                withAnimation(.default) {
                    view.opacity(0.0)
                }
            })
                .if(viewModel.fadeDraggedSidebarItem == nil, transform: { view in
                    withAnimation(.default) {
                        view.opacity(1.0)
                    }
                })
                .onTapGesture {
                    self.viewModel.endEditingActions()
                    self.viewModel.currentDraggedSidebarItem = nil
                    self.viewModel.selectedSideBarItem = item
                    self.delegate?.didTapOnSidebarItem(item)
                }
                .background(RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                ).fill(viewModel.getRowSelectionColorFor(item: item)))
                .foregroundColor(viewModel.getRowForegroundColorFor(item: item))
                .if(item.isEditable, transform: { view in
                    view.contextMenu(menuItems: {
                        FTSideBarItemContexualMenuButtons(showTrashAlert: $showTrashAlert,
                                                          item: item,
                                                          alertInfo: $alertInfo,
                                                          viewModel: viewModel.sidebarItemContexualMenuVM,longPressOptions: viewModel.getContextualOptionsForSideBarType(item.type))
                    },preview: {
                        view
                        .frame(width: viewWidth)
                        .onAppear {
                            shelfMenuOverlayInfo.isMenuShown = true;
                        }
                        .onDisappear {
                            shelfMenuOverlayInfo.isMenuShown = false;
                        }
                    })
                })
            .alert(alertInfo?.title ?? "", isPresented: $showTrashAlert, presenting: alertInfo) { _ in
                let title = item.type == .trash ? NSLocalizedString("shelf.emptyTrash", comment: "Empty Trash") : NSLocalizedString("shelf.alerts.delete", comment: "Delete")
                Button(title, role: .destructive) {
                    if item.type == .trash {
                        viewModel.emptyTrash(item)
                    } else {
                        viewModel.deleteSideBarItem(item)
                    }
                }
            } message: { info in
                Text(info.message)
            }
        }
        .frame(height: 44)
    }
}
