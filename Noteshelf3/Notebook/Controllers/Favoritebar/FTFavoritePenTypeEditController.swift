//
//  FTFavoritePenTypeEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 07/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

protocol FTFavoritePenTypeUpdateDelegate: NSObjectProtocol {
    func didChangePenType(_ type: FTPenType)
}

class FTFavoritePenTypeEditController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    private let cellIdentifier = "PenType"

    weak var delegate: FTFavoritePenTypeUpdateDelegate?

    private var penTypeOrder: [FTPenType] {
        var penTypes: [FTPenType] = []
        if let parent = self.parent as? FTFavoriteEditViewController {
            let selSegment = parent.getCurrentSelectedSegment()
            if selSegment == .pen {
                penTypes = FTRackType.pen.penTypes
            } else {
                penTypes = FTRackType.highlighter.penTypes
            }
        }
        return penTypes
    }

    private var manager: FTFavoritePensetManager {
        guard let parent = self.parent as? FTFavoriteEditViewController else {
            fatalError("Hanlde hierarchy chnages")
        }
        return parent.manager
    }

    private var currentPenset: FTPenSetProtocol {
        guard let parent = self.parent as? FTFavoriteEditViewController else {
            fatalError("Hanlde hierarchy chnages")
        }
        let selSegment = parent.getCurrentSelectedSegment()
        return self.manager.fetchCurrentPenset(for: selSegment)
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
        cell.configure(penType: penType, currentPenSet: self.currentPenset, color: self.currentPenset.color)
        cell.contentView.transform = .identity
        cell.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let penType = self.penTypeOrder[indexPath.item]
        let currentPenSet = self.currentPenset
        if currentPenSet.type == penType {
            return
        }
        currentPenSet.type = penType
        self.manager.saveCurrentSelection(penSet: currentPenSet)
        self.delegate?.didChangePenType(penType)
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
        let cellSpacing = 4
        let totalWidth = cellDimension * cellCount
        let totalSpacingWidth = cellSpacing * (cellCount - 1)
        let horizantalInset = (collectionView.frame.width - CGFloat(totalWidth + totalSpacingWidth)) / 2
        let vertInset = (collectionView.frame.height - CGFloat(cellDimension))/2
        return UIEdgeInsets(top: vertInset, left: horizantalInset, bottom: vertInset, right: horizantalInset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}
