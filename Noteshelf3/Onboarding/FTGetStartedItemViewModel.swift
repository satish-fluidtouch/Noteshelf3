//
//  FTGetStartedModel.swift
//  Noteshelf3
//
//  Created by Rakesh on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTGetStartedViewItems:CaseIterable {
    case autoBackup
    case superNaturalPens
    case focusmode
    case daynightJournal
    case customizableToolbar
    case unsplash
    case savedClips
    case links
    case widgets
    case pixabay
    case beatifulCovers
//    case fancyHeaders
    case stickers
    case emojies
    case audioNotes
    case webClip
    case iCloudsync
    case appleWatch
    case macApp
    case shapes
    case imageEditing
    case importDocuments
    case presentMode
    case richText
    case tags
    case nestedGroups
    case presureSensitive
    case handwritingRecognition
    case scanDocuments
    case bookmarks
    case password
    case customTemplates
    case zoombox
    case thousandPlusTemplates
    case digitalDiaries

    var displayTitle:String{
        let title:String
        switch self {
        case .autoBackup:
            title = "welcome.autoBackup"
        case .superNaturalPens:
            title = "welcome.superNaturalPens"
        case .focusmode:
            title = "welcome.focusMode"
        case .daynightJournal:
            title = "welcome.dayNightJournal"
        case .customizableToolbar:
            title = "welcome.customizableToolBar"
        case .unsplash:
            title = "welcome.unsplash"
        case .savedClips:
            title = "welcome.savedClips"
        case .links:
            title = "welcome.links"
        case .widgets:
            title = "welcome.widgets"
        case .pixabay:
            title = "welcome.pixabay"
        case .beatifulCovers:
            title = "welcome.beautifulCovers"
//        case .fancyHeaders:
//            title = "welcome.fancyHeaders"
        case .stickers:
            title = "welcome.stickers"
        case .emojies:
            title = "welcome.emojies"
        case .audioNotes:
            title = "welcome.audioNotes"
        case .webClip:
            title = "welcome.webClips"
        case .iCloudsync:
            title = "welcome.icloudSync"
        case .appleWatch:
            title = "welcome.appleWatch"
        case .macApp:
            title = "welcome.macApp"
        case .shapes:
            title = "welcome.shapes"
        case .imageEditing:
            title = "welcome.imageEditing"
        case .importDocuments:
            title = "welcome.importDocuments"
        case .presentMode:
            title = "welcome.presentMode"
        case .richText:
            title = "welcome.richText"
        case .tags:
            title = "welcome.tags"
        case .nestedGroups:
            title = "welcome.nestedgroups"
        case .presureSensitive:
            title = "welcome.pressureSensitive"
        case .handwritingRecognition:
            title = "welcome.handWritingRecognition"
        case .scanDocuments:
            title = "welcome.scanDocuments"
        case .bookmarks:
            title = "welcome.bookmarks"
        case .password:
            title = "welcome.password"
        case .customTemplates:
            title = "welcome.customTemplates"
        case .zoombox:
            title = "welcome.zoombox"
        case .thousandPlusTemplates:
            title = "welcome.thousandPlusTemplates"
        case .digitalDiaries:
            title = "welcome.digitalDiaries"
        }
        return title.localized
    }

    var imageName: String {
        let name: String
        switch self {
        case .autoBackup:
            name = "auto_backup"
        case .superNaturalPens:
            name = "super_naturalpens"
        case .focusmode:
            name = "focusmode"
        case .daynightJournal:
            name = "daynight_journal"
        case .customizableToolbar:
            name = "customizable_toolbar"
        case .unsplash:
            name = "unsplash_welcome"
        case .savedClips:
            name = "welcome.savedclips"
        case .links:
            name = "welcome.links"
        case .widgets:
            name = "welcome.widgets"
        case .pixabay:
            name = "pixabay_welcome"
        case .beatifulCovers:
            name = "beautiful_covers"
//        case .fancyHeaders:
//            name = "fancy_headers"
        case .stickers:
            name = "stickers"
        case .emojies:
            name = "emojies"
        case .audioNotes:
            name = "audio_notes"
        case .webClip:
            name = "webclips"
        case .iCloudsync:
            name = "icloud_sync"
        case .appleWatch:
            name = "apple_watch"
        case .macApp:
            name = "macApp"
        case .shapes:
            name = "shapes"
        case .imageEditing:
            name = "image_editing"
        case .importDocuments:
            name = "import_documents"
        case .presentMode:
            name = "presentMode"
        case .richText:
            name = "richText"
        case .tags:
            name = "welcome_tags"
        case .nestedGroups:
            name = "nestedGroups"
        case .presureSensitive:
            name = "pressure_sensitive"
        case .handwritingRecognition:
            name = "handwriting_recognition"
        case .scanDocuments:
            name = "scanDocments"
        case .bookmarks:
            name = "bookmarks"
        case .password:
            name = "password"
        case .customTemplates:
            name = "custom_templates"
        case .zoombox:
            name = "zoombox"
        case .thousandPlusTemplates:
            name = "tenthousandplusTemplates"
        case .digitalDiaries:
            name = "digital_dairies"
        }
        return name
    }
    
    var itemDescription:String{
        let title:String
        switch self {
        case .autoBackup:
            title = "welcome.autoBackup,description"
        case .superNaturalPens:
            title = "welcome.superNaturalPens.description"
        case .focusmode:
            title = "welcome.focusMode.description"
        case .daynightJournal:
            title = "welcome.dayNightJournal.description"
        case .customizableToolbar:
            title = "welcome.customizableToolBar.description"
        case .unsplash:
            title = "welcome.unsplash.description"
        case .savedClips:
            title = "welcome.savedclips.description"
        case .links:
            title = "welcome.links.description"
        case .widgets:
            title = "welcome.widgets.description"
        case .pixabay:
            title = "welcome.pixabay.description"
        case .beatifulCovers:
            title = "welcome.beautifulCovers.description"
//        case .fancyHeaders:
//            title = "welcome.fancyHeaders.description"
        case .stickers:
            title = "welcome.stickers.description"
        case .emojies:
            title = "welcome.emojies.description"
        case .audioNotes:
            title = "welcome.audioNotes.description"
        case .webClip:
            title = "welcome.webClips.description"
        case .iCloudsync:
            title = "welcome.icloudSync.description"
        case .appleWatch:
            title = "welcome.appleWatch.description"
        case .macApp:
            title = "welcome.macApp.description"
        case .shapes:
            title = "welcome.shapes.description"
        case .imageEditing:
            title = "welcome.imageEditing.description"
        case .importDocuments:
            title = "welcome.importDocuments.description"
        case .presentMode:
            title = "welcome.presentMode.description"
        case .richText:
            title = "welcome.richText.description"
        case .tags:
            title = "welcome.tags.description"
        case .nestedGroups:
            title = "welcome.nestedgroups.description"
        case .presureSensitive:
            title = "welcome.pressureSensitive.description"
        case .handwritingRecognition:
            title = "welcome.handWritingRecognition.description"
        case .scanDocuments:
            title = "welcome.scanDocuments.description"
        case .bookmarks:
            title = "welcome.bookmarks.description"
        case .password:
            title = "welcome.password.description"
        case .customTemplates:
            title = "welcome.customTemplates.description"
        case .zoombox:
            title = "welcome.zoombox.description"
        case .thousandPlusTemplates:
            title = "welcome.thousandPlusTemplates.description"
        case .digitalDiaries:
            title = "welcome.digitalDiaries.description"
        }
        return title.localized
    }
    
    var previewImageName: String {
        let name: String
        switch self {
        case .autoBackup:
            name = "welcome.autoBackup.preview"
        case .superNaturalPens:
            name = "welcome.superNaturalPens.preview"
        case .focusmode:
            name = "welcome.focusMode.preview"
        case .daynightJournal:
            name = "welcome.dayNightJournal.preview"
        case .customizableToolbar:
            name = "welcome.customizableToolBar.preview"
        case .unsplash:
            name = "welcome.unsplash.preview"
        case .savedClips:
            name = "welcome.savedClips.preview"
        case .links:
            name = "welcome.links.preview"
        case .widgets:
            name = "welcome.widgets.preview"
        case .pixabay:
            name = "welcome.pixabay.preview"
        case .beatifulCovers:
            name = "welcome.beautifulCovers.preview"
//        case .fancyHeaders:
//            name = "fancy_headers"
        case .stickers:
            name = "welcome.stickers.preview"
        case .emojies:
            name = "welcome.emojies.preview"
        case .audioNotes:
            name = "welcome.audioNotes.preview"
        case .webClip:
            name = "welcome.webClips.preview"
        case .iCloudsync:
            name = "welcome.icloudSync.preview"
        case .appleWatch:
            name = "welcome.appleWatch.preview"
        case .macApp:
            name = "welcome.macApp.preview"
        case .shapes:
            name = "welcome.shapes.preview"
        case .imageEditing:
            name = "welcome.imageEditing.preview"
        case .importDocuments:
            name = "welcome.importDocuments.preview"
        case .presentMode:
            name = "welcome.presentMode.preview"
        case .richText:
            name = "welcome.richText.preview"
        case .tags:
            name = "welcome.tags.preview"
        case .nestedGroups:
            name = "welcome.nestedgroups.preview"
        case .presureSensitive:
            name = "welcome.pressureSensitive.preview"
        case .handwritingRecognition:
            name = "welcome.handWritingRecognition.preview"
        case .scanDocuments:
            name = "welcome.scanDocuments.preview"
        case .bookmarks:
            name = "welcome.bookmarks.preview"
        case .password:
            name = "welcome.password.preview"
        case .customTemplates:
            name = "welcome.customTemplates.preview"
        case .zoombox:
            name = "welcome.zoombox.preview"
        case .thousandPlusTemplates:
            name = "welcome.thousandPlusTemplates.preview"
        case .digitalDiaries:
            name = "welcome.digitalDiaries.preview"
        }
        return name
    }
}
class FTGetStartedItemViewModel: ObservableObject {
    var getstartedList: [FTGetStartedViewItems] = FTGetStartedViewItems.allCases

    var headerTopTitle: String {
        return "welcome.headertopTitle".localized
    }
    var headerbottomfirstTitle: String {
        return "welcome.headerbottomfirstTitle".localized
    }
    var headerbottomsecondTitle: String {
        return "welcome.headerbottomsecondTitle".localized
    }
    var btntitle: String {
        return "welcome.getStarted".localized
    }
    var appLogo:String{
        return "logo"
    }
}
