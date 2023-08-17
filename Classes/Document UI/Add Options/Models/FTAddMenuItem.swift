//
//  FTAddMenuItem.swift
//  FTAddOperations
//
//  Created by Siva on 04/06/20.
//  Copyright © 2020 Siva. All rights reserved.
//

import Foundation
import UIKit



    
protocol FTAddMenuItemProtocol {
    var key: AddMenuItemKey { get }
    var comment: String { get }
    var type: AddMenuItemType { get }
    var thumbImage: String { get }
    var localizedTitle: String { get }
}

extension FTAddMenuItemProtocol {
    
    var comment: String {
        return ""
    }
    
    var type: AddMenuItemType {
        return .basic
    }
    
    //Localized
    var localizedTitle: String {
        return NSLocalizedString(key.rawValue, comment: comment)
    }
    
}
//MARK:- PagesMenuItems
struct PageMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .Page
    }
    
    var thumbImage: String {
        return "DocumentEntity/pagePage"
    }
    
}

struct PageFromTemplateMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .PageFromTemplate
    }
    
    var thumbImage: String {
        return "DocumentEntity/pageTemp"
    }
    
}

struct InsertFromClipboardMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .InsertFromClipboard
    }
    
    var thumbImage: String {
        return "DocumentEntity/pageClipboard"
    }
    
}

struct PhotoBackgroundMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .PhotoBackground
    }
    
    var thumbImage: String {
        return "DocumentEntity/pageImage"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
    var localizedTitle: String {
        return NSLocalizedString(key.rawValue, comment: "Photo Background")
    }
    
    
}

struct ImportDocumentMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .ImportDocument
    }
    
    var thumbImage: String {
        return "DocumentEntity/pageImport"
    }
    
    var type: AddMenuItemType {
        return .basic
    }
    
}

struct ImportScanDocumentMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .ScanDocument
    }
    
    var thumbImage: String {
        return "DocumentEntity/pageScan"
    }
    
}

//MARK:- MediaMenuItems
struct CameraMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .Camera
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaCamera"
    }
    
}

struct PhotoLibraryMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .PhotoLibrary
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaImage"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}

struct MediaLibraryMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .MediaLibrary
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaSticker"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}

struct EmojisMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .Emojis
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaEmoji"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}

struct RecordAudioMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .RecordAudio
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaAudio"
    }
    
}

struct RecordingsMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .AudioRecordings
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaAudiorec"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}

struct InsertMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .InsertFrom
    }
    
    var thumbImage: String {
        return "DocumentEntity/mediaFolder"
    }
    
}

//MARK:- TagsMenuItems
struct PageTagMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .Tags
    }
    
    var thumbImage: String {
        return "DocumentEntity/tag"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}

struct BookmarkTagMenuItem: FTAddMenuItemProtocol  {
    
    var key: AddMenuItemKey {
        return .Bookmark
    }
    
    var thumbImage: String {
        return "DocumentEntity/bookmark"
    }
    
    var type: AddMenuItemType {
        return .disclose
    }
    
}
enum AddMenuItemKey: String {
    case Page
    case PageFromTemplate
    case InsertFromClipboard
    case PhotoBackground
    case ImportDocument
    case ScanDocument
    
    case Camera
    case PhotoLibrary
    case MediaLibrary
    case Emojis
    case RecordAudio
    case AudioRecordings
    case InsertFrom
    
    case Tags
    case Bookmark
    
    
    //    case PageFromClipBoard
    case Stickers
    case Clipart
    //    case PageTags
    case BookmarkThisPage
    case Photo
    case Audio
    case More
    case AddPageOptions
    
    var localizedTitle: String {
        return NSLocalizedString(self.rawValue, comment: self.rawValue)
    }
}

enum AddMenuItemType:String,Codable {
    case basic
    case disclose
}
