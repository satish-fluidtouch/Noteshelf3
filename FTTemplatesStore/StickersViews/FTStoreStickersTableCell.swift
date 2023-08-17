//
//  FTStoreStickersTableCell.swift
//  TempletesStore
//
//  Created by Siva on 20/04/23.
//

import UIKit

class FTStoreStickersTableCell: UITableViewCell {
    @IBOutlet private weak var collectionView: UICollectionView!

    private var templatesStoreInfo: StoreInfo!
    private let padding = 40.0
    private var dataSource: TemplatesDatasource!
    private var snapshot = TemplatesSnapshot()

    override func awakeFromNib() {
        super.awakeFromNib()
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
private extension FTStoreStickersTableCell {
    func initializeCollectionView() {
        FTStoreStickersCollectionCell.registerWithCollectionView(collectionView)
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        self.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, template in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreStickersCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreStickersCollectionCell else {
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
        let type = templatesStoreInfo.sectionType//FTStoreSectionType(rawValue: templatesStoreInfo.sectionType)!
        self.snapshot.appendSections([type])
        self.snapshot.appendItems(templatesStoreInfo.discoveryItems, toSection: type)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate
extension FTStoreStickersTableCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items = self.templatesStoreInfo.discoveryItems
        FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: indexPath.row))

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = FTStoreConstants.Sticker.calculateSizeFor(view: self)
        return CGSize(width: size.width, height: size.height + FTStoreConstants.Sticker.extraHeightPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTStoreConstants.Sticker.interItemSpacing
    }

}


