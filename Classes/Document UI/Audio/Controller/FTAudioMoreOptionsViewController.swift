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
        let localizedKey: String
        switch self {
        case .jumpToPage:
            localizedKey = "audiooption.jumptoPage"
        case .rename:
            localizedKey = "Rename"
        case .goToRecording:
            localizedKey = "audiooption.gotoRecording"
        case .share:
            localizedKey = "Share"
        case .delete:
            localizedKey = "Trash"
        case .speed:
            localizedKey = "audiooption.speed"
        case .close:
            localizedKey = "Close"
        }
        return localizedKey.localized
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
            imageKey = "normal"
        case .close:
            imageKey = "xmark.circle.fill"
        }
        var image = UIImage.image(for: imageKey, font: UIFont.appFont(for: .regular, with: 15))
        if image == nil {
            image = UIImage(named: imageKey)?.withTintColor(.label)
        }
        return image
    }
    
    func actionElment(completion: @escaping (UIAction) -> Void) -> UIAction {
        let saveAction = { (action: UIAction) in
            completion(action)
        }
        let attributes = (self == .delete) ? UIMenuElement.Attributes.destructive : UIMenuElement.Attributes.standard
        return UIAction(title: self.title(), image: self.image(),identifier: UIAction.Identifier(self.rawValue),attributes: attributes, handler: saveAction)
    }
}

