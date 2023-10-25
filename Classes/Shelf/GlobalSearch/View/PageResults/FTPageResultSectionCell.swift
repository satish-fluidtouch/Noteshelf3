//
//  FTPageResultSectionCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


class FTPageResultSectionCell: FTBaseResultSectionCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }

    override func getAnimationInfo(for indexPath: IndexPath) -> FTOpenAnimationInfo? {
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? FTSearchResultPageCell {
            let imageFrame = CGRect.init(x: cell.frame.origin.x + cell.imageViewPage!.frame.origin.x + self.frame.origin.x, y: cell.frame.origin.y + cell.imageViewPage!.frame.origin.y + self.frame.origin.y, width: cell.imageViewPage!.frame.width, height: cell.imageViewPage!.frame.height)
            let animateInfo = FTOpenAnimationInfo()
            animateInfo.imageFrame = imageFrame
            animateInfo.shelfImage = cell.imageViewPage?.image
            return animateInfo
        }
        return nil
    }
}

extension FTPageResultSectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize
        if isRegular {
            cellSize = GlobalSearchConstants.PageCellSize.regular
        } else {
            cellSize = GlobalSearchConstants.PageCellSize.compact
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

extension FTPageResultSectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contentSection.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gridItem = self.contentSection.items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSearchResultPageCell", for: indexPath)
        if let cell = cell as? FTSearchResultPageCell{
            cell.transform = CGAffineTransform.identity;
            cell.imageViewPage?.contentMode = UIView.ContentMode.scaleAspectFill
            cell.imageViewPage?.image = UIImage(named: "finder-empty-pdf-page")

            if let contentSection = self.contentSection as? FTSearchSectionContentProtocol {
                if let item = contentSection.items[indexPath.row] as? FTSearchResultPageProtocol {
                    if let associatedPage = contentSection.associatedPage(forItem: item) {
                        cell.pageLabel?.text = "globalSearch.page".localized + " \(associatedPage.pageIndex() + 1)"
                        if let pageItem = gridItem as? FTSearchResultPageProtocol, (associatedPage as? FTPageProtocol)?.parentDocument != nil {
                            (associatedPage as? FTNoteshelfPage)?.searchingInfo = pageItem.searchingInfo
                            var size = isRegular ? GlobalSearchConstants.PageThumbnailSize.Portrait.regular : GlobalSearchConstants.PageThumbnailSize.Portrait.compact
                            if associatedPage.pdfPageRect.size.width > associatedPage.pdfPageRect.height {
                                size = isRegular ? GlobalSearchConstants.PageThumbnailSize.Landscape.regular : GlobalSearchConstants.PageThumbnailSize.Landscape.compact
                            }
                            let aspectFitSize = CGSize.aspectFittedSize(associatedPage.pdfPageRect.size, max: size)
                            cell.pdfSize = aspectFitSize
                            cell.setThumbnailImage(usingPage: associatedPage)
                        }
                    }
                    else{
                        cell.pageLabel?.text = ""
                    }
                }
            }
        }
        return cell
    }
}
