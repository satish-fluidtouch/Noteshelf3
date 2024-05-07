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
    @IBOutlet private weak var sizeTapView: UIView!
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
    private var manager = FTFavoritePensetManager(activity: nil)

    private var isDisplayedEditPenRack: Bool = false
    private var isAddingNewPenSet: Bool = false
    private var editFavoriteCurrentIndex: Int?

    var activity: NSUserActivity?

    // Don't make below viewmodel weak as this is needed for eyedropper delegate to be implemented here(since we are dismissing edit controller)
    // Better solution would be appericiated
    internal var presetViewModel: FTFavoritePresetsViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addVisualEffectBlur(cornerRadius: 19.0)
        self.sizeTapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sizeTapped)))
        self.manager = FTFavoritePensetManager(activity: activity)
        self.configureDragAndDrop()
        self.favorites = manager.fetchFavorites()
        let curPenset = self.updateDisplay()
        self.scrollToCurrentPenset(curPenset)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if self.isDisplayedEditPenRack {
            self.dismiss(animated: false, completion: nil)
            self.handleEditScreenDismissal()
        }
    }

    @objc func sizeTapped() {
        let curPenset = self.getCurrentPenset()
        let sizeEditVc = FTFavoriteSizeEditController(size: curPenset.preciseSize, penType: curPenset.type, displayMode: .favoriteEdit, activity: self.activity)
        sizeEditVc.delegate = self
        sizeEditVc.ftPresentationDelegate.source = sizeTapView
        sizeEditVc.ftPresentationDelegate.sourceRect = sizeTapView.bounds
        self.ftPresentPopover(vcToPresent: sizeEditVc, contentSize: CGSize(width: 340.0, height: 80.0), hideNavBar: true)
    }

    func reloadFavoritesData() {
        self.collectionView.reloadData()
    }

    @discardableResult
    private func updateDisplay() -> FTPenSetProtocol {
        let currentPenset = self.getCurrentPenset()
        let penType = currentPenset.type
        let reqWidth = penType.getIndicatorSize(using: currentPenset.preciseSize).width
        self.sizeDisplayView?.isHidden = false
        self.sizeDisplayView?.backgroundColor = UIColor.label
        self.sizeDisplayWidthConstraint?.constant = reqWidth
        self.sizeDisplayView?.layer.cornerRadius = reqWidth*0.5
        self.sizeDisplayView?.layer.shouldRasterize = true
        self.sizeDisplayView?.layer.rasterizationScale = UIScreen.main.scale
        self.sizeDisplayView.layoutIfNeeded()
        return currentPenset
    }
}

private extension FTFavoritebarViewController {
     func displayMaximumFavoritesAlert() {
        let titleString = "MaximumFavoritesWarningTitle".localized
        let messageString = "MaximumFavoritesWarning".localized
        let okString = "OK".localized

        let alert = UIAlertController(title: titleString, message: messageString, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: okString, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func scrollToCurrentPenset(_ curPenset: FTPenSetProtocol) {
        if let curIndex = self.favorites.firstIndex(where: { fav in
            fav.isEqualTo(curPenset)
        }) {
            self.collectionView.scrollToItem(at: IndexPath(item: curIndex, section: 0), at: .centeredVertically, animated: false)
        }
    }
    
    func handleEditScreenDismissal() {
        let favTuple = self.manager.removeDuplicates(fromFavPenSets: self.favorites)
        self.favorites = favTuple.uniqueElements
        self.manager.saveFavorites(favorites)
        self.updateDisplay()
        if(favTuple.duplicateExists) {
            FTToastHostController.showToast(from: self, toastConfig: FTToastConfiguration(title: "AlreadyInFavorites".localized))
            self.reloadFavoritesData()
        } else {
            if(isAddingNewPenSet) {
                FTToastHostController.showToast(from: self, toastConfig: FTToastConfiguration(title: "FavoriteAddedNotification".localized))
                self.reloadFavoritesData()
            }
        }
        self.collectionView.isScrollEnabled = true
        self.isDisplayedEditPenRack = false
        self.isAddingNewPenSet = false
    }
    
    func configureDragAndDrop() {
        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
        self.collectionView.dragInteractionEnabled = true
        self.collectionView.isPagingEnabled = true
    }

    func getTheRotationAngleForDragPreviewContent() -> CGFloat {
        let placement = FTShortcutPlacement.getSavedPlacement(activity: self.activity)
        var angle: CGFloat = 0.0
        if placement.isLeftPlacement() {
            angle = -.pi/2.0
        } 
        return angle
    }

    func handlePenTypeCellTransformation(cell: UICollectionViewCell) {
        let placement = FTShortcutPlacement.getSavedPlacement(activity: self.activity)
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
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            for index in self.favorites.indices where (self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell)?.isFavoriteSelected == true {
                let prevCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell
                prevCell?.isFavoriteSelected = false
                break
            }
            cell?.isFavoriteSelected = true
        }, completion: { (_) in
        })
    }

    func showFavoriteEditScreen(with penset: FTPenSetProtocol, sourceView: UIView) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: FTFavoriteEditViewController.self))
        guard let controller  = storyboard.instantiateViewController(withIdentifier: "FTFavoriteEditViewController") as? FTFavoriteEditViewController else {
            fatalError("Proggrammer error")
        }
        controller.delegate = self
        controller.favorite = penset
        controller.manager = self.manager
        controller.activity = self.activity
        controller.ftPresentationDelegate.source = sourceView
        var rect = sourceView.bounds
        let placement = FTShortcutPlacement.getSavedPlacement(activity: self.activity)
        // To fix the arrow position
        let offset: CGFloat = 8.0
        if placement == .top || placement.isRightPlacement() {
            rect.origin.y += offset
        } else if placement.isLeftPlacement() {
            rect.origin.y -= offset
        }
        controller.ftPresentationDelegate.sourceRect = rect
        controller.ftPresentationDelegate.compactGrabFurther = false
        self.ftPresentPopover(vcToPresent: controller, contentSize: FTFavoriteEditViewController.contentSize, hideNavBar: true)
    }

    private func getCurrentPenset() -> FTPenSetProtocol {
        return self.manager.fetchCurrentPenset()
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
        cell.addFavoriteImageView.isHidden = true
        if indexPath.row < self.favorites.count {
            let favorite = self.favorites[indexPath.row]
            cell.configure(favorite: favorite, currentPenset: self.getCurrentPenset())
        } else {
            cell.configureEmptySlot()
            if indexPath.row == self.favorites.count {
                cell.addFavoriteImageView.isHidden = false
            }
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
            editFavoriteCurrentIndex = indexPath.row
            let favorite = self.favorites[indexPath.row]
            self.manager.saveCurrentSelection(penSet: favorite)
            if(cell.isFavoriteSelected) {
                self.showFavoriteEditScreen(with: favorite, sourceView: cell)
            } else {
                if(self.isDisplayedEditPenRack) {
                    self.showFavoriteEditScreen(with: favorite, sourceView: cell)
                }
                self.updateSelectionStatus(cell: cell)
            }
            self.updateDisplay()
        } else if indexPath.row == self.favorites.count && !self.isAddingNewPenSet {
            if indexPath.row < maximumSupportedFavorites {
                editFavoriteCurrentIndex = indexPath.row
                cell.addFavoriteImageView.isHidden = true
                self.isAddingNewPenSet = true
                let currentPenset = self.manager.fetchCurrentPenset()
                self.favorites.append(currentPenset)
                self.manager.saveFavorites(favorites)
                cell.configure(favorite: currentPenset, currentPenset: currentPenset)
                self.updateSelectionStatus(cell: cell)
                self.showFavoriteEditScreen(with: currentPenset, sourceView: cell)
            } else {
                self.isAddingNewPenSet = false
                self.displayMaximumFavoritesAlert()
            }
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
                manager.saveFavorites(favorites)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: nil)
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}

extension FTFavoritebarViewController: FTFavoriteEditDelegate {
    func didChangeFavorite(_ penset: FTPenSetProtocol) {
        if let index = editFavoriteCurrentIndex, index < self.favorites.count {
            if let currentCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell {
                currentCell.configure(favorite: penset, currentPenset: penset)
            }
            if(index < self.favorites.count) {
                self.favorites[index] = penset
            } else if index == self.favorites.count {
                self.favorites.append(penset)
            }
            self.manager.saveFavorites(favorites)
            self.updateDisplay()
        }
    }

    func didDeleteFavorite(_ favorite: FTPenSetProtocol) {
        if let index = editFavoriteCurrentIndex, index < self.favorites.count {
            self.favorites.remove(at: index)
            self.manager.saveFavorites(favorites)
            self.dismiss(animated: false)
            // After removal of favorite, we need to make the one comes in the slot as current penset or, the last one
            if index < self.favorites.count {
                let immediateFav = self.favorites[index]
                self.manager.saveCurrentSelection(penSet: immediateFav)
            } else if let last = self.favorites.last {
                self.manager.saveCurrentSelection(penSet: last)
            }
            self.reloadFavoritesData()
            self.isAddingNewPenSet = false
            self.isDisplayedEditPenRack = false
            self.collectionView.isScrollEnabled = true
            self.updateDisplay()
        }
    }

    func didDismissEditModeScreen() {
        self.handleEditScreenDismissal()
    }

    func currentFavoriteCount() -> Int {
        return self.favorites.count
    }
}

extension FTFavoritebarViewController: FTFavoriteSizeUpdateDelegate {
    func didChangeSize(_ size: CGFloat) {
        let curPenset = self.getCurrentPenset()
        if let size = FTPenSize(rawValue: Int(Float(size))) {
            curPenset.size = size
        }
        curPenset.preciseSize = size
        self.manager.saveCurrentSelection(penSet: curPenset)
        self.updateDisplay()
    }

    func didDismissCurrentsizeEditScreen() {
        self.reloadFavoritesData()
    }
}

extension FTFavoritebarViewController: FTColorEyeDropperPickerDelegate {
    func colorPicker(picker: FTColorEyeDropperPickerController,didPickColor color:UIColor) {
        let hexColor = color.hexString
        if let index = editFavoriteCurrentIndex, index < self.favorites.count {
            let penset = self.favorites[index]
            penset.color = hexColor
            if let currentCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FTFavoritePenCollectionViewCell {
                currentCell.configure(favorite: penset, currentPenset: penset)
            }
            if(index < self.favorites.count) {
                self.favorites[index] = penset
            } else if index == self.favorites.count {
                self.favorites.append(penset)
            }
            self.manager.saveFavorites(favorites)
        }
        if let vm = self.presetViewModel {
            vm.updateCurrentSelection(colorHex: hexColor)
            if let editIndex = vm.presetEditIndex {
                vm.updatePresetColor(hex: color.hexString, index: editIndex)
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.edit.rawValue])
            }
            else {
                vm.addSelectedColorToPresets()
                NotificationCenter.default.post(name: .PresetColorUpdate, object: nil, userInfo: ["type": FTColorToastType.add.rawValue])
            }
            vm.updateCurrentColors()
        }
        self.presetViewModel = nil
    }
}
