//
//  FTStoreStickersTableCell.swift
//  TempletesStore
//
//  Created by Siva on 20/04/23.
//

import UIKit
import Combine

class FTStoreStickersTableCell: UITableViewCell {
    @IBOutlet private weak var collectionView: UICollectionView!

    private var templatesStoreInfo: StoreInfo!
    private let padding = 40.0
    private var dataSource: TemplatesDatasource!
    private var snapshot = TemplatesSnapshot()
    private var actionStream: PassthroughSubject<FTStoreActions, Never>?
    override func awakeFromNib() {
        super.awakeFromNib()
        initializeCollectionView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func prepareCellWith(templatesStoreInfo: StoreInfo, actionStream: PassthroughSubject<FTStoreActions, Never>?) {
        self.templatesStoreInfo = templatesStoreInfo
        self.actionStream = actionStream
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
        self.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { [weak self] collectionView, indexPath, template in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreStickersCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreStickersCollectionCell else {
                fatalError("can't dequeue CustomCell")
            }
            cell.prepareCellWith(templateInfo: template, actionStream: self?.actionStream)
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
        var items = self.templatesStoreInfo.discoveryItems
        // Update sectionType to track events
        for (index, _) in items.enumerated() {
            items[index].sectionType = templatesStoreInfo.sectionType
        }
        actionStream?.send(.didTapOnDiscoveryItem(items: items, selectedIndex: indexPath.row))

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = FTStoreConstants.Sticker.calculateSizeFor(view: self)
        return CGSize(width: size.width, height: size.height + FTStoreConstants.Sticker.extraHeightPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTStoreConstants.Sticker.interItemSpacing
    }

}


