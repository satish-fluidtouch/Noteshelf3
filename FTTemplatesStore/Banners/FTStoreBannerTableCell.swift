//
//  FTStoreBannerTableCell.swift
//  FTTemplatesStore
//
//  Created by Siva on 05/05/23.
//

import UIKit

class FTStoreBannerTableCell: UITableViewCell {
    @IBOutlet private weak var collectionView: UICollectionView!
    private var templatesStoreInfo: StoreInfo!
    private let padding = 40.0
    private var dataSource: TemplatesDatasource!
    private var snapshot = TemplatesSnapshot()
    private var timer: Timer!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        initializeCollectionView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func prepareCellWith(templatesStoreInfo: StoreInfo) {
        self.templatesStoreInfo = templatesStoreInfo
        self.createAndApplySnapshot()
    }
}

// MARK: - Private Methods
private extension FTStoreBannerTableCell {

    func initializeCollectionView() {
        FTStoreBannerCollectionCell.registerWithCollectionView(collectionView)
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        self.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, template in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreBannerCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreBannerCollectionCell else {
                fatalError("can't dequeue CustomCell")
            }
            cell.prepareCellWith(templateInfo: template)

            return cell
        })
    }

    func createAndApplySnapshot() {
        guard self.dataSource != nil else { return }

        self.snapshot.deleteAllItems()

        if templatesStoreInfo.discoveryItems.isEmpty {
            self.dataSource.apply(self.snapshot, animatingDifferences: true)
            return
        }
        let type = templatesStoreInfo.sectionType
        self.snapshot.appendSections([type])
        self.snapshot.appendItems(templatesStoreInfo.discoveryItems, toSection: type)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
    }

    // Move to the next cell
    @objc func scrollToNextCell() {
        let contentOffset = collectionView.contentOffset
        let centerX = collectionView.bounds.size.width / 2 + contentOffset.x
        let centerY = collectionView.bounds.size.height / 2 + contentOffset.y
        let centerPoint = CGPoint(x: centerX, y: centerY)
        if let indexPath = collectionView.indexPathForItem(at: centerPoint) {
            // IndexPath of the currently centered cell
            let centeredCellIndexPath = indexPath
            let nextIndex = centeredCellIndexPath.row + 1
            if nextIndex < collectionView.numberOfItems(inSection: 0) {
                let nextIndexPath = IndexPath(item: nextIndex, section: 0)
                collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
            } else {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                collectionView.scrollToItem(at: firstIndexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FTStoreBannerTableCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items = self.templatesStoreInfo.discoveryItems
        FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: indexPath.row))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = FTStoreConstants.Banner.calculateSizeFor(view: self)
        return CGSize(width: size.width, height: size.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTStoreConstants.Banner.interItemSpacing
    }

}
