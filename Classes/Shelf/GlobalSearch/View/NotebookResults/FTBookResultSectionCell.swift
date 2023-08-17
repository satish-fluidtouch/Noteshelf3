//
//  FTBookResultSectionCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTBookResultSectionCell: FTBaseResultSectionCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }
    
    override func getAnimationInfo(for indexPath: IndexPath) -> FTOpenAnimationInfo? {
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? FTSearchResultBookCell {
            let imageFrame = CGRect.init(x: cell.frame.origin.x + cell.coverImageView!.frame.origin.x + self.frame.origin.x, y: cell.frame.origin.y + cell.coverImageView!.frame.origin.y + self.frame.origin.y, width: cell.coverImageView!.frame.width, height: cell.coverImageView!.frame.height)
            
            let animateInfo = FTOpenAnimationInfo()
            animateInfo.imageFrame = imageFrame
            animateInfo.shelfImage = cell.coverImageView.image
            return animateInfo
        }
        return nil
    }
}


extension FTBookResultSectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize
        if isRegular {
            cellSize = GlobalSearchConstants.BookCellSize.regular
        } else {
            cellSize = GlobalSearchConstants.BookCellSize.compact
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

extension FTBookResultSectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contentSection.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gridItem = self.contentSection.items[indexPath.row]
        var reqCell = UICollectionViewCell()
        if let resultItem = gridItem as? FTSearchResultBookProtocol,  let item = resultItem.shelfItem {
            let searchKey = self.contentSection.searchKey
            if item is FTGroupItemProtocol {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSearchResultGroupCell", for: indexPath) as? FTSearchResultGroupCell else {
                    fatalError("Programmer error, Could not find FTSearchResultGroupCell")
                }
                cell.configureCellWithItem(resultItem, searchKey: searchKey)
                reqCell = cell
            } else {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSearchResultBookCell", for: indexPath) as? FTSearchResultBookCell else {
                    fatalError("Programmer error, Could not find FTSearchResultBookCell")
                }
                cell.transform = CGAffineTransform.identity
                cell.configureCellWithItem(resultItem, searchKey: searchKey)
                reqCell = cell
            }
        }
        return reqCell
    }
}
