//
//  FTSaveClipPreviewViewController.swift
//  Noteshelf3
//
//  Created by Siva on 22/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTSaveClipDelegate: AnyObject {
    func didSelectCategory(name: String)
}

class FTSaveClipPreviewViewController: UIViewController {

    let viewModel = FTSavedClipsViewModel()
    var previewImage: UIImage?
    var categories = [FTSavedClipsCategoryModel]()
    var selectedIndexPath = IndexPath(row: 1, section: 0)
    var lassoSelectionView: FTLassoSelectionView?
    weak var delegate: FTSaveClipDelegate?

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addClipButton: UIButton!
    @IBOutlet weak var previewImageContainer: UIView!

    @IBOutlet weak var cancelButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previewImageContainer.layer.cornerRadius = 8.0
        if let previewImage {
            if previewImageView.bounds.width < previewImage.size.width || previewImageView.bounds.height < previewImage.size.height {
                self.previewImageView.contentMode = .scaleAspectFit
            } else {
                self.previewImageView.contentMode = .center
            }
            self.previewImageView.image = previewImage
        }

        addClipButton.layer.cornerRadius = 10.0

        tableView.register(FTInlineTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView?.bounds = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: ((self.tableView.frame.size.width)/1.75))

        self.categories = viewModel.savedClipsCategories()
        self.categories.insert(FTSavedClipsCategoryModel(title: "clip.newCategory".localized, url: nil), at: 0)
        if categories.count == 1 {
            //TODO: Localization
            self.categories.insert(FTSavedClipsCategoryModel(title: "My Clips", url: nil), at: 1)
        }
        if let selectedCategory = FTUserDefaults.selectedClipCategory, let index = self.categories.firstIndex(where: {$0.title == selectedCategory}) {
            selectedIndexPath = IndexPath(row: index, section: 0)
        }
        self.tableView.reloadData()

        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        cancelButton.setTitle("Cancel".localized, for: .normal)
        // Do any additional setup after loading the view.
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true)
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.saveclip_cancel_tap)
    }

    @IBAction func addClipAction(_ sender: Any) {
        if let editingCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FTInlineTableViewCell {
            editingCell.textField.resignFirstResponder()
        }
        let category = categories[self.selectedIndexPath.row]
        FTUserDefaults.selectedClipCategory = category.title
        delegate?.didSelectCategory(name: category.title)
        let toastView = FTToastConfiguration(title: "clip.clipAdded".localized)
        FTToastHostController.showToast(from: self, toastConfig: toastView)
        self.dismiss(animated: true)
        FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.saveclip_addclip_tap)
    }
}

extension FTSaveClipPreviewViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FTInlineTableViewCell
            cell.selectionStyle = .none
            cell.didEndEditing = { str in
                // update data array when text in cell is edited
                self.categories[indexPath.row].title = str
                if str.count == 0 {
                    self.selectedIndexPath = IndexPath(row: 1, section: 0)
                    tableView.selectRow(at: self.selectedIndexPath, animated: false, scrollPosition: .none)
                } else {
                    self.selectedIndexPath = IndexPath(row: 0, section: 0)
                }
            }

            cell.didBeginEditing = {
                self.selectedIndexPath = IndexPath(row: 0, section: 0)
                tableView.selectRow(at: self.selectedIndexPath, animated: false, scrollPosition: .none)
            }
            return cell
        }
        // Reuse or create a cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: "FTSaveClipCategoriesCell", for: indexPath)
        let category = categories[indexPath.row]
        cell.textLabel!.text = category.title
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FTSaveClipCategoriesCell {
            self.view.endEditing(true)
            self.selectedIndexPath = indexPath
            cell.setSelected(true, animated: true)
            FTNotebookEventTracker.trackNotebookEvent(with: FTNotebookEventTracker.saveclip_category_tap)
        }
        // Toggle the cell's selection state
        if let cell = tableView.cellForRow(at: indexPath) as? FTInlineTableViewCell {
            cell.setSelected(true, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FTSaveClipCategoriesCell {
            cell.setSelected(false, animated: true)
        }
        // Toggle the cell's selection state
        if let cell = tableView.cellForRow(at: indexPath) as? FTInlineTableViewCell {
            cell.setSelected(false, animated: true)
        }
    }

}
