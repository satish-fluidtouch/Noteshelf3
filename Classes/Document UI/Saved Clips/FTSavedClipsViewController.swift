//
//  FTSavedClipsViewController.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

enum FTSavedClipsCellType {
    case normal, editing
}

protocol FTSavedClipdelegate : NSObjectProtocol {
    func didTapSavedClip(clip: FTSavedClipModel)
    func dismiss()
}

class FTSavedClipsViewController: UIViewController, FTPopoverPresentable {
    weak var delegate: FTSavedClipdelegate?
    var ftPresentationDelegate = FTPopoverPresentation()
    var sourceType : FTSourceScreenType = .Others

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var segmentedControl: FTSegmentedControl!
    @IBOutlet weak var deleteCategory: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var segmentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var categoryTitleTextField: UITextField!

    @IBOutlet weak var emptyClipsView: UIView!
    @IBOutlet weak var emptyCategoryLabel: UILabel!
    private var cellType: FTSavedClipsCellType = .normal
    private let viewModel = FTSavedClipsViewModel()
    private var minimumColumnSpacing : CGFloat = 12.0
    private var minimumInterItemSpacing : CGFloat = 12.0
    private var selectedSegmentIndex: Int  = 0

    var toHideBackBtn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedSegmentIndex = viewModel.selectedIndex()
        categoryTitleTextField.layer.cornerRadius = 8.0
        categoryTitleTextField.delegate = self
        categoryTitleTextField.returnKeyType = .done

        self.setupCollectionView()
        self.setupSegmentedControl()
        titleLabel.text = "clip.savedClips".localized
        self.backButton.isHidden = self.toHideBackBtn
    }
    
    private func setupCollectionView() {
        collectionView.dragInteractionEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    @IBAction func tapOnBackButton(_ sender: UIButton) {
        guard let _ = navigationController?.popViewController(animated: true) else {
            // ll be executed during emoji edit and back tap
            self.dismiss(animated: true)
            return
        }
    }

    @IBAction func editButtonTapped(sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            startEditing()
            trackSavedClips(with: FTNotebookEventTracker.nbk_addmenu_savedclips_edit_tap)
        } else {
            endEditing()
            trackSavedClips(with: FTNotebookEventTracker.nbk_addmenu_savedclips_done_tap)
        }
        collectionView.reloadData()
    }

    @IBAction func deleteCategoryAction(_ sender: Any) {
        viewModel.updatedSegmentSelection = { categoriesCount in
            if categoriesCount > 0 {
                if self.selectedSegmentIndex == categoriesCount {
                    self.selectedSegmentIndex -= 1
                }
                self.setupSegmentedControl()
            } else {
                self.segmentHeightConstraint.constant = 0
            }
            self.endEditing()
        }
        let rows = viewModel.numberOfRowsForSection(section: self.selectedSegmentIndex)
        let title = String(format: "clip.deleteCategory.title".localized, "\"\(rows)\"")
        UIAlertController.showDeleteDialog(with: title, message: "", from: self) {
            do {
                try self.viewModel.removeCategory(index: self.selectedSegmentIndex)
                self.trackSavedClips(with: FTNotebookEventTracker.nbk_savedclips_edit_deletecategory_tap)
            } catch {
                // Handle error
            }
        }
    }

    private func startEditing() {
        cellType = .editing
        self.editButton.isSelected = true
        editButton.setTitle("Done".localized, for: .selected)
        deleteHeightConstraint.constant = 35
        deleteCategory.isHidden = false
        categoryTitleTextField.isHidden = false
        segmentedControl.isHidden = true
    }  

    private func endEditing() {
        self.cellType = .normal
        self.editButton.isSelected = false
        self.collectionView.stopWiggle()
        self.deleteHeightConstraint.constant = 0
        self.deleteCategory.isHidden = true
        categoryTitleTextField.endEditing(true)
        categoryTitleTextField.isHidden = true
        self.segmentedControl.isHidden = false
        self.collectionView.reloadData()
        segmentedControl.textCornerRadius = 10.0
    }

    func removeItem(clip: FTSavedClipModel) {
        guard let index = viewModel.index(for: clip, in: selectedSegmentIndex) else {
            return
        }
        if index < viewModel.numberOfRowsForSection(section: selectedSegmentIndex) {
            do {
                try self.viewModel.removeClip(clip: clip, in: selectedSegmentIndex)
                collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                if self.collectionView.numberOfItems(inSection: 0) == 0 {
                    self.endEditing()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func trackSavedClips(with event: String) {
        FTNotebookEventTracker.trackNotebookEvent(with: event)
    }
}

//MARK:- FTSegmentedControlDelegate
extension FTSavedClipsViewController: FTSegmentedControlDelegate {
    private func setupSegmentedControl() {
        let titles = viewModel.categoryNames()
        
    if titles.count > 0 {
        segmentedControl?.delegate = self
        segmentedControl?.setTitles(titles, style: .adaptiveSpace(18))
    }
            segmentedControl.textColor = UIColor.appColor(.black70)
            segmentedControl.textSelectedColor = UIColor.white
            segmentedControl.textFont = UIFont.appFont(for: .medium, with: 13.0)
            segmentedControl.textCornerRadius = 10.0
            segmentedControl.textBorderWidth = 0.0
            segmentedControl.segmentBgColor = UIColor.appColor(.black5)
            segmentedControl.selectedSegmentBgColor = UIColor.appColor(.neutral)
            segmentedControl.setCover(upDowmSpace: 0, cornerRadius: 10)
            segmentedControl.backgroundColor = .clear
            segmentedControl.selectedIndex = selectedSegmentIndex
    }

    public func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
        selectedSegmentIndex = index
        if let category = viewModel.categoryFor(index: index) {
            FTUserDefaults.selectedClipCategory = category.title
            categoryTitleTextField.text = category.title
            self.endEditing()
        }
    }

    public func didEndScrollOfSegments() {
        track("Saved Clips_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
    }

    func didTapSegment(_ index: Int) {
        trackSavedClips(with: FTNotebookEventTracker.nbk_addmenu_savedclips_category_tap)
    }

}


// MARK: UICollectionViewDataSource
extension FTSavedClipsViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let rows = viewModel.numberOfRowsForSection(section: self.selectedSegmentIndex)
        if viewModel.categoryNames().isEmpty {
            collectionView.backgroundView = emptyClipsView
            editButton.isHidden = true
        } else {
            collectionView.backgroundView = emptyCategoryLabel
            editButton.isHidden = false
        }
        if rows == 0 {
            collectionView.backgroundView?.isHidden = false
        } else {
            collectionView.backgroundView?.isHidden = true
        }
        return rows
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSavedClipsCollectionViewCell", for: indexPath) as? FTSavedClipsCollectionViewCell else {
            fatalError("Failed deque cell")
        }
        if let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) {
            cell.configureCellWith(clip: clip, isEditing: self.cellType == .editing ? true : false)
            cell.deleteSavedClip = { [weak self] clip in
                self?.removeItem(clip: clip)
                self?.trackSavedClips(with: FTNotebookEventTracker.nbk_savedclips_edit_delete_tap)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FTSavedClipsCollectionViewCell {
            cell.updateContentMode()
        }
    }

    func collectionView(_ collectionView: UICollectionView, emptyCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        cell.backgroundColor = .red
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if cellType == .normal, let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) {
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.didTapSavedClip(clip: clip)
                self?.trackSavedClips(with: FTNotebookEventTracker.nbk_addmenu_savedclips_clip_tap)
            }
        } else if cellType == .editing {
            self.endEditing()
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard cellType == .normal, let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) else {
            return nil
        }
        var contextMenu : UIContextMenuConfiguration?
        let identifier = indexPath as NSIndexPath

        let actionProvider : ([UIMenuElement]) -> UIMenu? = { _ in
            let addACtion = UIAction(title: NSLocalizedString("snippets.addtopage", comment: "Add"),
                                     image: nil,
                                     identifier: nil,
                                     discoverabilityTitle: nil,
                                     attributes: .standard,
                                     state: .off) { [weak self] _ in
                guard let self = self else { return }
                self.dismiss(animated: true) { [weak self] in
                    self?.delegate?.didTapSavedClip(clip: clip)
                    self?.trackSavedClips(with: FTNotebookEventTracker.nbk_savedclips_clip_addtopage_tap)
                }
            }
            let deleteACtion = UIAction(title: NSLocalizedString("delete", comment: "delete"),
                                     image: nil,
                                     identifier: nil,
                                     discoverabilityTitle: nil,
                                     attributes: .destructive,
                                     state: .off) { [weak self] _ in
                guard let self = self else { return }
                self.removeItem(clip: clip)
                self.trackSavedClips(with: FTNotebookEventTracker.nbk_savedclips_clip_delete_tap)
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [addACtion, deleteACtion])
        }
        contextMenu = UIContextMenuConfiguration(identifier: identifier, previewProvider: {
            guard let controller = UIStoryboard(name: "FTDocumentEntity", bundle: nil).instantiateViewController(withIdentifier: "FTClipPreviewViewController") as? FTClipPreviewViewController else {
                return nil
            }
            controller.setPreviewImage(clip.image)
            if let size = clip.image?.size {
                let width = max(size.width, 250)
                let height = max(size.height, 250)
                controller.preferredContentSize = CGSize(width: width + 20, height: height + 20)
            }
            return controller
        }, actionProvider: actionProvider)
        return contextMenu
    }
}

extension FTSavedClipsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.size.width/2 - 5
        return CGSize(width: width, height: width)
    }
}

extension FTSavedClipsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let category = viewModel.categoryFor(index: self.selectedSegmentIndex) , category.title != textField.text {
            do {
                try viewModel.renameCategory(category: category, with: textField.text ?? "")
                let titles = viewModel.categoryNames()
                segmentedControl?.setTitles(titles, style: .adaptiveSpace(18))
                segmentedControl.selectedIndex = selectedSegmentIndex
                if !(textField.text ?? "").isEmpty {
                    FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.nbk_savedclips_edit_name_type)
                }
            } catch {
                // Handle
                print(error)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }

}

extension FTSavedClipsViewController {
    class func showSavedClipsController(from controller: UIViewController, source: Any, delegate: FTSavedClipdelegate?, toHideBackBtn: Bool = false) -> FTSavedClipsViewController {
        let storyboard = UIStoryboard.init(name: "FTDocumentEntity", bundle: nil)
        guard let savedClipsVc = storyboard.instantiateViewController(withIdentifier: "FTSavedClipsViewController") as? FTSavedClipsViewController else {
            fatalError("FTEmojisViewController not found")
        }
        savedClipsVc.sourceType = .centerPanel
        savedClipsVc.delegate = delegate
        savedClipsVc.toHideBackBtn = toHideBackBtn
        savedClipsVc.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        savedClipsVc.ftPresentationDelegate.source = source as AnyObject
        controller.ftPresentPopover(vcToPresent: savedClipsVc, contentSize: AddMenuType.media.contentSize, hideNavBar: true)
        return savedClipsVc
    }
}
