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
    case normal, editing, emptyCategories, emptyClips
}

protocol FTSavedClipdelegate : NSObjectProtocol {
    func didTapSavedClip(annotations: [FTAnnotation])
    func dismiss()
}

class FTSavedClipsViewController: UIViewController {
    weak var delegate: FTSavedClipdelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var segmentedControl: FTSegmentedControl!
    @IBOutlet weak var deleteCategory: UIButton!
    @IBOutlet weak var segmentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var categoryTitleTextField: UITextField!

    private let viewModel = FTSavedClipsViewModel()
    lazy private var layout = FTCollectionViewWaterfallLayout()
    private var minimumColumnSpacing : CGFloat = 12.0
    private var minimumInterItemSpacing : CGFloat = 12.0
    private var cellType: FTSavedClipsCellType = .normal
    private var selectedSegmentIndex: Int  = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        selectedSegmentIndex = viewModel.selectedIndex()
        categoryTitleTextField.layer.cornerRadius = 8.0
        categoryTitleTextField.delegate = self
        categoryTitleTextField.returnKeyType = .done

        self.setupCollectionView()
        self.setupSegmentedControl()
        self.updateCellType()
        // Do any additional setup after loading the view.
    }

    private func updateCellType() {
        if viewModel.categoriesCount() == 0 {
            self.cellType = .emptyCategories
            self.segmentHeightConstraint.constant = 0
        } else {
            let clips = self.viewModel.numberOfRowsForSection(section: self.selectedSegmentIndex)
            self.cellType = clips == 0 ? .emptyClips : .normal
        }
    }

    private func setupCollectionView() {
        self.collectionView.register(FTEmptyCollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")
        /// Configure Empty Categories ReusableView
        let emptyCategoriesView = UINib(nibName: "FTEmptyCategoriesView", bundle: nil)
        self.collectionView.register(emptyCategoriesView, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FTEmptyCategoriesView")

        //FTEmptyClipsView
        let emptyClipsView = UINib(nibName: "FTEmptyClipsView", bundle: nil)
        self.collectionView.register(emptyClipsView, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FTEmptyClipsView")

        layout.minimumColumnSpacing = minimumColumnSpacing
        layout.minimumInteritemSpacing = minimumInterItemSpacing

        collectionView.collectionViewLayout  = layout
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

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            startEditing()
            for cell in collectionView!.visibleCells as! [FTSavedClipsCollectionViewCell] {
                cell.closeButton.isHidden = false
                cell.startWiggle()
            }
        } else if sender.state == .ended ||  sender.state == .changed {
            let seconds = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                // Put your code which should be executed with a delay here
                //                self.layout.invalidateLayout()
                //                self.collectionView.reloadData()
            }
        }
    }

    @IBAction func deleteCategoryAction(_ sender: Any) {
        viewModel.updatedSegmentSelection = { categoriesCount in
            if categoriesCount > 0 {
                if self.selectedSegmentIndex == categoriesCount {
                    self.selectedSegmentIndex -= 1
                }
                self.setupSegmentedControl()
            } else {
                self.cellType = .emptyCategories
                self.segmentHeightConstraint.constant = 0
            }
            self.endEditing()
        }
        let rows = viewModel.numberOfRowsForSection(section: self.selectedSegmentIndex)
        let title = String(format: "clip.deleteCategory.title".localized, "\"\(rows)\"")
        let message = "clip.deleteCategory.message".localized
        UIAlertController.showDeleteDialog(with: title, message: message, from: self) {
            do {
                try self.viewModel.removeCategory(index: self.selectedSegmentIndex)
                self.updateCellType()
            } catch {
                // Handle error
            }
        }
    }

    private func startEditing() {
        cellType = .editing
        deleteHeightConstraint.constant = 35
        deleteCategory.isHidden = false
        categoryTitleTextField.isHidden = false
        segmentedControl.isHidden = true
    }  

    private func endEditing() {
        self.collectionView.stopWiggle()
        self.deleteHeightConstraint.constant = 0
        self.deleteCategory.isHidden = true
        categoryTitleTextField.isHidden = true
        self.segmentedControl.isHidden = false
        self.collectionView.reloadData()
    }

    @objc private func removeItem(_ sender: UIButton) {
        let index = sender.tag
        if index < viewModel.numberOfRowsForSection(section: selectedSegmentIndex) {
            do {
                try self.viewModel.removeItemFor(indexPath: IndexPath(item: index, section: self.selectedSegmentIndex))
                collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                if self.cellType == .emptyClips || self.cellType == .emptyCategories {
                    self.endEditing()
                }
            } catch {
                print(error)
            }
        }
    }
}

//MARK:- FTSegmentedControlDelegate
extension FTSavedClipsViewController: FTSegmentedControlDelegate {
    private func setupSegmentedControl() {
        let titles = viewModel.categoryNames()
        if titles.count > 0 {
            segmentedControl?.delegate = self
            segmentedControl?.setTitles(titles, style: .adaptiveSpace(18))
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
    }

    public func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
        selectedSegmentIndex = index
        if let category = viewModel.categoryFor(index: index) {
            FTUserDefaults.selectedClipCategory = category.title
            categoryTitleTextField.text = category.title
            self.updateCellType()
            self.endEditing()
        }
    }

    public func didEndScrollOfSegments() {
        track("Saved Clips_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
    }

    func didTapSegment(_ index: Int) {
    }

}


// MARK: UICollectionViewDataSource
extension FTSavedClipsViewController: UICollectionViewDelegate, UICollectionViewDataSource,
                                      FTCollectionViewDelegateWaterfallLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let rows = viewModel.numberOfRowsForSection(section: self.selectedSegmentIndex)
        return rows
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch cellType {
        case .normal, .editing:
            return self.collectionView(collectionView, normalCellForItemAt: indexPath)
        case .emptyCategories, .emptyClips:
            return self.collectionView(collectionView, emptyCellForItemAt: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, normalCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSavedClipsCollectionViewCell", for: indexPath) as? FTSavedClipsCollectionViewCell else {
            fatalError("Failed deque cell")
        }
        if let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) {
            cell.configureCellWith(clip: clip, isEditing: self.cellType == .editing ? true : false)
            cell.closeButton.tag = indexPath.item
            cell.closeButton.addTarget(self, action: #selector(removeItem(_:)), for: .touchUpInside)
        }
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        cell.addGestureRecognizer(longPressRecognizer)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, emptyCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        cell.backgroundColor = .red
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
                if cellType == .emptyCategories {
                    let emptyCategoriesView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTEmptyCategoriesView", for: indexPath)
                    if let emptyCategoriesView = emptyCategoriesView as? FTEmptyCategoriesView  {
                        emptyCategoriesView.titleLabel.isHidden = false
                        emptyCategoriesView.titleLabel.text = "clip.noSavedClips".localized
                        emptyCategoriesView.subTitleLabel.text = "clip.noSavedClips.description".localized
                        return emptyCategoriesView
                    }
                } else if cellType == .emptyClips {
                    let emptyClipsView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTEmptyClipsView", for: indexPath)
                    if let emptyClipsView = emptyClipsView as? FTEmptyClipsView  {
                        emptyClipsView.titleLabel.text = "clip.noCategory".localized
                    return emptyClipsView
                }
            }
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderIn section: Int) -> CGFloat {
        if cellType == .emptyCategories || cellType == .emptyClips {
            return self.collectionView.frame.size.height - 64
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if cellType == .normal, let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) {
            viewModel.clipAnnotationsFor(clip: clip) { [weak self] annotations, error in
                if let annotations {
                    self?.delegate?.didTapSavedClip(annotations: annotations)
                } else {
                    // Handle Error
                }
            }
        } else if cellType == .editing {
            updateCellType()
            self.endEditing()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let clip = viewModel.itemFor(indexPath: IndexPath(item: indexPath.item, section: self.selectedSegmentIndex)) {
            if let itemWidth = clip.image?.size.width, let itemHeight = clip.image?.size.height {
                return CGSize(width: itemWidth, height: itemHeight)
            }
        }
        return CGSize(width: 90, height: 90)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsFor section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }

}

extension FTSavedClipsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        let category = viewModel.categoryFor(index: self.selectedSegmentIndex)
        if category?.title != textField.text {
            do {
                try viewModel.renameCategory(category: category!, with: textField.text ?? "")
                let titles = viewModel.categoryNames()
                segmentedControl?.setTitles(titles, style: .adaptiveSpace(18))
                segmentedControl.selectedIndex = selectedSegmentIndex
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
