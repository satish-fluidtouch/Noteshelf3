//
//  FTStoreJournalTableCell.swift
//  FTTemplates
//
//  Created by Siva on 16/02/23.
//

import UIKit

class FTStoreJournalTableCell: UITableViewCell {
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
private extension FTStoreJournalTableCell {
    func initializeCollectionView() {
        FTStoreJournalsCollectionCell.registerWithCollectionView(collectionView)
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        self.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, template in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreJournalsCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreJournalsCollectionCell else {
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
extension FTStoreJournalTableCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var items = self.templatesStoreInfo.discoveryItems
        // Update sectionType to track events
        items[indexPath.row].sectionType = templatesStoreInfo.sectionType
        FTStoreActionManager.shared.actionStream.send(.didTapOnDiscoveryItem(items: items, selectedIndex: indexPath.row))

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: FTStoreConstants.DigitalDiary.size.width, height: FTStoreConstants.DigitalDiary.size.height + FTStoreConstants.DigitalDiary.extraHeightPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return FTStoreConstants.DigitalDiary.innerItemSpacing
    }
}


