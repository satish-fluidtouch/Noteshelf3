//
//  FTSidebarView.swift
//  Noteshelf3
//
//  Created by Akshay on 05/05/22.
//

import FTStyles
import SwiftUI
import UIKit
import FTCommon

extension Notification.Name {
    static let didChangeUnfiledCategoryLocation = Notification.Name(rawValue: "didChangeUnfiledCategoryLocation");
}

struct TrashAlertInfo {
    enum TrashType {
        case category(item: FTSideBarItem)
        case tags(item: FTSideBarItem)
        case emptyTrash(item: FTSideBarItem)
    }

    let title: String
    let message: String
    let type: TrashType
}
protocol FTSidebarViewDelegate: AnyObject {
    func didTapOnUpgradeNow();
    func didTapOnSettings()
    func didTapOnSidebarItem(_ item: FTSideBarItem)
    func emptyTrash(_ collection: FTShelfItemCollection, showConfirmationAlert: Bool, onCompletion: @escaping ((Bool) -> Void))
}
struct FTSidebarView: View {

    @StateObject var viewModel : FTSidebarViewModel
    @EnvironmentObject var shelfMenuOverlayInfo : FTShelfMenuOverlayInfo
    @EnvironmentObject var premiumUser : FTPremiumUser

    @State private var searchText: String = ""
    @State private var showOverlay: Bool = false
    @State private var expanded: Set<String> = []
    @State private var orientation = UIDevice.current.orientation
    @State private var reloadView: Bool = false

    weak var delegate: FTSidebarViewDelegate?
    private let collectionAddedUpdatedNotification = NotificationCenter.default.publisher(for: FTCategoryItemsDidUpdateNotification)

    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some View {
        menuView
            .macOnlyPlainButtonStyle() // added this to avoid gesture issue in ipad due to plain button style for mac, can be removed once we get better fix
        .onDrop(of: [.text], delegate: SideBarDropDelegate(viewModel: viewModel))
        .onTapGesture {
            self.hideKeyboard() // if any textfield is in editing state we exit from that mode and perform action. eg.rename category.
        }
    }

    @ViewBuilder private var menuView: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVGrid(columns: gridItemLayout(),alignment: .leading, spacing: 2.0) {
                    ForEach(viewModel.menuItems.indices, id: \.self) { index in
                        let menuSection = viewModel.menuItems[index]
                        if menuSection.type == .all {
                            FTSidebarTopSectionView(viewModel: viewModel,delegate: viewModel.delegate)
                        }
                        else {
                            let sidebarItemWidth = self.sidebarItemSizeBasinfAvailableWidth(geometry.size.width)
                            self.getDisclousreGroupForSection(menuSection,availableWidth: sidebarItemWidth)
                                .padding(.trailing,12)
                                .padding(.leading,12)
                        }
                    }
                }
                .ignoresSafeArea()
                .padding(.bottom,premiumUser.isPremiumUser ? 0 : 142)
            }
            .overlay(alignment: .bottom, content: {
                if !premiumUser.isPremiumUser {
                    FTPremiumBanner()
                        .environmentObject(viewModel)
                        .frame(height:108)                    
                        .padding(.horizontal,12)
                }
            })
            
            .detectOrientation($orientation)
                .onFirstAppear(perform: {
                    self.viewModel.configureUIOnViewLoad()
                })
                .onReceive(collectionAddedUpdatedNotification, perform: { notification in
                    viewModel.updateUserCreatedCategories()
                })
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: "refreshSideMenu")), perform: { notification in
                    updateTagItems(notification: notification)
                })
                .onReceive(NotificationCenter.default.publisher(for: .didChangeUnfiledCategoryLocation), perform: { notification in
                    viewModel.updateUnfiledCategory()
                })
                .onChange(of: orientation) { newValue in
                    self.reloadView.toggle()
                }
        }
    }
    @ViewBuilder
    private func getEditableViewForSideBarItem(_ item: FTSideBarItem,
                                               withPlaceHolder placeHolder:String,
                                               editableField: Bool = false,
                                               onSubmit: @escaping (_ newTitle: String) -> Void) -> some View{
        HStack(spacing:0) {
            FTEditableView(placeHolder: placeHolder,
                           onButtonSubmit:  onSubmit ,
                           showEditableField: editableField,
                           newTitle: item.title)
            .environmentObject(item)
        }
        .frame(height: 44.0, alignment: .leading)
        .background(Color.clear)
        .padding(.leading,8)
        .contentShape(Rectangle())
    }
    private func gridItemLayout() -> [GridItem] {
        return [GridItem(GridItem.Size.flexible(minimum: viewModel.sideBarItemWidth, maximum: .infinity),spacing: 0.0 ,alignment:.leading)]
    }
    @ViewBuilder
    private func getDisclousreGroupForSection(_ menuSection: FTSidebarSection,availableWidth: CGFloat) -> some View {
        DisclosureGroup(
            isExpanded: Binding<Bool>(
                get: { self.viewModel.getSideBarStatusForSection(menuSection)},
                set: { isExpanding in
                    if isExpanding {
                        self.viewModel.updateSideBarSectionStatus( menuSection, status: true)
                        self.viewModel.trackEventForSections(section: menuSection, isExpand: true)
                    } else {
                        self.viewModel.updateSideBarSectionStatus( menuSection, status: false)
                        self.viewModel.trackEventForSections(section: menuSection, isExpand: false)
                    }
                }
            )
        ) {
            VStack(spacing:2.0){
                ForEach(menuSection.items, id:\.self) { item in
                    if item.isEditing {
                        getEditableViewForSideBarItem(item, withPlaceHolder:item.title,editableField: true) { newTitle in
                            item.isEditing = false
                            if !newTitle.isEmpty {
                                viewModel.renameSideBarItem(item, toNewTitle: newTitle)
                            }
                        }
                    } else {
                        SideBarItemView(viewWidth: availableWidth)
                            .environmentObject(viewModel)
                            .environmentObject(menuSection)
                            .environmentObject(item)
                        .if(menuSection.supportsRearrangeOfItems, transform: { view in
                            view.onDrag {
                                self.viewModel.currentDraggedSidebarItem = item
                                self.viewModel.activeReorderingSidebarSectionType = menuSection.type
                                return NSItemProvider(item: nil, typeIdentifier: item.shelfCollection?.uuid)
                            } preview: {
                                view
                                    .frame(width:availableWidth)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .contentShape(RoundedRectangle(cornerRadius: 10))
                            }
                        })
                    }
                }
                if menuSection.type == .categories {
                    getEditableViewForSideBarItem(viewModel.newItem,withPlaceHolder:"New Category") { newTitle in
                        if !newTitle.isEmpty {
                            viewModel.addNewCategoryWithTitle(newTitle)
                            viewModel.newItem.title = ""
                        }else {

                        }
                    }
                }
            }
        } label: {
            SidebarSectionHeader()
                .environmentObject(menuSection)
                .padding(.bottom, 8)
                .padding(.trailing,10)
                .padding(.leading,8)
        }
        .accentColor(.appColor(.black1))
        .padding(.top,24)
    }
    private func sidebarItemSizeBasinfAvailableWidth(_ width: CGFloat) -> CGFloat {
        return (width > 0) ? width - 24 : 0  // 24 is horizontal padding
    }

    private func updateTagItems(notification: Notification) {
        if let selectedSideBarItem = viewModel.selectedSideBarItem, selectedSideBarItem.type == .tag {
            if let info = notification.userInfo, let type = info["type"] as? String {
                let tagItems = viewModel.menuItems.filter {$0.type == .tags}
                if type == "rename", let tag = info["tag"] as? String, let renamedTag = info["renamedTag"] as? String {
                    let tagItem = tagItems.flatMap {$0.items}.first(where: {$0.title == tag})
                    tagItem?.title = renamedTag
                } else if type == "add", let tag = info["tag"] as? String {
                    let item = FTSideBarItem(title: tag, icon: .number, isEditable: true, isEditing: false, type: FTSideBarItemType.tag, allowsItemDropping: false)
                    tagItems.first?.items.append(item)
                } else if type == "delete", let tag = info["tag"] as? String {
                    tagItems.first?.items = tagItems.flatMap({$0.items.filter({$0.title != tag})})
                }

                viewModel.setSideBarItemSelection()
            } else {
                viewModel.updateTags()
            }
        } else {
            viewModel.updateTags()
        }
    }
}
struct SidebarSectionHeader: View {
    @EnvironmentObject var section: FTSidebarSection
    //TODO: Check
    var body: some View {
        HStack {
            if section.type == .ns2Categories {
                Image("ns2_migration_logo")
            }
            Text(section.title)
                .font(.clearFaceFont(for: .medium, with: 22))
                .fontWeight(.heavy)
                .foregroundColor(.appColor(.black1))
                .tracking(-0.41)
        }
    }
}
