//
//  FTFavoritebarViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/09/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFavoritebarViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var sizeIndicator: UIButton!
    @IBOutlet private weak var sizeDisplayView: UIView!
    @IBOutlet private weak var sizeDisplayWidthConstraint: NSLayoutConstraint?

    // Drag preview related
    @IBOutlet private weak var dragPreview: UIView!
    @IBOutlet private weak var dragContentPreview: UIView!
    @IBOutlet private weak var previewShadow: UIImageView!
    @IBOutlet private weak var previewOverLay: UIImageView!
    @IBOutlet private weak var previewMask: UIImageView!
    @IBOutlet private weak var previewEffect: UIImageView!
    @IBOutlet private weak var previewOverlayBottomConstraint: NSLayoutConstraint!

    private var favorites: [FTPenSetProtocol] = []
    private let manager = FTFavoritePensetManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addVisualEffectBlur(cornerRadius: 19.0)
        self.configureDragAndDrop()
        self.favorites = manager.fetchFavorites()
        self.showSizeDisplay(10.0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func sizeIndicatorTapped(_ sender: Any) {
    }

    func reloadFavoritesData() {
        self.collectionView.reloadData()
    }
}

private extension FTFavoritebarViewController {
    func configureDragAndDrop() {
        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
        self.collectionView.dragInteractionEnabled = true
        self.collectionView.isPagingEnabled = true
    }

    func getTheRotationAngleForDragPreviewContent() -> CGFloat {
        let placement = FTShortcutPlacement.getSavedPlacement()
        var angle: CGFloat = 0.0
        if placement.isLeftPlacement() {
            angle = -.pi/2.0
        } 
        return angle
    }

    func handlePenTypeCellTransformation(cell: UICollectionViewCell) {
        let placement = FTShortcutPlacement.getSavedPlacement()
        cell.contentView.alpha = 0.0
        cell.contentView.transform = .identity
        if placement.isLeftPlacement() {
            cell.contentView.transform = CGAffineTransform(rotationAngle: .pi)
        }
        cell.contentView.alpha = 1.0
    }

    func showSizeDisplay(_ size: CGFloat) {
        self.sizeDisplayWidthConstraint?.constant = 8
        self.sizeDisplayView.layoutIfNeeded()
        self.sizeDisplayView.layer.cornerRadius = sizeDisplayView.frame.height/2
    }

     func updateSelectionStatus(cell: FTFavoritePenCollectionViewCell?) {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            for index in self.favorites.indices where (self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell)?.isFavoriteSelected == true {
                let prevCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell
                prevCell?.isFavoriteSelected = false
                break
            }
            cell?.isFavoriteSelected = true
        }, completion: { (_) in
        })
    }
}

extension FTFavoritebarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = ((self.favorites.count/7) + 1) * 7
        return count
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }
        if indexPath.row < self.favorites.count {
            let favorite = self.favorites[indexPath.row]
            cell.configure(favorite: favorite, currentPenset: FTDefaultPenSet())
        } else {
            cell.configureEmptySlot()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTFavoritePenCollectionViewCell", for: indexPath)
        self.handlePenTypeCellTransformation(cell: cell)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell else {
            fatalError("Programmer error - FTFavoritePenCollectionViewCell not found")
        }

        if(indexPath.row < self.favorites.count) {
            if(cell.isFavoriteSelected) {
                // to show edit mode UI here
            } else {
                self.updateSelectionStatus(cell: cell)
            }
        } else {

        }
    }
}

extension FTFavoritebarViewController: UICollectionViewDragDelegate {
    private func updateDragContentPreview(penSet: FTPenSetProtocol, isSelectedPenSet: Bool) {
        self.dragPreview.layer.cornerRadius = self.dragPreview.frame.size.height / 2.0
        self.previewShadow.image = UIImage(named: penSet.type.favShadowImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)
        self.previewMask.image = UIImage(named: penSet.type.favMaskImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)
        self.previewOverLay.image = UIImage(named: penSet.type.favOverlayImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        self.previewOverLay.tintColor = UIColor(hexString: penSet.color)
        self.previewEffect.image = UIImage(named: penSet.type.favEffectImageName, in: Bundle(for: FTFavoritePenCollectionViewCell.self), compatibleWith: nil)
        self.previewOverlayBottomConstraint.constant = 0.0
        if isSelectedPenSet {
            self.previewOverlayBottomConstraint.constant = -12.0
        }

        let maskLayerPreview = CAShapeLayer()
        maskLayerPreview.path = UIBezierPath(roundedRect: CGRect.init(x: 0, y: 0, width: self.dragContentPreview.bounds.width, height: self.dragPreview.bounds.height + 20.0), byRoundingCorners: UIRectCorner.topLeft.union(.topRight), cornerRadii: CGSize(width: self.dragContentPreview.frame.width / 2, height: self.dragContentPreview.frame.height / 2)).cgPath;
        self.dragContentPreview.layer.mask = maskLayerPreview
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if self.presentedViewController != nil {
            return []
        }
        if indexPath.item < self.favorites.count, let cell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell {
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear

            let item = self.favorites[indexPath.row]
            self.updateDragContentPreview(penSet: item, isSelectedPenSet: cell.isFavoriteSelected)
            let itemProvider = NSItemProvider(object: item);
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            let rotationAngle = self.getTheRotationAngleForDragPreviewContent()
            dragItem.previewProvider = { () -> UIDragPreview? in
                self.dragPreview.alpha = 1.0
                self.dragContentPreview.transform = .identity
                self.dragContentPreview.transform = CGAffineTransform(rotationAngle: rotationAngle)
                let dragPreview = UIDragPreview(view: self.dragPreview)
                return dragPreview
            }

            return [dragItem]
        }
        return []
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell: FTFavoritePenCollectionViewCell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell {
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            let dragPreview = UIDragPreviewParameters.init()
            let itemFrame = cell.viewPenImage.frame
            dragPreview.visiblePath = UIBezierPath.init(roundedRect: itemFrame, cornerRadius: itemFrame.size.height/2.0)
            dragPreview.backgroundColor = UIColor.clear
            return dragPreview
        }
        return UIDragPreviewParameters.init()
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        if self.presentedViewController != nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

//MARK: - UICollectionViewDropDelegate
extension FTFavoritebarViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if collectionView.hasActiveDrag && session.localDragSession != nil {
            for item in session.items where item.localObject is FTPenSet {
                return true
            }
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell: FTFavoritePenCollectionViewCell = collectionView.cellForItem(at: indexPath) as? FTFavoritePenCollectionViewCell {
            cell.backgroundColor = UIColor.clear
            cell.contentView.backgroundColor = UIColor.clear
            let dropPreview = UIDragPreviewParameters.init()
            dropPreview.backgroundColor = UIColor.clear
            let itemFrame = cell.viewPenImage.frame
            dropPreview.visiblePath = UIBezierPath.init(roundedRect: itemFrame, cornerRadius: itemFrame.size.height/2.0)
            return dropPreview
        }
        return UIDragPreviewParameters.init()
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if destinationIndexPath != nil, let index = destinationIndexPath?.item, collectionView.hasActiveDrag, index < self.favorites.count  {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .cancel)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(item: row - 1, section: 0)
        }
        self.dragPreview.alpha = 0.0
        if coordinator.proposal.operation == .move {
            self.reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
    }

    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath, let penSet = item.dragItem.localObject as? FTPenSet, destinationIndexPath.item < self.favorites.count, sourceIndexPath.item < self.favorites.count {
            collectionView.performBatchUpdates({
                self.favorites.remove(at: sourceIndexPath.item)
                self.favorites.insert(penSet, at: destinationIndexPath.item)
                manager.saveFavorites()
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: nil)
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}
