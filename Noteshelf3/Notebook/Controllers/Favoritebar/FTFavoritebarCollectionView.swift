//
//  FTFavoritebarCollectionView.swift
//  Noteshelf3
//
//  Created by Narayana on 19/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
 
protocol FTFavoritebarDelegate: AnyObject {
    func updateSizeDisplay()
    func displayMaximumFavoritesAlert()
    func getFavorites() -> [FTPenSetProtocol]
    func saveFavorites(_ favorites: [FTPenSetProtocol])
    func fetchCurrentPenset() -> FTPenSetProtocol
    func saveCurrentSelection(penset: FTPenSetProtocol)
    func getSavedPlacement() -> FTShortcutPlacement?
    func showFavoriteEditScreen(with penset: FTPenSetProtocol, sourceView: UIView)
}

class FTFavoritebarCollectionView: UICollectionView {
    var isDisplayedEditPenRack: Bool = false
    var isAddingNewPenSet: Bool = false
    var editFavoriteCurrentIndex: Int?

    weak var interactionDelegate: FTFavoritebarDelegate?
    var mode: FTCollectionViewMode = .toolbar

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.dataSource = self
        self.delegate = self
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    private var favorites: [FTPenSetProtocol] {
        return self.interactionDelegate?.getFavorites() ?? []
    }
}

private extension FTFavoritebarCollectionView {
   func getCurrentPenset() -> FTPenSetProtocol {
       return self.interactionDelegate?.fetchCurrentPenset() ?? FTDefaultPenSet()
    }
    
    func handlePenTypeCellTransformation(cell: UICollectionViewCell) {
        if let placement = self.interactionDelegate?.getSavedPlacement() {
            cell.contentView.alpha = 0.0
            cell.contentView.transform = .identity
            if placement.isLeftPlacement() {
                cell.contentView.transform = CGAffineTransform(rotationAngle: .pi)
            }
            cell.contentView.alpha = 1.0
        }
    }
    
    func updateSelectionStatus(cell: FTFavoritePenCollectionViewCell?) {
       UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
           for index in self.favorites.indices where (self.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell)?.isFavoriteSelected == true {
               let prevCell = self.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell
               prevCell?.isFavoriteSelected = false
               break
           }
           cell?.isFavoriteSelected = true
       }, completion: { (_) in
       })
   }
}

extension FTFavoritebarCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = ((self.favorites.count/7) + 1) * 7
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }
        cell.addFavoriteImageView.isHidden = true
        if indexPath.row < self.favorites.count {
            let favorite = self.favorites[indexPath.row]
            cell.configure(favorite: favorite, currentPenset: self.getCurrentPenset())
        } else {
            cell.configureEmptySlot()
            if indexPath.row == self.favorites.count {
                cell.addFavoriteImageView.isHidden = false
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTFavoritePenCollectionViewCell", for: indexPath)
        self.handlePenTypeCellTransformation(cell: cell)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }
        if(indexPath.row < self.favorites.count) {
            editFavoriteCurrentIndex = indexPath.row
            let favorite = self.favorites[indexPath.row]
            self.interactionDelegate?.saveCurrentSelection(penset: favorite)
            if(cell.isFavoriteSelected) {
                self.interactionDelegate?.showFavoriteEditScreen(with: favorite, sourceView: cell)
            } else {
                if(self.isDisplayedEditPenRack) {
                    self.interactionDelegate?.showFavoriteEditScreen(with: favorite, sourceView: cell)
                }
                self.updateSelectionStatus(cell: cell)
            }
            self.interactionDelegate?.updateSizeDisplay()
        } else if indexPath.row == self.favorites.count && !self.isAddingNewPenSet {
            if indexPath.row < maximumSupportedFavorites {
                editFavoriteCurrentIndex = indexPath.row
                cell.addFavoriteImageView.isHidden = true
                self.isAddingNewPenSet = true
                let currentPenset = self.getCurrentPenset()
                var curFavorites = self.favorites
                curFavorites.append(currentPenset)
                self.interactionDelegate?.saveFavorites(curFavorites)
                cell.configure(favorite: currentPenset, currentPenset: currentPenset)
                self.updateSelectionStatus(cell: cell)
                self.interactionDelegate?.showFavoriteEditScreen(with: currentPenset, sourceView: cell)
            } else {
                self.isAddingNewPenSet = false
                self.interactionDelegate?.displayMaximumFavoritesAlert()
            }
        }
    }
}
