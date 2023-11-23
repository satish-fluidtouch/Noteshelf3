//
//  FTCoversViewController.swift
//  FTNewNotebook
//
//  Created by Narayana on 27/02/23.
//

import UIKit
import FTCommon
import FTDocumentFramework

extension URL {
    func resolvedFileURL() -> URL {
        return FTDocumentUtils.resolvedURL(self);
    }
}

class FTCoversViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView?

    private let otherCellsReuseId = "FTCoverCollectionViewCell"
    private let customSectionCellReuseId = "FTCustomSectionCell"
    private var size: CGSize = .zero
    private var selectedIndexPath: IndexPath?

    weak var coverSelectionDelegate: FTCoverSelectionDelegate?
    weak var scrollDelegate: FTCoversScrollDelegate?
    var viewModel: FTCoversViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator?.isHidden = true
        self.viewModel.prepareData()
        self.scrollDelegate?.variantsData = self.viewModel.variantsData
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
            self.scrollDelegate?.didScrollToSection(selIndexPath.section - 2) // Excluding NoCover, Custom
        } else {
            self.scrollDelegate?.didScrollToSection(0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.size != self.view.frame.size {
            self.size = self.view.frame.size
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.updateContentInset()
            self.collectionView.reloadData()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.collectionView.reloadData()
        }
    }

    private func updateContentInset() {
        var contentInset = FTCovers.ContentInset.regular
        if !self.isRegularClass() {
            contentInset = FTCovers.ContentInset.compact
        }
        self.collectionView.contentInset = contentInset
    }

    private func findInitialSelectedIndexpathIfExist() -> IndexPath? {
        var scrollIndexPath: IndexPath?
        if let selTheme = FTCurrentCoverSelection.shared.selectedCover {
            for (sectionIndex, coverSection) in self.viewModel.coversSections.enumerated() {
                if let coverIndex = coverSection.covers.firstIndex(where: { $0.themeable.themeFileURL.resolvedFileURL() == selTheme.themeFileURL.resolvedFileURL() }) {
                    scrollIndexPath = IndexPath(row: coverIndex, section: sectionIndex)
                }
            }
        }
        return scrollIndexPath
    }

    private func requiredStandardSectionToShow() -> Int {
        var reqSection: Int = 0
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        var visibleSecArr: [Int] = []
        if !visibleIndexPaths.isEmpty {
            var visibleSections = Set<Int>()
            for indexPath in visibleIndexPaths {
                visibleSections.insert(indexPath.section)
            }
            visibleSecArr = Array(visibleSections).sorted(by: { $0 > $1 })
        }
        if !visibleSecArr.isEmpty {
            for section in visibleSecArr {
                let indexPath = IndexPath(row: 0, section: section)
                if let layoutAttrs = self.collectionView.layoutAttributesForItem(at: indexPath) {
                    if (layoutAttrs.frame.minX < (self.collectionView.contentOffset.x + self.collectionView.frame.width/2.0)) {
                        reqSection = section
                        break
                    }
                }
            }
        }
        return reqSection - 2 // excluding nocover, custom
    }

    private func resetPreviousSelection() {
        if let selIndex = self.selectedIndexPath, let cell = collectionView.cellForItem(at: selIndex) as? FTCoverCollectionViewCell {
            cell.isCoverSelected = false
        }
    }
}

extension FTCoversViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.coversSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = self.viewModel.coversSections[section]
        var count: Int = 1
        if section.sectionType != .custom {
            count = section.covers.count
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = self.viewModel.coversSections[indexPath.section]
        var title: String = ""

        if section.sectionType == .custom {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: customSectionCellReuseId, for: indexPath) as? FTCustomSectionCell else {
                fatalError("Programmer error")
            }
            cell.configureSection(section)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: otherCellsReuseId, for: indexPath) as? FTCoverCollectionViewCell else {
                fatalError("Programmer error")
            }
            if indexPath.row == 0 { // only for first row of any section
                title = section.name
            }
            let theme = section.covers[indexPath.row]
            let isSelected = theme.themeable.themeFileURL.resolvedFileURL() == FTCurrentCoverSelection.shared.selectedCover?.themeFileURL.resolvedFileURL()
            if isSelected {
                self.selectedIndexPath = indexPath
            }
            cell.configureCell(with: theme, title: title, isSelected: isSelected)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) is FTCustomSectionCell {
            self.navigateToCustomCoversScreen()
        } else if let cell = collectionView.cellForItem(at: indexPath) as? FTCoverCollectionViewCell {
            self.resetPreviousSelection()
            self.selectedIndexPath = indexPath
            let section = self.viewModel.coversSections[indexPath.section]
            let theme = section.covers[indexPath.row]
            cell.isCoverSelected = true
            self.coverSelectionDelegate?.didSelectCover(theme)
        }
    }

    private func navigateToCustomCoversScreen() {
        let storyBoard = UIStoryboard(name: "FTCovers", bundle: currentBundle)
        guard let customVc = storyBoard.instantiateViewController(withIdentifier: "FTCustomCoversViewController") as? FTCustomCoversViewController else {
            fatalError("Programmer error, unable to find FTCustomCoversViewController")
        }
        customVc.viewModel = FTCustomCoversViewModel(with: self.viewModel.delegate)
        customVc.delegate = self.coverSelectionDelegate
        self.navigationController?.pushViewController(customVc, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let reqSection = self.requiredStandardSectionToShow()
        self.scrollDelegate?.didScrollToSection(reqSection)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let reqSection = self.requiredStandardSectionToShow()
        self.scrollDelegate?.didScrollToSection(reqSection)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGSize
        if self.isRegularClass() {
            size = FTCovers.Panel.CellSize.regular
        } else {
            size = FTCovers.Panel.CellSize.compact
        }
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset: CGFloat
        if self.isRegularClass() {
            inset = FTCovers.Panel.SectionInset.regular
        } else {
            inset = FTCovers.Panel.SectionInset.compact
        }
        return UIEdgeInsets(top: 0.0, left: inset/2, bottom: 0.0, right: inset/2)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let spacing: CGFloat
        if self.isRegularClass() {
            spacing = FTCovers.Panel.ItemSpacing.regular
        } else {
            spacing = FTCovers.Panel.ItemSpacing.compact
        }
        return spacing
    }
}

extension FTCoversViewController: FTCoverVariantDelegate {
    func didSelectVariant(_ name: String) {
        if let section = self.viewModel.coversSections.firstIndex(where: { $0.name == name }) {
            if section < 3 {
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.contentOffset = .zero
                }
            } else {
                let selectedIndexPath = IndexPath(row: 0, section: section)
                if section == self.viewModel.coversSections.count - 1 {
                    self.collectionView.scrollToItem(at: selectedIndexPath, at: .left, animated: true)
                } else {
                    var reqOffset: CGFloat = 0.0
                    var inset = FTCovers.Panel.SectionInset.regular
                    if !self.isRegularClass() {
                        inset = FTCovers.Panel.SectionInset.compact
                    }
                    if let secondSectionLayoutAttrs = collectionView.layoutAttributesForItem(at: IndexPath(row: 0, section: 1)) {
                        reqOffset = secondSectionLayoutAttrs.frame.maxX + inset
                    }
                    if let layoutAttributes = collectionView.layoutAttributesForItem(at: selectedIndexPath) {
                        let cellFrame = layoutAttributes.frame
                        let offset = CGPoint(x: cellFrame.minX - reqOffset, y: 0)
                        self.collectionView.setContentOffset(offset, animated: true)
                    }
                }
            }
        }
    }
}
