//
//  FTAudioMoreOptionsViewController.swift
//  Noteshelf
//
//  Created by Sameer on 18/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

enum FTAudioMoreOption: String, CaseIterable {
    case speed
    case jumpToPage
    case rename
    case goToRecording
    case share
    case delete
    case close
    
    func title() -> String {
        let title: String
        switch self {
        case .jumpToPage:
            title = "Jump to Page"
        case .rename:
            title = "Rename"
        case .goToRecording:
            title = "Go to Recording"
        case .share:
            title = "Share"
        case .delete:
            title = "Trash"
        case .speed:
            title = "Speed"
        case .close:
            title = "Close"
        }
        return title.localized
    }
    
    func image() -> UIImage? {
        var imageKey = ""
        switch self {
        case .jumpToPage:
            imageKey = "doc.text.magnifyingglass"
        case .rename:
            imageKey = "pencil"
        case .goToRecording:
            imageKey = "play.circle"
        case .share:
            imageKey = "square.and.arrow.up"
        case .delete:
            imageKey = "trash"
        case .speed:
            imageKey = "square.and.arrow.up"
        case .close:
            imageKey = "xmark.circle.fill"
        }
        return UIImage.image(for: imageKey, font: UIFont.appFont(for: .regular, with: 15))
    }
    
    func actionElment(completion: @escaping (UIAction) -> Void) -> UIAction {
        let saveAction = { (action: UIAction) in
            completion(action)
        }
        let attributes = (self == .delete) ? UIMenuElement.Attributes.destructive : UIMenuElement.Attributes.standard
        return UIAction(title: self.title(), image: self.image(),identifier: UIAction.Identifier(self.rawValue),attributes: attributes, handler: saveAction)
    }
}

