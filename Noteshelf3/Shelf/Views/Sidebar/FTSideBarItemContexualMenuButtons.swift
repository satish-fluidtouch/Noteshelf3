//
//  FTSideBarItemContexualMenu.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 26/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

struct FTSideBarItemContexualMenuButtons: View {
    @Binding var showTrashAlert: Bool
    @EnvironmentObject var item: FTSideBarItem
    @Binding var alertInfo: TrashAlertInfo?

    @EnvironmentObject var viewModel: FTSidebarItemContextualMenuVM
    @EnvironmentObject var sidebarViewModel: FTSidebarViewModel

    var longPressOptions: [FTSidebarItemContextualOption] = []
    var body: some View {
            ForEach(longPressOptions,id: \.self) { menuOption in
                Button(role: menuOption.isDestructiveOption ? .destructive : nil) {
                    sidebarViewModel.trackEventForLongPressOptions(item: item, option: menuOption)
                    if menuOption == .trashCategory || menuOption == .emptyTrash || menuOption == .deleteTag {
                        showTrashAlert = true
                        setAlertInfoForOption(menuOption)
                    } else {
                        viewModel.sideBarItem = item
                        viewModel.performAction = menuOption
                    }
                } label: {
                    Label {
                        Text(menuOption.displayTitle)
                            .fontWeight(.regular)
                            .appFont(for: .regular, with: 15)
                            .foregroundColor(Color(menuOption.foreGroundColor))
                    } icon: {
                        Image(icon: menuOption.icon)
                            .frame(width: 16, height: 24, alignment: SwiftUI.Alignment.center)
                            .foregroundColor(Color(menuOption.foreGroundColor))
                            .font(Font.appFont(for: .regular, with: 15))
                    }
                }
            }
    }
    private func setAlertInfoForOption(_ option: FTSidebarItemContextualOption) {
        if option == .emptyTrash {
            alertInfo = TrashAlertInfo(title: NSLocalizedString("trash.alert.title", comment: "Are you sure you want empty your Trash?"),
                                       message: "",
                                       type: TrashAlertInfo.TrashType.emptyTrash(item: item))
        } else if option == .trashCategory {
            let title = String(format: "shelf.deleteCategoryAlert.title".localized, "\"\(item.title)\"")
            let message = NSLocalizedString("shelf.deleteCategoryAlert.message", comment: "The items in this category will be placed in the Trash.")
            alertInfo = TrashAlertInfo(title: title, message: message, type: TrashAlertInfo.TrashType.category(item: item))
        } else if option == .deleteTag {
            let title = String(format: "tags.delete.alert.title".localized, "\"\(item.title)\"")
            let message = "tags.delete.alert.message".localized
            alertInfo = TrashAlertInfo(title: title,
                                       message: message,
                                       type: TrashAlertInfo.TrashType.tags(item: item))
        }
    }
}
