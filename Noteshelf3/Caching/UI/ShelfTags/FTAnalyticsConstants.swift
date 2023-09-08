//
//  FTShelfTagsAnalytics.swift
//  Noteshelf3
//
//  Created by Siva on 23/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension ScreenName {
    static let sidebar =  "sidebar"
    static let shelf = "shelf"
    static let shelf_tags = "shelf_tags"
    static let shelf_bookmarks = "shelf_bookmarks"
    static let shelf_photos = "shelf_photos"
    static let shelf_recordings = "shelf_recordings"
}

extension EventName {
    //Sidebar
    static let sidebar_premium_tap = "sidebar_premium_tap"
    static let sidebar_hamburger_tp = "sidebar_hamburger_tp"
    static let sidebar_home_tap =  "sidebar_home_tap"
    static let sidebar_starred_tap = "sidebar_starred_tap"
    static let sidebar_unflied_tap = "sidebar_unflied_tap"
    static let sidebar_trash_tap = "sidebar_trash_tap"
    static let sidebar_templates_tap = "sidebar_templates_tap"
    static let sidebar_category_tap = "sidebar_category_tap"
    static let sidebar_categories_expand = "sidebar_categories_expand"
    static let sidebar_categories_collapse = "sidebar_categories_collapse"
    static let sidebar_addnewcategory_tap = "sidebar_addnewcategory_tap"
    static let sidebar_photo_tap = "sidebar_photo_tap"
    static let sidebar_recording_tap = "sidebar_recording_tap"
    static let sidebar_bookmark_tap = "sidebar_bookmark_tap"
    static let sidebar_alltags_tap = "sidebar_alltags_tap"
    static let sidebar_tag_tap = "sidebar_tag_tap"
    static let sidebar_tags_expand = "sidebar_tags_expand"
    static let sidebar_tags_collapse = "sidebar_tags_collapse"
    static let sidebar_content_expand = "sidebar_content_expand"
    static let sidebar_content_collapse = "sidebar_content_collapse"

    // Sidebar LongPress
    static let sidebar_home_longpress = "sidebar_home_longpress"
    static let sidebar_starred_longpress = "sidebar_starred_longpress"
    static let sidebar_unfiled_longpress = "sidebar_unfiled_longpress"
    static let sidebar_trash_longpress = "sidebar_trash_longpress"
    static let sidebar_category_longpress = "sidebar_category_longpress"
    static let sidebar_photo_longpress = "sidebar_photo_longpress"
    static let sidebar_recording_longpress = "sidebar_recording_longpress"
    static let sidebar_bookmark_longpress = "sidebar_bookmark_longpress"
    static let sidebar_tag_longpress = "sidebar_tag_longpress"
    static let sidebar_templates_longpress = "sidebar_templates_longpress"
    
    // Sidebar Longpress Actions
    static let home_openinnewwindow_tap =  "home_openinnewwindow_tap"
    static let starred_openinnewwindow_tap = "starred_openinnewwindow_tap"
    static let unfiled_openinnewwindow_tap = "unfiled_openinnewwindow_tap"
    static let trash_emptytrash_tap = "trash_emptytrash_tap"
    static let templates_openinnewwindow_tap = "templates_openinnewwindow_tap"
    static let category_openinnewwindow_tap = "category_openinnewwindow_tap"
    static let category_rename_tap = "category_rename_tap"
    static let category_trash_tap = "category_trash_tap"

    static let sidebar_photo_openinnewwindow_tap = "sidebar_photo_openinnewwindow_tap"
    static let sidebar_recording_openinnewindow_tap = "sidebar_recording_openinnewindow_tap"
    static let sidebar_bookmark_openinnewwindow_tap = "sidebar_bookmark_openinnewwindow_tap"
    static let sidebar_tag_rename_tap = "sidebar_tag_rename_tap"
    static let sidebar_tag_delete_tap = "sidebar_tag_delete_tap"

    // Shelf Top level Actions
    static let shelf_quicknote_tap = "shelf_quicknote_tap"
    static let shelf_newnotebook_tap = "shelf_newnotebook_tap"
    static let shelf_importfile_tap = "shelf_importfile_tap"
    static let shelf_search_tap = "shelf_search_tap"
    static let shelf_more_tap = "shelf_more_tap"
    static let shelf_addmenu_tap = "shelf_addmenu_tap"
    static let shelf_book_tap = "shelf_book_tap"
    // Shelf Add Menu Actions
    static let shelf_addmenu_quicknote_tap = "shelf_addmenu_quicknote_tap"
    static let shelf_addmenu_newnotebook_tap = "shelf_addmenu_newnotebook_tap"
    static let shelf_addmenu_importfile_tap = "shelf_addmenu_importfile_tap"
    static let shelf_addmenu_phototemplate_tap = "shelf_addmenu_phototemplate_tap"
    static let shelf_addmenu_audionote_tap = "shelf_addmenu_audionote_tap"
    static let shelf_addmenu_scandoc_tap = "shelf_addmenu_scandoc_tap"
    static let shelf_addmenu_takephoto_tap = "shelf_addmenu_takephoto_tap"

    // Shelf Sort Order
    static let shelf_more_lastopened_tap = "shelf_more_lastopened_tap"
    static let shelf_more_lastmodified_tap = "shelf_more_lastmodified_tap"
    static let shelf_more_name_tap = "shelf_more_name_tap"
    static let shelf_more_custom_tap = "shelf_more_custom_tap"

    // Shelf More Actions
    static let shelf_more_selectnotes_tap = "shelf_more_selectnotes_tap"
    static let shelf_more_settings_tap = "shelf_more_settings_tap"
    static let shelf_more_largebook_tap = "shelf_more_largebook_tap"
    static let shelf_more_smallbook_tap = "shelf_more_smallbook_tap"
    static let shelf_more_list_tap = "shelf_more_list_tap"

    // Shelf Edit Actions
    static let shelf_select_book_tap = "shelf_select_book_tap"
    static let shelf_select_group_tap = "shelf_select_group_tap"

    static let shelf_select_selectall_tap = "shelf_select_selectall_tap"
    static let shelf_select_selectnone_tap = "shelf_select_selectnone_tap"
    static let shelf_select_done_tap = "shelf_select_done_tap"

    static let shelf_select_restore_tap = "shelf_select_restore_tap"
    static let shelf_select_delete_tap = "shelf_select_delete_tap"
    static let shelf_select_share_tap = "shelf_select_share_tap"
    static let shelf_select_move_tap = "shelf_select_move_tap"
    static let shelf_select_trash_tap = "shelf_select_trash_tap"
    static let shelf_select_rename_tap = "shelf_select_rename_tap"
    static let shelf_select_tags_tap = "shelf_select_tags_tap"
    static let shelf_select_duplicate_tap = "shelf_select_duplicate_tap"
    static let shelf_select_changecover_tap = "shelf_select_changecover_tap"
    static let shelf_select_creategroup_tap = "shelf_select_creategroup_tap"

    // Shelf Notebook Contextmenu Actions
    static let shelf_book_openinnewindow_tap = "shelf_book_openinnewindow_tap"
    static let shelf_book_showenclosingfolder_tap = "shelf_book_showenclosingfolder_tap"
    static let shelf_book_addtostarred_tap = "shelf_book_addtostarred_tap"
    static let shelf_book_rename_tap = "shelf_book_rename_tap"
    static let shelf_book_changecover_tap = "shelf_book_changecover_tap"
    static let shelf_book_tags_tap = "shelf_book_tags_tap"
    static let shelf_book_duplicate_tap = "shelf_book_duplicate_tap"
    static let shelf_book_move_tap = "shelf_book_move_tap"
    static let shelf_book_getinfo_tap = "shelf_book_getinfo_tap"
    static let shelf_book_share_tap = "shelf_book_share_tap"
    static let shelf_book_trash_tap = "shelf_book_trash_tap"
    static let shelf_book_removefromstarred_tap = "shelf_book_removefromstarred_tap"
    static let shelf_book_restore_tap = "shelf_book_restore_tap"
    static let shelf_book_delete_tap = "shelf_book_delete_tap"

    // Shelf Group Actions
    static let shelf_book_longpress = "shelf_book_longpress"
    static let shelf_book_draganddrop = "shelf_book_draganddrop"
    static let shelf_book_creategroup = "shelf_book_creategroup"
    static let shelf_book_addtogroup = "shelf_book_addtogroup"
    static let shelf_group_tap = "shelf_group_tap"
    static let shelf_group_longpress = "shelf_group_longpress"
    static let shelf_group_openinewwindow_tap = "shelf_group_openinewwindow_tap"
    static let shelf_group_rename_tap = "shelf_group_rename_tap"
    static let shelf_group_duplicate_tap = "shelf_group_duplicate_tap"
    static let shelf_group_move_tap = "shelf_group_move_tap"
    static let shelf_group_share_tap = "shelf_group_share_tap"
    static let shelf_group_trash_tap = "shelf_group_trash_tap"

    // Shelf Discover
    static let discover_expand = "discover_expand"
    static let discover_collapse = "discover_collapse"
    static let discover_blog_tap = "discover_blog_tap"

    // Shelf Tags
    static let shelf_tag_book_tap = "shelf_tag_book_tap"
    static let shelf_tag_book_longpress = "shelf_tag_book_longpress"
    static let shelf_tag_book_openinnewwindow_tap = "shelf_tag_book_openinnewwindow_tap"
    static let shelf_tag_book_edittags_tap = "shelf_tag_book_edittags_tap"
    static let shelf_tag_book_removetags_tap = "shelf_tag_book_removetags_tap"

    static let shelf_tag_page_tap = "shelf_tag_page_tap"
    static let shelf_tag_page_longpress = "shelf_tag_page_longpress"
    static let shelf_tag_page_openinnewwindow_tap = "shelf_tag_page_openinnewwindow_tap"
    static let shelf_tag_page_edittags_tap = "shelf_tag_page_edittags_tap"
    static let shelf_tag_page_removetags_tap = "shelf_tag_page_removetags_tap"

    static let shelf_tag_select_tap = "shelf_tag_select_tap"
    static let shelf_tag_select_done_tap = "shelf_tag_select_done_tap"
    static let shelf_tag_select_selectall_tap = "shelf_tag_select_selectall_tap"
    static let shelf_tag_select_selectnone_tap = "shelf_tag_select_selectnone_tap"
    static let shelf_tag_select_share_tap = "shelf_tag_select_share_tap"
    static let shelf_tag_select_edittags_tap = "shelf_tag_select_edittags_tap"
    static let shelf_tag_select_removetags_tap = "shelf_tag_select_removetags_tap"
    static let shelf_tag_select_page_tap = "shelf_tag_select_page_tap"
    static let shelf_tag_select_book_tap = "shelf_tag_select_book_tap"

    // Shelf Bookmarks
    static let shelf_bookmark_page_tap = "shelf_bookmark_page_tap"
    static let shelf_bookmark_page_longpress = "shelf_bookmark_page_longpress"
    static let shelf_bookmark_openinnewwindow_tap = "shelf_bookmark_openinnewwindow_tap"
    static let shelf_bookmark_remove_tap = "shelf_bookmark_remove_tap"

    // Shelf Photos
    static let shelf_photo_page_tap = "shelf_photo_page_tap"
    static let shelf_photo_page_longpress = "shelf_photo_page_longpress"
    static let shelf_photo_openinnewwindow_tap = "shelf_photo_openinnewwindow_tap"

    // Shelf Recording
    static let shelf_recording_page_tap = "shelf_recording_page_tap"
    static let shelf_recording_page_longpress = "shelf_recording_page_longpress"
    static let shelf_recording_openinnewwindow_tap = "shelf_recording_openinnewwindow_tap"

// Custom Toolbar
    static let toolbar_longpress = "toolbar_longpress"
    static let toolbar_more_customizetoolbar_tap = "toolbar_more_customizetoolbar_tap"
    static let customizetoolbar_reset_tap = "customizetoolbar_reset_tap"
    static let customizetoolbar_done_tap = "customizetoolbar_done_tap"
    static let customizetoolbar_tool_add = "customizetoolbar_tool_add"
    static let customizetoolbar_tool_remove = "customizetoolbar_tool_remove"
    static let customizetoolbar_tool_reorder = "customizetoolbar_tool_reorder"


}
