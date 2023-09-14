//
//  FTSideBarItemContextMenuPreview.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles
import SwiftUI

struct FTSideBarItemContextMenuPreview<Content: View>: UIViewControllerRepresentable {

    @ViewBuilder let preview : () -> Content;

    let onAppearActon: (() -> Void)?;
    let onDisappearActon: (() -> Void)?;

    var cornerRadius: CGFloat = 10
    @Binding var alertInfo: TrashAlertInfo?
    @Binding var showTrashAlert: Bool
    @EnvironmentObject var sidebarModel: FTSidebarViewModel;
    @EnvironmentObject var sidebarItem: FTSideBarItem;
    @EnvironmentObject var contextualMenuViewModel: FTSidebarItemContextualMenuVM;

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: preview())

        // Create and add a UIContextMenuInteraction to the view
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.addInteraction(interaction)

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
    class FTContextMenuCoordinator: NSObject, UIContextMenuInteractionDelegate {
        let representView: FTSideBarItemContextMenuPreview;

        init(representView view: FTSideBarItemContextMenuPreview) {
            representView = view;
        }

        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            // Return the configuration for the context menu
            return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                return nil
            }) { [weak self] _ in
                guard let strongSelf = self else {
                    return UIMenu();
                }

                let _sidebarModel = strongSelf.representView.sidebarModel;
                let _sidebarItem = strongSelf.representView.sidebarItem;
                let _contextualMenuViewModel = strongSelf.representView.contextualMenuViewModel

                let menuItems = _sidebarModel.getContextualOptionsForSideBarType(_sidebarItem.type);
                var elements = [UIMenuElement]();
                var actions = [UIAction]();
                menuItems.forEach { menuOption in
                    let action1 = UIAction(title:menuOption.displayTitle,
                                           image: UIImage(icon: menuOption.icon),
                                           discoverabilityTitle: menuOption.displayTitle, attributes: menuOption.isDestructiveOption ? .destructive : .standard) { [weak self] _ in
                        guard let strongSelf = self else {
                            return;
                        }

                        strongSelf.representView.onDisappearActon?();
                        if menuOption == .trashCategory || menuOption == .emptyTrash || menuOption == .deleteTag {
                            strongSelf.representView.showTrashAlert = true
                            strongSelf.setAlertInfoForOption(menuOption)
                        } else {
                            _contextualMenuViewModel.sideBarItem = _sidebarItem
                            _contextualMenuViewModel.performAction = menuOption
                        }
                        _sidebarModel.trackEventForLongPressOptions(item: _sidebarItem, option: menuOption)
                    }
                    actions.append(action1);
                   // elements.append(UIMenu(title: "", options: .displayInline, children: actions));
                }
                return UIMenu(title: "", children: actions)
            }
        }

        private func targettedPreview(_ interaction: UIContextMenuInteraction) -> UITargetedPreview? {
            if let _parentPreview = interaction.view {

                let parameters = UIPreviewParameters();
                parameters.backgroundColor = .clear;
                let frame = _parentPreview.bounds;
                let path = UIBezierPath(roundedRect: frame, cornerRadius:self.representView.cornerRadius)
                parameters.visiblePath = path;

                let targettedPreview = UITargetedPreview(view: _parentPreview, parameters: parameters);
                return targettedPreview;
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

        private func setAlertInfoForOption(_ option: FTSidebarItemContextualOption) {
            if option == .emptyTrash {
                self.representView.alertInfo = TrashAlertInfo(title: "trash.alert.title".localized,
                                                              message: "",
                                                              type: TrashAlertInfo.TrashType.emptyTrash(item: self.representView.sidebarItem))
            } else if option == .trashCategory {
                let title = String(format: "shelf.deleteCategoryAlert.title".localized, "\"\(self.representView.sidebarItem.title)\"")
                let message = NSLocalizedString("shelf.deleteCategoryAlert.message", comment: "The items in this category will be placed in the Trash.")
                self.representView.alertInfo = TrashAlertInfo(title: title, message: message, type: TrashAlertInfo.TrashType.category(item: self.representView.sidebarItem))
            } else if option == .deleteTag {
                let title = String(format: "tags.delete.alert.title".localized, "\"\(self.representView.sidebarItem.title)\"")
                let message = "tags.delete.alert.message".localized
                self.representView.alertInfo = TrashAlertInfo(title: title,
                                                              message: message,
                                                              type: TrashAlertInfo.TrashType.tags(item: self.representView.sidebarItem))
            }
        }
    }
}
