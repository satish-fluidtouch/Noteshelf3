//
//  FTFavoritebarViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritebarViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var sizeIndicator: UIButton!
    @IBOutlet private weak var sizeDisplayView: UIView!
    @IBOutlet private weak var sizeDisplayWidthConstraint: NSLayoutConstraint?

    private var favorites: [FTPenSetProtocol] = []
    private let manager = FTFavoritePensetManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.favorites = manager.fetchFavorites()
        self.showSizeDisplay(10.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func sizeIndicatorTapped(_ sender: Any) {
    }
}

private extension FTFavoritebarViewController {
    func showSizeDisplay(_ size: CGFloat) {
        self.sizeDisplayWidthConstraint?.constant = 8
        self.sizeDisplayView.layoutIfNeeded()
        self.sizeDisplayView.layer.cornerRadius = sizeDisplayView.frame.height/2
    }

     func updateSelectionStatus(cell: FTFavoritePenCollectionViewCell?) {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            for index in self.favorites.indices where (self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell)?.isFavoriteSelected == true {
                let prevCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell
                prevCell?.isFavoriteSelected = false
                break
            }
            cell?.isFavoriteSelected = true
        }, completion: { (_) in
        })
    }
}

extension FTFavoritebarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = ((self.favorites.count/7) + 1) * 7
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTFavoritePenCollectionViewCell", for: indexPath) as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }
        if indexPath.row < self.favorites.count {
            let favorite = self.favorites[indexPath.row]
            cell.configure(favorite: favorite, currentPenset: FTDefaultPenSet())
        } else {
            cell.configureEmptySlot()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }

        if(indexPath.row < self.favorites.count) {
            if(cell.isFavoriteSelected) {
                // to show edit mode UI here
            } else {
                self.updateSelectionStatus(cell: cell)
            }
        } else {

        }
    }
}
