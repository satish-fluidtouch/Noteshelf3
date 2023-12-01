//
//  FTCustomCoversViewController.swift
//  FTNewNotebook
//
//  Created by Narayana on 01/03/23.
//

import UIKit
import PhotosUI
import FTCommon

class FTCustomCoversViewController: FTCoversHeaderController {
    @IBOutlet private weak var customInfoLabel: UILabel?
    @IBOutlet private weak var collectionView: UICollectionView!

    @IBOutlet private weak var infoLabelHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var collectionViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet private weak var collectionViewTrailingConstraint: NSLayoutConstraint?
    @IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint?

    var viewModel: FTCustomCoversViewModel!
    weak var delegate: FTCoverSelectionDelegate?

    private let sectionCellReUseId = "FTDefaultCustomCoverSectionCell"
    private let coverCellReuseId = "FTCoverCollectionViewCell"
    private var selectedIndexPath: IndexPath?
    private var size: CGSize = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.shapeTopCorners()
        self.configureNavigationItems(with: "CustomCover".localized)
        self.customInfoLabel?.text = "theams.unsplashDescription".localized
        // To fix the issue of initial variant selection based on selected cover
        // TODO: (Narayana) // To check for better fix
        runInMainThread(0.1) {
            self.showRequiredPosition()
        }
    }

    private func showRequiredPosition() {
        self.collectionView.reloadData()
        if let selIndexPath = self.findInitialSelectedIndexpathIfExist() {
            self.collectionView.scrollToItem(at: selIndexPath, at: .centeredHorizontally, animated: false)
        }
    }

    private func findInitialSelectedIndexpathIfExist() -> IndexPath? {
        var scrollIndexPath: IndexPath?
        if let selTheme = FTCurrentCoverSelection.shared.selectedCover {
            if let coverIndex = self.viewModel.recentCovers.firstIndex(where: { $0.themeable.themeFileURL.standardizedFileURL == selTheme.themeFileURL.standardizedFileURL }) {
                scrollIndexPath = IndexPath(row: coverIndex, section: 1) // custom cover section is 1
            }
        }
        return scrollIndexPath
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.relayoutCollectionView()
            self.collectionView.reloadData()
        }
    }

    override func doneTapped() {
        self.delegate?.didTapOnDoneButton()
    }

    private func relayoutCollectionView() {
        if self.viewModel.recentCovers.isEmpty {
            self.customInfoLabel?.isHidden = false
            self.infoLabelHeightConstraint?.constant = 34.0
            self.collectionViewLeadingConstraint?.isActive = false
            self.collectionViewTrailingConstraint?.isActive = false
            let defaultSectionCount = CGFloat(self.viewModel.defaultSections.count)

            var cellSize = FTCovers.Panel.CellSize.regular
            var spacing = FTCovers.Panel.ItemSpacing.customCoverRegular
            var inset = FTCovers.Panel.SectionInset.customCoverRegular

            if !self.isRegularClass() {
                cellSize = FTCovers.Panel.CellSize.compact
                 spacing = FTCovers.Panel.ItemSpacing.compact
                 inset = FTCovers.Panel.SectionInset.compact
            }
            let reqWidth = (defaultSectionCount * cellSize.width) + ((defaultSectionCount - 1) * (spacing)) + (2 * inset)
            self.collectionViewWidthConstraint?.constant = reqWidth
        } else {
            self.collectionViewWidthConstraint?.constant = self.view.frame.size.width
            self.customInfoLabel?.isHidden = true
            self.infoLabelHeightConstraint?.constant = 16.0
            self.collectionViewLeadingConstraint?.isActive = true
            self.collectionViewTrailingConstraint?.isActive = true
            var contentInset = FTCovers.ContentInset.regular
            if !self.isRegularClass() {
                contentInset = FTCovers.ContentInset.compact
            }
            self.collectionView?.layoutIfNeeded()
            self.collectionView.contentInset = contentInset
        }
    }

    private func resetPreviousSelection() {
        if let selIndex = self.selectedIndexPath, let cell = collectionView.cellForItem(at: selIndex) as? FTCoverCollectionViewCell {
            cell.isCoverSelected = false
        }
    }
}

extension FTCustomCoversViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // default + recent
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = self.viewModel.defaultSections.count
        if section == 1 {
            count = self.viewModel.recentCovers.count
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionCellReUseId, for: indexPath) as? FTDefaultCustomCoverSectionCell else {
                fatalError("Programmer error")
            }
            cell.configureCell(with: self.viewModel.defaultSections[indexPath.row])
            return cell
        } else {
            let coverTheme = self.viewModel.recentCovers[indexPath.row]
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: coverCellReuseId, for: indexPath) as? FTCoverCollectionViewCell else {
                fatalError("Programmer error")
            }
            let isSelected = coverTheme.themeable.themeFileURL.standardizedFileURL == FTCurrentCoverSelection.shared.selectedCover?.themeFileURL.standardizedFileURL
            if isSelected {
                self.selectedIndexPath = indexPath
            }
            cell.configureCell(with: coverTheme, isSelected: isSelected)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) is FTDefaultCustomCoverSectionCell {
            let section = self.viewModel.defaultSections[indexPath.row]
            if section.type == .photoLibrary {
                FTPHPicker.shared.presentPhPickerController(from: self, selectionLimit: 1)
            } else if  section.type == .camera {
                FTImagePicker.shared.showImagePickerController(from: self)
            } else if section.type == .unsplash {
                let storyBoard = UIStoryboard(name: "FTCovers", bundle: currentBundle)
                if let unsplashVc = storyBoard.instantiateViewController(withIdentifier: "FTUnsplashViewController") as? FTUnsplashViewController {
                    unsplashVc.delegate = self.delegate
                    self.navigationController?.pushViewController(unsplashVc, animated: true)
                }
            }
        } else {
            if let cell = collectionView.cellForItem(at: indexPath) as? FTCoverCollectionViewCell {
                self.resetPreviousSelection()
                self.selectedIndexPath = indexPath
                cell.isCoverSelected = true
                let coverTheme = self.viewModel.recentCovers[indexPath.row]
                self.delegate?.didSelectCover(coverTheme)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGSize
        if self.isRegularClass() {
            size = FTCovers.Panel.CellSize.customRegular
        } else {
            size = FTCovers.Panel.CellSize.compact
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var insetDefined = FTCovers.Panel.SectionInset.customCoverRegular
        if !self.isRegularClass() {
            insetDefined = FTCovers.Panel.SectionInset.compact
        }
        return UIEdgeInsets(top: 0, left: insetDefined/2, bottom: 0, right: insetDefined/2)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return FTCovers.Panel.ItemSpacing.customTypeRegular
        } else {
            var spacing = FTCovers.Panel.ItemSpacing.customCoverRegular
            if !self.isRegularClass() {
                spacing = FTCovers.Panel.ItemSpacing.compact
            }
            return spacing
        }
    }
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 1 {
            let identifier = indexPath as NSIndexPath
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider:  { [weak self]actions in
                return UIMenu(children: [
                    UIAction(title: "Delete", attributes: .destructive) { _ in
                        guard let self = self else {
                            return
                        }
                        let customCover = self.viewModel.recentCovers[indexPath.row]
                        self.deletionCustomCover(customCover.themeable)
                        self.updateCoverPreviewIfNeeded(recentDeletedCover: customCover)
                    }
                ])
            })
        }
        return nil
    }
    private func targetedPreview(for cell:UICollectionViewCell) -> UITargetedPreview? {
        guard let _ = cell.window else {
            return nil;
        }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        var view = cell.contentView
        if let coverCell = cell as? FTCoverCollectionViewCell, let imgView = coverCell.imgView {
            view = imgView
        }
        let shape = FTPreviewShape(leftRaidus: 3, rightRadius: 7.5)
        let bezierPath = UIBezierPath(cgPath: shape.path(in: view.bounds).cgPath)
        parameters.visiblePath = bezierPath
        let preview = UITargetedPreview.init(view: view, parameters: parameters)
        return preview
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let indexPath = configuration.identifier as? IndexPath, let cell = collectionView.cellForItem(at: indexPath){
            return self.targetedPreview(for: cell);
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let identifier = configuration.identifier as? IndexPath {
            if let cell = self.collectionView?.cellForItem(at: identifier) {
                return self.targetedPreview(for: cell);
            }
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .dismiss
    }

}

extension FTCustomCoversViewController: FTPHPickerDelegate, FTImagePickerDelegate {
    func didFinishPicking(results: [PHPickerResult], photoType: PhotoType) {
        if photoType != .photoLibrary {
            return
        }
        FTPHPicker.shared.processResultForUIImages(results: results) { phItems in
            if let phItem = phItems.first {
                let image = phItem.image
                self.processSelectedImage(image)
            }
        }
    }

    private func processSelectedImage(_ image: UIImage) {
        Task {
            self.delegate?.didSelectCustomImage(image)
            self.collectionView.reloadData()
        }
    }

    func didFinishPicking(image: UIImage, picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.processSelectedImage(image)
        }
    }
}
//MARK: Custom cover deletion
extension FTCustomCoversViewController {
    func deletionCustomCover(_ customCover:FTThemeable){
        if FileManager().fileExists(atPath: customCover.themeFileURL.path) {
            do {
                try FileManager.init().removeItem(at: customCover.themeFileURL)
                viewModel.deleteCustomCoverFromRecents(customCover)
                self.collectionView.reloadSections(IndexSet(integer: 1))
                self.relayoutCollectionView()
            } catch let failError as NSError{
                debugPrint("error occured while deleting custom cover with reason",failError.localizedDescription)
            }
        }
    }
    func updateCoverPreviewIfNeeded(recentDeletedCover: FTCoverThemeModel){
        if recentDeletedCover.themeable.themeFileURL.urlByDeleteingPrivate() ==
            FTCurrentCoverSelection.shared.selectedCover?.themeFileURL.urlByDeleteingPrivate() ,
           let coverStyleVC = self.navigationController?.children.first(where: {$0 is FTCoverStyleViewController}) as? FTCoverStyleViewController,
           let noCoverTheme = coverStyleVC.noCoverTheme(){
            self.delegate?.didSelectCover(noCoverTheme)
            coverStyleVC.setDefaultCover(noCoverTheme.themeable)
        }
    }
}
