//
//  FTFavoritePenTypeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 07/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritePenTypeEditController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    private let cellIdentifier = "PenType"

    var rack = FTRackData(type: .pen, userActivity: nil)

    private var type: FTRackType {
        return self.rack.type
    }

    private var penTypeOrder: [FTPenType] {
        return self.type.penTypes
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.register(UINib.init(nibName: "FTPenTypeCollectionViewCell",
                                                bundle: Bundle(for: FTFavoritePenTypeEditController.self)), forCellWithReuseIdentifier: cellIdentifier)
    }

    func reloadPenTypes() {
        self.collectionView.reloadData()
    }
}

// MARK: - DataSource
extension FTFavoritePenTypeEditController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.penTypeOrder.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? FTPenTypeCollectionViewCell else {
            fatalError("Programmer error, Couldnot find FTPenTypeCollectionViewCell")
        }
        let penType = self.penTypeOrder[indexPath.item]
        cell.configure(penType: penType, currentPenSet: self.rack.currentPenset, color: self.rack.currentPenset.color)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let penType = self.penTypeOrder[indexPath.item]
        let currentPenSet = self.rack.currentPenset
        if currentPenSet.type == penType {
            return
        }
        self.rack.currentPenset.type = penType
        self.rack.saveCurrentSelection()

        collectionView.indexPathsForVisibleItems.forEach({ (penTypeIndexPath) in
            if let cell = collectionView.cellForItem(at: penTypeIndexPath) as? FTPenTypeCollectionViewCell {
                let penType = self.penTypeOrder[penTypeIndexPath.item]
                cell.configure(penType: penType, currentPenSet: currentPenSet, color: currentPenSet.color)
            }
        })

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            collectionView.layoutIfNeeded()
        })
    }
}

extension FTFavoritePenTypeEditController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellDimension = 72
        let cellCount = self.penTypeOrder.count
        let cellSpacing = 8
        let totalWidth = cellDimension * cellCount
        let totalSpacingWidth = cellSpacing * (cellCount - 1)
        let horizantalInset = (collectionView.frame.width - CGFloat(totalWidth + totalSpacingWidth)) / 2
        let vertInset = (collectionView.frame.height - CGFloat(cellDimension))/2
        return UIEdgeInsets(top: vertInset, left: horizantalInset, bottom: vertInset, right: horizantalInset)
    }
}
