//
//  FTStorePlannerTableCell.swift
//  FTTemplates
//
//  Created by Siva on 16/02/23.
//

import UIKit
import Combine

internal typealias TemplatesDatasource = UICollectionViewDiffableDataSource<Int, DiscoveryItem>
internal typealias TemplatesSnapshot = NSDiffableDataSourceSnapshot<Int, DiscoveryItem>

class FTStorePlannerTableCell: UITableViewCell {
    @IBOutlet private weak var collectionView: UICollectionView!

    private var templatesStoreInfo: StoreInfo!
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
private extension FTStorePlannerTableCell {

    func initializeCollectionView() {
        FTStorePlannerCollectionCell.registerWithCollectionView(collectionView)
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        self.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, template in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStorePlannerCollectionCell.reuseIdentifier, for: indexPath) as? FTStorePlannerCollectionCell else {
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

}

// MARK: - UICollectionViewDelegate
extension FTStorePlannerTableCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items = self.templatesStoreInfo.discoveryItems
        FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: indexPath.row))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = FTStoreConstants.StoreTemplate.size
        return CGSize(width: size.width, height: size.height + FTStoreConstants.StoreTemplate.extraHeightPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTStoreConstants.StoreTemplate.innerItemSpacing
    }

}
