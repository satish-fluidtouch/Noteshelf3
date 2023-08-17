//
//  FTContextMenuRepresentation.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct FTContextMenuRepresentation<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder let content : () -> Content;
    
    let onAppearAction: (() -> Void)?;
    let onDisappearAction: (() -> Void)?;
    
    @EnvironmentObject var shelfItemModel: FTShelfViewModel;
    weak var shelfItem: FTShelfItemViewModel?;    
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: content())
        
        // Create and add a UIContextMenuInteraction to the view
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        host.view.backgroundColor = .clear
        host.view.addInteraction(interaction)
        
        let dragInteraction = UIDragInteraction(delegate: context.coordinator);
        host.view.addInteraction(dragInteraction)
        host.view.clipsToBounds = true;
        
        return host;
    }
    
    func updateUIViewController(_ host: UIHostingController<Content>, context: Context) {
        // Update the view if needed
        host.rootView = content() // Update content
    }
    
    func makeCoordinator() -> FTContextMenuCoordinator {
        let coCoordinator = FTContextMenuCoordinator(representView: self);
        return coCoordinator;
    }
    
    class FTContextMenuCoordinator: NSObject, UIContextMenuInteractionDelegate,UIDragInteractionDelegate {
        let representView: FTContextMenuRepresentation;
        
        init(representView view: FTContextMenuRepresentation) {
            representView = view;
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            // Return the configuration for the context menu
            return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                return nil
            }) { [weak self] _ in
                guard let strongSelf = self
                        ,let _shelfItem = strongSelf.representView.shelfItem else {
                    return nil;
                }
                
                let _shelfModel = strongSelf.representView.shelfItemModel;
                                
                let menuItems = _shelfModel.getContexualOptionsForShelfItem(_shelfItem);
                var mainGroups = [UIMenuElement]();
                
                menuItems.forEach { group in
                    var actions = [UIAction]();
                    group.forEach { eachItem in
                        let action1 = UIAction(title:eachItem.displayTitle,
                                               image: UIImage(icon: eachItem.icon),
                                               attributes: eachItem.isDestructiveOption ? .destructive : .standard) { [weak self] _ in
                            guard let strongSelf = self else {
                                return;
                            }
                            
                            strongSelf.representView.onDisappearAction?();
                            _shelfModel.shelfItemContextualMenuViewModel.shelfItem = _shelfItem;
                            _shelfModel.shelfItemContextualMenuViewModel.performAction = eachItem;
                        }
                        actions.append(action1);
                    }
                    mainGroups.append(UIMenu(title: "", options: .displayInline, children: actions));
                }
                return UIMenu(title: "", children: mainGroups)
            }
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            self.representView.onDisappearAction?();
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            self.representView.onAppearAction?();
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            if self.representView.shelfItemModel.mode == .normal, let shelfItem = self.representView.shelfItem {
                let dragItem = UIDragItem(itemProvider: self.representView.shelfItemModel.itemProvider(shelfItem));
                dragItem.localObject = shelfItem;
                return [dragItem]
            }
            return [];
        }
    }
}
