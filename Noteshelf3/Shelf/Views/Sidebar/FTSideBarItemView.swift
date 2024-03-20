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
    @State var itemBgColor: Color = .clear
    @State var itemTitleTint: Color = .clear
    @State var numberOfChildren: Int = 0
    @State var showChildrenNumber: Bool
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var viewWidth: CGFloat
    var body: some View {
        Button {
            if self.viewModel.selectedSideBarItem == item, item.isEditing {
                return
            }
            self.viewModel.endEditingActions()
            self.viewModel.currentDraggedSidebarItem = nil
            self.viewModel.selectedSideBarItem = item
            self.viewModel.delegate?.didTapOnSidebarItem(item)
        } label: {
            VStack(spacing:0) {
                sideBarItem
            }
            .frame(minHeight: 44)
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
                    .frame(maxWidth: 36, maxHeight: 36, alignment: SwiftUI.Alignment.center)
                    .padding(.leading,8)
                    .padding(.trailing, 4)
                    .font(Font.appFixedFont(for: .regular, with: isLargerTextEnabled(for: dynamicTypeSize) ? 26 : 20))
            }
            Spacer()
                Text("\(numberOfChildren)")
                    .fontWeight(.medium)
                    .appFont(for: .regular, with: 15)
                    .padding(.trailing,12)
                    .padding(.leading,8)
                    .isHidden(!showChildrenNumber)
        }
        .frame(minHeight: 44.0, alignment: .leading)
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
                    SideBarItemView(itemBgColor:viewModel.getRowSelectionColorFor(item: item),
                                    itemTitleTint:viewModel.getRowForegroundColorFor(item: item),
                                    numberOfChildren: (item.shelfCollection?.childrens.count ?? 0),
                                    showChildrenNumber: ((item.shelfCollection?.childrens.count ?? 0) > 0 && viewModel.selectedSideBarItem?.id == item.id),
                                    viewWidth: 0.0)
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
            .onChange(of: viewModel.selectedSideBarItem, perform: { newValue in
                updateItemBGAndTintColor()
                updateShowChildrenNumberStatus()
            })
            .onChange(of: viewModel.highlightItem, perform: { newValue in
                updateItemBGAndTintColor()
            })
            .onChange(of:viewModel.fadeDraggedSidebarItem, perform: { newValue in
                if newValue == item || newValue == nil {
                    updateItemBGAndTintColor()
                }
            })
            .background(RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            ).fill(itemBgColor))
            .foregroundColor(itemTitleTint)
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(rawValue:shelfCollectionItemsCountNotification)), perform: { notification in
            if let userInfo = notification.userInfo {
                if let collectionName = userInfo["shelfCollectionTitle"] as? String, collectionName == item.shelfCollection?.displayTitle, let count = userInfo["shelfItemsCount"] as? Int {
                        numberOfChildren = count
                    showChildrenNumber = (numberOfChildren > 0 && viewModel.selectedSideBarItem?.id == item.id)
                }
            }
        })
    }
    private func updateItemBGAndTintColor() {
        itemBgColor = viewModel.getRowSelectionColorFor(item: item);
        itemTitleTint = viewModel.getRowForegroundColorFor(item: item)
    }
    private func updateShowChildrenNumberStatus(){
        numberOfChildren  = item.shelfCollection?.childrens.count ?? 0
        showChildrenNumber = (numberOfChildren > 0 && viewModel.selectedSideBarItem?.id == item.id)
    }
}
