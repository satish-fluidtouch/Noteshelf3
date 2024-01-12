//
//  FTStoreTemplatesViewController.swift
//  TempletesStore
//
//  Created by Siva on 08/05/23.
//

import UIKit

class FTStoreTemplatesViewController: UIViewController {
    private var discoveryItem: DiscoveryItem!
    private let cellPadding: CGFloat = 20
    private var currentSize: CGSize = .zero
    private let viewModel = FTStoreTemplatesViewModel()
    @IBOutlet weak var collectionView: UICollectionView!
    private var actionManager: FTStoreActionManager?

    class func controller(discoveryItem: DiscoveryItem, actionManager: FTStoreActionManager?) -> FTStoreTemplatesViewController {
        guard let vc = UIStoryboard.init(name: "FTTemplatesStore", bundle: storeBundle).instantiateViewController(withIdentifier: "FTStoreTemplatesViewController") as? FTStoreTemplatesViewController else {
            fatalError("FTStoreTemplatesViewController not found")
        }
        vc.discoveryItem = discoveryItem
        vc.actionManager = actionManager
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = discoveryItem.title
        viewModel.items = discoveryItem.items!
        initializeCollectionView()
        viewModel.loadTemplates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFrame()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {[weak self](_) in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }, completion: { (_) in
        })
    }

    private func updateFrame() {
        let frame = self.view.frame.size;
        if currentSize.width != frame.width {
            currentSize = frame
            self.collectionView.reloadData()
        }
    }

    func initializeCollectionView() {
        FTStorePlannerCollectionCell.registerWithCollectionView(collectionView)
        FTStoreJournalsCollectionCell.registerWithCollectionView(collectionView)
        collectionView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0)
        self.collectionView.delegate = self
        self.configureDatasource()
    }

    func configureDatasource() {
        viewModel.dataSource = TemplatesDatasource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStorePlannerCollectionCell.reuseIdentifier, for: indexPath) as? FTStorePlannerCollectionCell else {
                fatalError("can't dequeue FTStoreTemplateCollectionCell")
            }
            if item.type == FTDiscoveryItemType.diary.rawValue {
                guard let diaryCell = collectionView.dequeueReusableCell(withReuseIdentifier: FTStoreJournalsCollectionCell.reuseIdentifier, for: indexPath) as? FTStoreJournalsCollectionCell else {
                    fatalError("can't dequeue FTStoreJournalsCollectionCell")
                }
                diaryCell.prepareCellWith(templateInfo: item)
                return diaryCell

            } else {
                cell.prepareCellWith(templateInfo: item)
            }
            return cell
        })

    }

    private func columnWidthForSize(_ size: CGSize) -> CGFloat {
        let noOfColumns = self.noOfColumnsForCollectionViewGrid()
        let totalSpacing = FTStoreConstants.Template.interItemSpacing * CGFloat(noOfColumns - 1)
        let itemWidth = (size.width - totalSpacing - (FTStoreConstants.Template.gridHorizontalPadding * 2)) / CGFloat(noOfColumns)
        return itemWidth
    }

    private func presentTemplatePreviewFor(templates: [TemplateInfo], selectedIndex: Int) {
        FTTemplatesPageViewController.presentFromViewController(self, actionManager: actionManager, templates: templates, selectedIndex: selectedIndex);
    }
}

// MARK: - UICollectionViewDelegate
extension FTStoreTemplatesViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let items = discoveryItem.items {
            self.presentTemplatePreviewFor(templates: items, selectedIndex: indexPath.row)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columnWidth = columnWidthForSize(self.view.frame.size)
       let size = CGSize(width: columnWidth, height: ((columnWidth) / FTStoreConstants.Template.potraitAspectRation) + FTStoreConstants.Template.extraHeightPadding)
        let item = viewModel.itemInfo(at: indexPath)
        if item?.type == FTDiscoveryItemType.diary.rawValue {
            return CGSize(width: FTStoreConstants.DigitalDiary.size.width, height: FTStoreConstants.DigitalDiary.size.height + FTStoreConstants.DigitalDiary.extraHeightPadding)
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: FTStoreConstants.Template.interItemSpacing, bottom: 0, right: FTStoreConstants.Template.interItemSpacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 32.0
    }

}
