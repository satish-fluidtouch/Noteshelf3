//
//  FTMediaObject.swift
//  Noteshelf3
//
//  Created by Sameer on 24/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

public enum FTMediaType: String {
    case photo
    case audio
    case attachment
    case sticker
    case webclip
    case allMedia
    
    func image() -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 15))
        var imageName = "doc.on.doc"
        switch self {
        case .photo:
            imageName = "photo"
        case .audio:
            imageName = "mic"
        case .sticker:
            imageName = "DocumentEntity/addmenu_stickers"
        case .webclip:
            imageName = "macwindow"
        case .allMedia:
            imageName = "rectangle.grid.2x2"
        default:
            imageName = "doc.on.doc"
        }
        var image = UIImage(systemName: imageName, withConfiguration: configuration)
        if image == nil {
            image =  UIImage(named: imageName)?.withTintColor(.black)
        }
        return image
    }
    
    func title() -> String {
        var title = ""
        switch self {
        case .photo:
            title = "Photo"
        case .audio:
            title = "Recording"
        case .allMedia:
            title = "finder.media.allcontent"
        case .sticker:
            title = "finder.media.sticker"
        case .webclip:
            title = "newnotebook.webclip.title"

        default:
            break
        }
        return title.localized
    }
    
    func actionElment(completion: @escaping (UIAction) -> Void) -> UIAction {
        return UIAction(title: self.title(),
                        image: self.image(),
                        identifier: UIAction.Identifier(self.rawValue),
                        handler: completion)
    }
}

protocol FTMediaItem {
    var mediaType: FTMediaType {get set}
    var page: FTThumbnailable? {get set}
    var annotation: FTAnnotation? {get set}
}

class FTMediaObject: NSObject, FTMediaItem {
    var mediaType: FTMediaType = .allMedia
    var page: FTThumbnailable?
    var annotation: FTAnnotation?
    
    init(page: FTThumbnailable, annotation: FTAnnotation) {
        super.init()
        self.page = page
        self.annotation = annotation
        var mediaType = FTMediaType.allMedia
        if annotation.annotationType == .image {
            mediaType = .photo
        } else if annotation.annotationType == .audio {
            mediaType = .audio
        } else if annotation.annotationType == .sticker {
            mediaType = .sticker
        } else if annotation.annotationType == .webclip {
            mediaType = .webclip
        }
        self.mediaType = mediaType
    }
    
}
