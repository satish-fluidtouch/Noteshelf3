//
//  FTStoreCustomViewController+ContextMenu.swift
//  FTTemplatesStore
//
//  Created by Siva on 21/07/23.
//

import UIKit

// MARK: - contextMenuConfiguration
extension FTStoreCustomViewController {

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let sectionType = viewModel.dataSource.snapshot().sectionIdentifiers[indexPath.section]
        if sectionType == .noRecords {
            return nil
        }
        self.delegate?.customController(self, menuShown: true)
        let identifier = indexPath as NSIndexPath
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            let delete = UIAction(title: "templatesStore.custom.alert.remove".localized, image: UIImage(systemName: "trash")) { [weak self] _ in
                Task {
                    if let item = self?.viewModel.itemAt(index: indexPath.row) {
                        do {
                            try await FTStoreCustomTemplatesHandler.shared.removeFile(item: item)
                            self?.viewModel.loadTemplates()
                        } catch {
                            UIAlertController.showAlert(withTitle: "templatesStore.alert.error".localized, message: error.localizedDescription, from: self, withCompletionHandler: nil)
                        }
                    }
                }
            }
            delete.attributes = .destructive
            return UIMenu(title: "", children: [delete])
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreCustomCollectionCell else {
            return nil
        }
        cell.titleLabel?.isHidden = true
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell.thumbnail!, parameters: parameters)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.delegate?.customController(self, menuShown: false)
        guard let identifier = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: identifier) as? FTStoreCustomCollectionCell else {
            return nil
        }
        cell.titleLabel?.isHidden = false
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell, parameters: parameters)
    }
}
