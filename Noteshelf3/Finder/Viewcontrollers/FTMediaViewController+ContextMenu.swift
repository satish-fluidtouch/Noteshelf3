//
//  FTMediaViewController+ContextMenu.swift
//  Noteshelf3
//
//  Created by Sameer on 25/08/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

enum FTMediaContextMenuOperation: String {
    case edit
    case share
    case play
    case trash
    case openInNewWindow
}

extension FTMediaViewController {
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        var contextMenu : UIContextMenuConfiguration?
        let identifier = indexPath as NSIndexPath
        
        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            return self.prepareContextMenu(for: indexPath)
        }
        contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: actionProvider)
        
        return contextMenu
    }
    
    internal func prepareContextMenu(for indexPath: IndexPath) -> UIMenu? {
        let mediaItem = filteredMediaObjects[indexPath.row]
        var editActionTitle = NSLocalizedString("Edit Photo", comment: "Edit Photo")
        if mediaItem.mediaType == .audio {
            editActionTitle = NSLocalizedString("Rename", comment: "Rename")
        }
        var imageActions = [UIMenuElement]()
        var audioActions = [UIMenuElement]()
        var actions = [UIMenuElement]()
        let configuration = UIImage.SymbolConfiguration(font: UIFont.appFont(for: .regular, with: 19))
        let editAction = UIAction(title: editActionTitle,
                                    image: UIImage(systemName: "pencil", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                  state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.edit, indexPath: indexPath, mediaItem: mediaItem)
        }
        
        let openInNewWindowAction = UIAction(title: NSLocalizedString("Open in New Window", comment: "Open in New Window"),
                                    image: UIImage(systemName: "rectangle.badge.plus", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                    state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.openInNewWindow, indexPath: indexPath, mediaItem: mediaItem)
        }
      
        let shareAction = UIAction(title: NSLocalizedString("Share", comment: "Share"),
                                    image: UIImage(systemName: "square.and.arrow.up", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                    state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.share, indexPath: indexPath, mediaItem: mediaItem)
        }
        
        
        let playAction = UIAction(title: NSLocalizedString("Play", comment: "Play"),
                                    image: UIImage(systemName: "play.fill", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .standard,
                                    state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.play, indexPath: indexPath, mediaItem: mediaItem)
        }
        
        let trashAction = UIAction(title: NSLocalizedString("Trash", comment: "Trash"),
                                    image: UIImage(systemName: "trash", withConfiguration: configuration),
                                    identifier: nil,
                                    discoverabilityTitle: nil,
                                    attributes: .destructive,
                                    state: .off) { [weak self] _ in
            self?.performContextMenuOperation(.trash, indexPath: indexPath, mediaItem: mediaItem)
        }
#if !targetEnvironment(macCatalyst)
        actions.append(openInNewWindowAction)
#endif
        actions.append(shareAction)
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
    }
}



extension UIMenuElement.Attributes {
    static let standard = UIMenuElement.Attributes([]);
}
