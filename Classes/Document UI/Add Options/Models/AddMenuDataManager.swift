//
//  AddMenuItemManager.swift
//  Noteshelf
//
//  Created by srinivas on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTPageType: String {
    case newPage, chooseTemplate, photoTemplate, scanDocument, pageFromCamera, importDocument, inserFromclipboard
}

enum MediaType: String {
    case photo, camera, audio, emojis, stickers, importMedia
}

enum AttachmentType: String {
    case webClip, unsplash, pixabay
}

protocol MenuProtocal {
    var image: UIImage? { get }
    var name: String { get }
    var showDiscloser: Bool { get set }
}

struct PageItem: MenuProtocal {
    var image: UIImage?
    var name: String
    var showDiscloser: Bool = false
    var type: FTPageType
}

struct MediaItem: MenuProtocal {
    var image: UIImage?
    var name: String
    var showDiscloser: Bool = false
    var type: MediaType
}

struct AttachmentItem: MenuProtocal {
    var image: UIImage?
    var name: String
    var showDiscloser: Bool = false
    var type: AttachmentType
}

class AddMenuDataManager {
    private let folderPrefix = "DocumentEntity/"

    func fetchPageItems() -> [[PageItem]] {
        let newPageItem = PageItem(image: UIImage(named: folderPrefix + "addmenu_newPage"), name: "notebook.addnew.newpage".localized, type: .newPage)

        let choseTemplateItem = PageItem(image: UIImage(named: folderPrefix + "addmenu_chooseTemplate"), name: "ChoosePaperTemplate".localized, type: .chooseTemplate)

        let photoItem = PageItem(image: UIImage(systemName: "photo.artframe"), name: "Photo".localized, type: .photoTemplate)
        let cameraItem = PageItem(image: UIImage(systemName: "camera"), name: "Camera".localized, type: .pageFromCamera)

        var items = [[newPageItem], [choseTemplateItem]]

#if !targetEnvironment(macCatalyst)
        let scanItem = PageItem(image: UIImage(systemName: "viewfinder"), name: "Scan".localized, type: .scanDocument)
        items.append([photoItem, scanItem, cameraItem])
#else
        items.append([photoItem, cameraItem])
#endif

        let importDocItem = PageItem(image: UIImage(systemName: "square.and.arrow.down"), name: "ImportDocument".localized, type: .importDocument)
        items.append([importDocItem])

        if FTPasteBoardManager.shared.isUrlValid() {
            let insertFromClipboard = PageItem(image: UIImage(systemName: "clipboard"), name: "Insert from Clipboard", type: .inserFromclipboard)
            items.append([insertFromClipboard])
        }
        return items
    }

    func fetchMediaItems() -> [[MediaItem]] {
        let photoItem = MediaItem(image: UIImage(systemName: "photo.on.rectangle"), name: "Photo".localized, type: .photo)
        let cameraItem = MediaItem(image:UIImage(systemName: "camera"), name: "Camera".localized, type: .camera)

        let audioItem = MediaItem(image: UIImage(systemName: "mic.fill.badge.plus"), name: "RecordAudio".localized,type: .audio)
        let emojiItem = MediaItem(image: UIImage(systemName: "face.smiling"), name: "Emojis".localized, showDiscloser: true, type: .emojis)
        let stickerItem = MediaItem(image: UIImage(named: folderPrefix + "addmenu_stickers"), name: "customizeToolbar.stickers".localized, showDiscloser: true, type: .stickers)

        let importMediaItem = MediaItem(image: UIImage(systemName: "square.and.arrow.down"), name: "add.menu.import.media".localized, type: .importMedia)

        return [[photoItem, cameraItem], [audioItem, emojiItem, stickerItem], [importMediaItem]]
    }

    func fetchAttachmentItems() -> [AttachmentItem] {
        let webClipItem = AttachmentItem(image: UIImage(systemName: "macwindow"), name:"newnotebook.webclip.title".localized, type: .webClip)
        let unsplashItem = AttachmentItem(image: UIImage(named: folderPrefix + "addmenu_unsplash"), name:"Unsplash", showDiscloser: true, type: .unsplash)
        let pixabayItem = AttachmentItem(image: UIImage(named: folderPrefix + "addmenu_pixabay"), name:"Pixabay", showDiscloser: true, type: .pixabay)
        return [webClipItem, unsplashItem, pixabayItem]
    }
}
