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
import FTCommon

struct SideBarItemView : View {
    @EnvironmentObject var shelfMenuOverlayInfo: FTShelfMenuOverlayInfo
    @EnvironmentObject var viewModel: FTSidebarViewModel
    @EnvironmentObject var section: FTSidebarSection
    @EnvironmentObject var item: FTSideBarItem
    // alerts
    @State private var showTrashAlert: Bool = false
    @State private var alertInfo: TrashAlertInfo?

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var viewWidth: CGFloat
    var body: some View {
        Button {
            self.viewModel.endEditingActions()
            self.viewModel.currentDraggedSidebarItem = nil
            self.viewModel.selectedSideBarItem = item
            self.viewModel.delegate?.didTapOnSidebarItem(item)
        } label: {
            VStack(spacing:0) {
                sideBarItem
            }
            .frame(height: 44)
        }
        .buttonStyle(FTMicroInteractionButtonStyle(scaleValue: .littleslow))
    }
    @ViewBuilder
    private var sideBarItem: some View {
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
                    SideBarItemView(viewWidth: 0.0)
                        .environmentObject(viewModel)
                        .environmentObject(item)
                        .environmentObject(section)
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
            .background(RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            ).fill(viewModel.getRowSelectionColorFor(item: item)))
            .foregroundColor(viewModel.getRowForegroundColorFor(item: item))
            .if(item.isEditable, transform: { view in
                view.contextMenu(menuItems: {
                    FTSideBarItemContexualMenuButtons(showTrashAlert: $showTrashAlert,
                                                      alertInfo: $alertInfo,
                                                      longPressOptions: viewModel.getContextualOptionsForSideBarType(item.type))
                    .environmentObject(item)
                    .environmentObject(viewModel.sidebarItemContexualMenuVM)
                },preview: {
                    view
                    .frame(width: viewWidth)
                    .onAppear {
                        viewModel.trackEventForlongpress(item: item)
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
}
