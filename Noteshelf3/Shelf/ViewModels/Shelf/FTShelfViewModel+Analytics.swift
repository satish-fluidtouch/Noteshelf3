//
//  FTShelfViewModel+Analytics.swift
//  Noteshelf3
//
//  Created by Siva on 25/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

extension FTShelfViewModel {
    func shelfLocation() -> String {
        return self.isInHomeMode ? "Home" : self.collection.displayTitle
    }

    func trackEventForContexualOption(option: FTShelfItemContexualOption, item: FTShelfItemViewModel) {
        let eventMapping: [FTShelfItemContexualOption: String] = [
            .showEnclosingFolder: EventName.shelf_book_showenclosingfolder_tap,
            .openInNewWindow: item.type == .notebook ? EventName.shelf_book_openinnewindow_tap : EventName.shelf_group_openinewwindow_tap,
            .rename: item.type == .notebook ? EventName.shelf_book_rename_tap : EventName.shelf_group_rename_tap,
            .changeCover: EventName.shelf_book_changecover_tap,
            .tags: EventName.shelf_book_tags_tap,
            .duplicate: item.type == .notebook ? EventName.shelf_book_duplicate_tap : EventName.shelf_group_duplicate_tap,
            .move: item.type == .notebook ? EventName.shelf_book_move_tap : EventName.shelf_group_move_tap,
            .addToStarred: EventName.shelf_book_addtostarred_tap,
            .removeFromStarred: EventName.shelf_book_removefromstarred_tap,
            .getInfo: EventName.shelf_book_getinfo_tap,
            .share: item.type == .notebook ? EventName.shelf_book_share_tap : EventName.shelf_group_share_tap,
            .trash: item.type == .notebook ? EventName.shelf_book_trash_tap : EventName.shelf_group_trash_tap,
            .restore: EventName.shelf_book_restore_tap,
            .delete: EventName.shelf_book_delete_tap
        ]
        if let event = eventMapping[option] {
            track(event, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }

    func trackEventForAddMenuoption(option: FTNewNotePopoverOptions) {
        let eventMapping: [FTNewNotePopoverOptions: String] = [
            .quickNote: EventName.shelf_addmenu_quicknote_tap,
            .newNotebook: EventName.shelf_addmenu_newnotebook_tap,
            .importFromFiles: EventName.shelf_addmenu_importfile_tap,
            .photoLibrary: EventName.shelf_addmenu_phototemplate_tap,
            .audioNote: EventName.shelf_addmenu_audionote_tap,
            .scanDocument: EventName.shelf_addmenu_scandoc_tap,
            .takePhoto: EventName.shelf_addmenu_takephoto_tap
        ]
        if let event = eventMapping[option] {
            track(event, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }

    func trackEventForSortOrder(sortOrder: FTShelfSortOrder) {
        let eventMapping: [FTShelfSortOrder: String] = [
            .byModifiedDate: EventName.shelf_more_lastmodified_tap,
            .byLastOpenedDate: EventName.shelf_more_lastopened_tap,
            .byName: EventName.shelf_more_name_tap,
            .manual: EventName.shelf_more_custom_tap
        ]
        if let event = eventMapping[sortOrder] {
            track(event, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }

    func trackEventForSupportedStyles(style: FTShelfDisplayStyle) {
        let eventMapping: [FTShelfDisplayStyle: String] = [
            .Gallery: EventName.shelf_more_largebook_tap,
            .List: EventName.shelf_more_list_tap,
            .Icon: EventName.shelf_more_smallbook_tap
        ]
        if let event = eventMapping[style] {
            track(event, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }

    func trackEventForShelfBottombar(option: FTShelfBottomBarOption) {
        let eventMapping: [FTShelfBottomBarOption: String] = [
            .share: EventName.shelf_select_share_tap,
            .move: EventName.shelf_select_move_tap,
            .delete: EventName.shelf_select_delete_tap,
            .createGroup: EventName.shelf_select_creategroup_tap,
            .changeCover: EventName.shelf_select_changecover_tap,
            .duplicate: EventName.shelf_select_duplicate_tap,
            .rename: EventName.shelf_select_rename_tap,
            .restore: EventName.shelf_select_restore_tap,
            .tags: EventName.shelf_select_tags_tap,
            .trash: EventName.shelf_select_trash_tap,
        ]
        if let event = eventMapping[option] {
            track(event, params: [EventParameterKey.location: shelfLocation()], screenName: ScreenName.shelf)
        }
    }




}
