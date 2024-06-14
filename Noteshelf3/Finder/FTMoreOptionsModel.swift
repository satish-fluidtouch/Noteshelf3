//
//  FTMoreOptionsModel.swift
//  Noteshelf3
//
//  Created by Sameer on 01/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles

enum FTEditOption: String {
    case edit
    case expand
    
    func image() -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 15))
        var imageName = "doc.on.doc"
        switch self {
        case .edit:
            imageName = "checkmark.circle"
        case .expand:
            imageName = "rectangle.inset.filled"
        }
        return UIImage(systemName: imageName, withConfiguration: configuration)
    }
    
    func title() -> String {
        var title = ""
        switch self {
        case .edit:
            title = NSLocalizedString("Select", comment: "Select")
        case .expand:
            title = "finder.fullscreen".localized
        }
        return title
    }
    
    func actionElment(completion: @escaping (UIAction) -> Void) -> UIAction {
        let saveAction = { (action: UIAction) in
            completion(action)
        }
        return UIAction(title: self.title(), image: self.image(),identifier: UIAction.Identifier(self.rawValue), handler: saveAction)
    }
}

enum FTMoreOption: String {
    case copy
    case move
    case bookMark
    case tag
    case delete
    
    func image() -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 15))
        var imageName = "doc.on.doc"
        switch self {
        case .copy:
            imageName = "doc.on.doc"
        case .move:
            imageName = "rectangle.portrait.and.arrow.right"
        case .bookMark:
            imageName = "bookmark"
        case .tag:
            imageName = "tag"
        case .delete:
            imageName = "trash"
        }
        return UIImage(systemName: imageName, withConfiguration: configuration)
    }
    
    func title() -> String {
        var title = ""
        switch self {
        case .copy:
            title = NSLocalizedString("Copy", comment: "Copy")
        case .move:
            title = NSLocalizedString("move", comment: "move")
        case .bookMark:
            title = NSLocalizedString("customizeToolbar.bookmark", comment: "bookmark")
        case .tag:
            title = NSLocalizedString("finder.tag", comment: "tag")
        case .delete:
            title = NSLocalizedString("delete", comment: "delete")
        }
        return title
    }
    
    func actionElment(isEnabled: Bool = true, completion: @escaping (UIAction) -> Void) -> UIAction {
        let action = { (action: UIAction) in
            completion(action)
        }
        var attributes =  UIMenuElement.Attributes.standard
        if self == .delete {
            attributes = .destructive
        }
        if !isEnabled {
            attributes = .disabled
        }
        return UIAction(title: self.title(), image: self.image(),identifier: UIAction.Identifier(self.rawValue), attributes: attributes, handler: action)
    }
    
    func eventDescription() -> String {
        var eventName = ""
        switch self {
        case .copy :
            eventName = "finder_select_copy_tap"
        case .bookMark :
            eventName = "finder_select_bookmark_tap"
        case .move :
            eventName = "finder_select_move_tap"
        case .tag :
            eventName = "finder_select_tag_tap"
        case .delete :
            eventName = "finder_select_delete_tap"
        }
        return eventName
    }
}
