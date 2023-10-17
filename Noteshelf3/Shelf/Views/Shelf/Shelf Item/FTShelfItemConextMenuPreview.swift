//
//  FTShelfItemConextMenuPreview.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 13/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import SwiftUI

struct FTShelfItemContextMenuPreview<Content: View>: UIViewControllerRepresentable {
    
    @ViewBuilder let preview : () -> Content;
    let notebookShape: ()-> FTNotebookShape?;
    
    let onAppearActon: (() -> Void)?;
    let onDisappearActon: (() -> Void)?;
    
    @EnvironmentObject var shelfItemModel: FTShelfViewModel;
    weak var shelfItem: FTShelfItemViewModel?;

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: preview())
        
        // Create and add a UIContextMenuInteraction to the view
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        host.view.backgroundColor = .clear
        host.view.addInteraction(interaction)
        
        let dragInteraction = UIDragInteraction(delegate: context.coordinator);
        host.view.addInteraction(dragInteraction);
        host.view.clipsToBounds = true;
        
        return host;
    }
    
    func updateUIViewController(_ host: UIHostingController<Content>, context: Context) {
        // Update the view if needed
        host.rootView = preview() // Update content
    }
    
    func makeCoordinator() -> FTContextMenuCoordinator {
        let coCoordinator = Coordinator(representView: self);
        return coCoordinator;
    }
    
    // Coordinator class to handle interaction events
    class FTContextMenuCoordinator: NSObject, UIContextMenuInteractionDelegate,UIDragInteractionDelegate {
        let representView: FTShelfItemContextMenuPreview;
        
        init(representView view: FTShelfItemContextMenuPreview) {
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

                if _shelfModel.isNS2Collection {
                    return nil;
                }

                let menuItems = _shelfModel.getContexualOptionsForShelfItem(_shelfItem);
                var mainGroups = [UIMenuElement]();

                menuItems.forEach { group in
                    var actions = [UIAction]();
                    group.forEach { eachItem in
                        var actionType: UIMenuElement.Attributes = eachItem.isDestructiveOption ? .destructive : .standard
                        if _shelfItem.isPinEnabled && eachItem == .tags {
                            actionType = .disabled
                        }
                        var action1 = UIAction(title:eachItem.displayTitle,
                                               image: UIImage(icon: eachItem.icon),
                                               attributes: actionType) { [weak self] _ in
                            guard let strongSelf = self else {
                                return;
                            }

                            strongSelf.representView.onDisappearActon?();
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
        
        private func targettedPreview(_ interaction: UIInteraction) -> UITargetedPreview? {
            if let _parentPreview = interaction.view {
                
                let parameters = UIPreviewParameters();
                parameters.backgroundColor = .clear;
                if let shape = self.representView.notebookShape() {
                    let frame = _parentPreview.bounds;
                    let path = UIBezierPath(cgPath: shape.path(in: frame).cgPath);
                    parameters.visiblePath = path;
                }
                
                if interaction is UIContextMenuInteraction {
                    return UITargetedPreview(view: _parentPreview, parameters: parameters);
                }
                else if interaction is UIDragInteraction {
                    return UITargetedDragPreview(view: _parentPreview, parameters: parameters);
                }
            }
            return nil;
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            self.representView.onDisappearActon?();
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            self.representView.onAppearActon?();
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            return targettedPreview(interaction);
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
            return targettedPreview(interaction);
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let _shelfViewmodel = self.representView.shelfItemModel;
            if _shelfViewmodel.isNS2Collection { // Not supporting drag for ns2 books under ns2 category
                return []
            }
            if self.representView.shelfItemModel.mode == .normal, let shelfItem = self.representView.shelfItem {
                let dragItem = UIDragItem(itemProvider: self.representView.shelfItemModel.itemProvider(shelfItem));
                dragItem.localObject = shelfItem;
                return [dragItem]
            }
            return []
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
            return targettedPreview(interaction) as? UITargetedDragPreview ?? nil;
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
            self.representView.shelfItemModel.endDragAndDropOperation();
        }
        
        func dragInteraction(_ interaction: UIDragInteraction, sessionDidTransferItems session: UIDragSession) {
            self.representView.shelfItemModel.endDragAndDropOperation();
        }
    }

}
