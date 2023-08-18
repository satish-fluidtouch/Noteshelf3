//
//  FTSideMenuItemModel+Mock.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 26/04/22.
//

import Foundation
import SwiftUI

struct FTIcon {
    let name: String
    let isSystemIcon: Bool

    init(systemName: String) {
        name = systemName
        isSystemIcon = true
    }

    init(bundleName: String) {
        name = bundleName
        isSystemIcon = false
    }
}

extension Image {
    init(icon: FTIcon) {
        if icon.isSystemIcon {
            self.init(systemName: icon.name)
        } else {
            self.init(icon.name)
        }
    }
}

extension UIImage {
    convenience init?(icon: FTIcon) {
        if icon.isSystemIcon {
            self.init(systemName: icon.name)
        } else {
            self.init(named: icon.name)
        }
    }
}

extension FTIcon {
    static let richtext: FTIcon = FTIcon(systemName: "doc.richtext")
    static let folder: FTIcon = FTIcon(systemName: "folder")
    static let tags: FTIcon = FTIcon(systemName: "tag")
    static let number: FTIcon = FTIcon(systemName: "number")
    static let upChevron: FTIcon = FTIcon(systemName: "chevron.up")
    static let downChevron: FTIcon = FTIcon(systemName: "chevron.down")
    static let createGroup: FTIcon = FTIcon(systemName: "folder.badge.plus")
    static let duplicate: FTIcon = FTIcon(systemName: "plus.square.on.square")
    static let rename: FTIcon = FTIcon(systemName: "pencil")
    static let changeCover: FTIcon = FTIcon(systemName: "book.closed")
    static let notebook: FTIcon = FTIcon(bundleName: "notebook")
    static let importFromFiles: FTIcon = FTIcon(bundleName: "importFile")
    static let photoLibrary: FTIcon = FTIcon(systemName: "photo.artframe")
    static let scanDocument: FTIcon = FTIcon(systemName: "viewfinder")
    static let appleWatch: FTIcon = FTIcon(systemName: "applewatch")
    static let audioNote: FTIcon = FTIcon(systemName: "mic")
    static let takePhoto: FTIcon = FTIcon(systemName: "camera")
    static let plusCircle: FTIcon = FTIcon(systemName: "plus.circle")
    static let templates: FTIcon = FTIcon(systemName: "app.gift")
    static let allNotes: FTIcon = FTIcon(systemName: "doc.on.doc")
    static let plus: FTIcon = FTIcon(systemName: "plus")
    static let favorites: FTIcon = FTIcon(systemName: "star")
    static let shared: FTIcon = FTIcon(systemName: "person.2")
    static let trash: FTIcon = FTIcon(systemName: "trash")
    static let openInNewWindow: FTIcon = FTIcon(systemName: "rectangle.badge.plus")
    static let move: FTIcon = FTIcon(systemName: "folder")
    static let addToFavorites: FTIcon = FTIcon(systemName: "star")
    static let removeFromFavorites: FTIcon = FTIcon(systemName: "star.fill")
    static let infoCircle: FTIcon = FTIcon(systemName: "info.circle")
    static let shareViaICloud: FTIcon = FTIcon(systemName: "person.crop.circle.badge.plus")
    static let share: FTIcon = FTIcon(systemName: "square.and.arrow.up")
    static let unsorted: FTIcon = FTIcon(systemName: "tray")
    static let restore: FTIcon = FTIcon(systemName: "arrow.counterclockwise")
    static let bookmark: FTIcon = FTIcon(systemName: "bookmark")
    static let showEnclosingFolder: FTIcon = FTIcon(systemName: "folder.badge.questionmark")
    static let photo: FTIcon = FTIcon(systemName: "photo.on.rectangle.angled")
    static let quickNote: FTIcon = FTIcon(bundleName: "Quicknote")
    static let quickCreateSettings = FTIcon(systemName: "slider.horizontal.3")
    static let search = FTIcon(systemName: "magnifyingglass")
    static let ellipsis = FTIcon(systemName: "ellipsis.circle")
    static let selectnotes = FTIcon(bundleName: "selectNotes")
    static let settings = FTIcon(bundleName: "settingsicon")
    static let clock = FTIcon(bundleName: "clock")
    static let character = FTIcon(bundleName: "character")
    static let icloud = FTIcon(bundleName: "icloudsync")
    static let autoBackup = FTIcon(bundleName: "autoBackup")
    static let evernote = FTIcon(bundleName: "evernote")
    static let exportData = FTIcon(bundleName: "exportData")
    static let backupWifi = FTIcon(bundleName: "backupwifi")
    static let rightArrow = FTIcon(systemName: "chevron.right")
    static let leftArrow = FTIcon(systemName: "chevron.left")
    static let docText = FTIcon(systemName: "doc.text")
    static let saveToPhoto = FTIcon(bundleName: "saveToPhoto")
    static let saveAsTemplate = FTIcon(systemName: "doc.richtext")
    static let rotateRight = FTIcon(systemName: "rotate.right")
    static let rotateLeft = FTIcon(systemName: "rotate.left")
    static let textMagnifyingglass = FTIcon(systemName: "doc.text.magnifyingglass")
    static let arrowCounterclockwise = FTIcon(systemName: "arrow.counterclockwise")
    static let squareAarrowUp = FTIcon(systemName: "square.and.arrow.up")
    static let handTap = FTIcon(systemName: "hand.tap")
    static let questionmarkCircle = FTIcon(systemName: "questionmark.circle")
    static let rectangleTextMagnifyingglass = FTIcon(systemName: "rectangle.and.text.magnifyingglass")
    static let present = FTIcon(bundleName: "present")
    static let customizeToolBar = FTIcon(bundleName: "customizeToolBar")
    static let gearShape = FTIcon(systemName: "gearshape")
    static let checkmark = FTIcon(systemName: "checkmark")
    static let photoIcon = FTIcon(systemName: "photo")
    static let richTextfill = FTIcon(systemName: "doc.richtext.fill")
    static let migrate = FTIcon(systemName: "rectangle.portrait.and.arrow.forward")
}
