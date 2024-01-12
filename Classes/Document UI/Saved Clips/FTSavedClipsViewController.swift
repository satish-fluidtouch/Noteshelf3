//
//  FTSavedClipsViewController.swift
//  Noteshelf3
//
//  Created by Siva on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

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
    
    private var savedClipsCategories = [FTSavedClipsCategoryModel]() {
        didSet {
            if self.savedClipsCategories.count == 1 {
                segmentHeightConstraint.constant = 0
            }
        }
    }
    private let viewModel = FTSavedClipsViewModel()
    lazy private var layout = FTCollectionViewWaterfallLayout()
    private var minimumColumnSpacing : CGFloat = 12.0
    private var minimumInterItemSpacing : CGFloat = 12.0
    private var cellType: FTSavedClipsCellType = .normal
    private var selectedSegmentIndex: Int  = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        savedClipsCategories = viewModel.savedClipsCategories()
        self.setupCollectionView()
        if savedClipsCategories.count > 1 {
            segmentHeightConstraint.constant = 36
            self.setupSegmentedControl()
        } else {
            segmentHeightConstraint.constant = 0
        }
        updateCellType()
        // Do any additional setup after loading the view.
    }

    private func setupCollectionView() {
        self.collectionView.register(FTEmptyCollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")
        /// Configure No Recents ReusableView
        let emptyCategoriesView = UINib(nibName: "FTEmptyCategoriesView", bundle: nil)
        self.collectionView.register(emptyCategoriesView, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FTEmptyCategoriesView")

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
            cellType = .editing
            deleteCategory.isHidden = false
            deleteHeightConstraint.constant = 35
            for cell in collectionView!.visibleCells as! [FTSavedClipsCollectionViewCell] {
                cell.closeButton.isHidden = false
                cell.startWiggle()
            }
        }
        else if sender.state == .ended ||  sender.state == .changed {
            let seconds = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                // Put your code which should be executed with a delay here
                //                self.layout.invalidateLayout()
                //                self.collectionView.reloadData()
            }
        }
    }

    private func updateCellType() {
        if self.savedClipsCategories.count == 0 {
            cellType = .emptyCategories
        } else {
            let clips = savedClipsCategories[selectedSegmentIndex].savedClips
            cellType = clips.count == 0 ? .emptyClips : .normal
        }
    }

    @IBAction func deleteCategoryAction(_ sender: Any) {
        if savedClipsCategories.count > 0 {
            let category = savedClipsCategories[selectedSegmentIndex]
            let saveClips = category.savedClips
            if saveClips.count > 0 {
                let title = "Deleting this category will delete all \(saveClips.count) clips in this category and cannot be recovered."
                let message = "Would you like to continue?"
                UIAlertController.showDeleteDialog(with: title, message: message, from: self) {
                    Task {
                        try self.viewModel.deleteCategory(category: category.title)
                    }
                    self.savedClipsCategories.remove(at: self.selectedSegmentIndex)
                    if self.savedClipsCategories.count > 0 {
                        self.selectedSegmentIndex = 0
                        self.setupSegmentedControl()
                        self.updateCellType()
                    } else {
                        self.cellType = .emptyCategories
                        self.segmentHeightConstraint.constant = 0
                    }
                    self.collectionView.reloadData()
                    self.deleteCategory.isHidden = true
                    self.deleteHeightConstraint.constant = 0
                }
            }
        }
    }
}

//MARK:- FTSegmentedControlDelegate
extension FTSavedClipsViewController: FTSegmentedControlDelegate {
    private func setupSegmentedControl() {

        let titles = savedClipsCategories.map{ $0.title.localized }
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

    public func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: FTSegmentedControl) {
    }

    public func didEndScrollOfSegments() {
        track("Saved Clips_tab_scrolled", params: [:], screenName: FTScreenNames.noteBookAddNew)
    }

    func didTapSegment(_ index: Int) {
        selectedSegmentIndex = index
        updateCellType()
        deleteCategory.isHidden = true
        deleteHeightConstraint.constant = 0
        collectionView.reloadData()
        collectionView.stopWiggle()
    }

}


// MARK: UICollectionViewDataSource
extension FTSavedClipsViewController: UICollectionViewDelegate, UICollectionViewDataSource,
                                      FTCollectionViewDelegateWaterfallLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if savedClipsCategories.count == 0 {
            return 0
        }
        let savedClips = savedClipsCategories[self.selectedSegmentIndex].savedClips
        return savedClips.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch cellType {
        case .normal, .editing:
            return self.collectionView(collectionView, normalCellForItemAt: indexPath)
        case .emptyCategories:
            return self.collectionView(collectionView, emptyCategoriesCellForItemAt: indexPath)
        case .emptyClips:
            return self.collectionView(collectionView, emptyClipsCellForItemAt: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, normalCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTSavedClipsCollectionViewCell", for: indexPath) as? FTSavedClipsCollectionViewCell else {
            fatalError("Failed deque cell")
        }
        let savedClips = savedClipsCategories[self.selectedSegmentIndex].savedClips
        let clip = savedClips[indexPath.row]
        cell.configureCellWith(clip: clip, isEditing: self.cellType == .editing ? true : false)
        cell.deleteSavedClip = {
            Task {
                try self.viewModel.deleteSavedClip(clip: clip)
                self.savedClipsCategories[self.selectedSegmentIndex].savedClips.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])
                self.updateCellType()
                if self.cellType == .emptyClips || self.cellType == .emptyCategories {
                    self.collectionView.stopWiggle()
                    self.deleteCategory.isHidden = true
                    self.deleteHeightConstraint.constant = 0
                    self.collectionView.reloadData()
                }
            }
        }
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        cell.addGestureRecognizer(longPressRecognizer)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, emptyCategoriesCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        cell.backgroundColor = .red
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, emptyClipsCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        cell.backgroundColor = .green
        return cell
    }


    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            if cellType == .emptyCategories || cellType == .emptyClips  {
                let noRecentsView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTEmptyCategoriesView", for: indexPath)
                if let noRecentsView = noRecentsView as? FTEmptyCategoriesView  {
                    return noRecentsView
                }
            }
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderIn section: Int) -> CGFloat {
        if cellType == .emptyCategories || cellType == .emptyClips {
            return self.collectionView.frame.size.height
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let savedClips = savedClipsCategories[self.selectedSegmentIndex].savedClips
        let clip = savedClips[indexPath.row]
        Task {
            if let annotations = try await viewModel.clipAnnotationsFor(clip: clip) {
                print(annotations)
                delegate?.didTapSavedClip(annotations: annotations)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let savedClips = savedClipsCategories[self.selectedSegmentIndex].savedClips
        let clip = savedClips[indexPath.row]
        if let itemWidth = clip.image?.size.width, let itemHeight = clip.image?.size.height {
            return CGSize(width: itemWidth, height: itemHeight)
        }
        return CGSize(width: 90, height: 90)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetsFor section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }

}

//extension FTSavedClipsViewController: UIScrollViewDelegate {
//
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//
//        if  !scrollView.isDragging {
//            return
//        }
//
//        let indexPath = collectionView.indexPathForItem(at: scrollView.contentOffset)
//
//        guard let indexPath = indexPath else {
//            let visibleSections = collectionView.indexPathsForVisibleItems.map { $0.section}
//            if let section = visibleSections.min() {
//                selectedSegmentIndex = section
//                if segmentedControl?.selectedIndex != section {
//                    segmentedControl?.selectedIndex = section
//                }
//            }
//            return
//        }
//
//        let section = indexPath.section
//        selectedSegmentIndex = section
//        if segmentedControl?.selectedIndex != section {
//            segmentedControl?.selectedIndex = section
//        }
//    }
//}
