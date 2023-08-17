//
//  FTCategoryResultSectionCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCategoryResultSectionCell: FTBaseResultSectionCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }
}

extension FTCategoryResultSectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize
        if isRegular {
            cellSize = GlobalSearchConstants.CategoryCellSize.regular
        } else {
            cellSize = GlobalSearchConstants.CategoryCellSize.compact
        }
        return cellSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let space: CGFloat
        if isRegular {
            space = GlobalSearchConstants.ResultItemSpace.regular
        } else {
            space = GlobalSearchConstants.ResultItemSpace.compact
        }
        return space
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let insets: UIEdgeInsets
        if isRegular {
            insets = GlobalSearchConstants.Insets.regular
        } else {
            insets = GlobalSearchConstants.Insets.compact
        }
        return insets
    }
}

extension FTCategoryResultSectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contentSection.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gridItem = self.contentSection.items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSearchResultCategoryCell", for: indexPath)
        if let cell = cell as? FTSearchResultCategoryCell, let resultItem = gridItem as? FTSearchResultCategoryProtocol {
            cell.configureCellWithItem(resultItem, searchKey: self.contentSection.searchKey)
        }
        return cell
    }
}

extension FTCategoryResultSectionCell {
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let gridItem = self.contentSection.items[indexPath.row]
        
        var actions = [UIMenuElement]()
        var staticActions = [UIMenuElement]()
        var contextMenu : UIContextMenuConfiguration?;
        let identifier = indexPath as NSIndexPath
        
        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            //=========================================
            let openAction = UIAction(title: NSLocalizedString("Open", comment: "Open")) { [weak self] _ in
                self?.delegate?.didSelectItem(gridItem)
            }
            staticActions.append(openAction)

            let openInWindowAction = UIAction(title: NSLocalizedString("OpenInNewWindow", comment: "Open in New Window")) {[weak self] _ in
                if let resultItem = gridItem as? FTSearchResultCategoryProtocol, let shelf = resultItem.shelfItemCollection {
                    self?.delegate?.performContextMenuOperation(for: shelf,
                                                                pageIndex: nil,
                                                                type: .openInNewWindow)
                }
            }
            staticActions.append(openInWindowAction)

            #if targetEnvironment(macCatalyst)
                actions.append(contentsOf: staticActions)
            #else
                actions.append(UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: staticActions))
            #endif
            
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: actions)
        }
       
        contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: actionProvider)
        
        return contextMenu;

    }
}
