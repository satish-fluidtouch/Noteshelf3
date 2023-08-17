//
//  FTCoverStyleViewController.swift
//  FTNewNotebook
//
//  Created by Narayana on 24/02/23.
//

import UIKit
import FTStyles
import FTCommon

class FTCoverStyleViewController: UIViewController {
    weak var selectionDelegate: FTCoverSelectionDelegate?
    private var coversVc: FTCoversViewController?

    var viewModel: FTCoversViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItems()
        self.view.shapeTopCorners()
    }

    private func configureNavigationItems() {
        self.title = "ChooseCover".localized
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs
        let leftNavItem = FTNavBarButtonItem(type: .left, title: "Cancel".localized, delegate: self)
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self)
        self.navigationItem.leftBarButtonItem = leftNavItem
        self.navigationItem.rightBarButtonItem = rightNavItem
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTCoversViewController", let coversVc = segue.destination as? FTCoversViewController {
            coversVc.viewModel = self.viewModel
            coversVc.coverSelectionDelegate = self.selectionDelegate
            self.coversVc = coversVc
            if let theme = FTCurrentCoverSelection.shared.selectedCover, theme.isCustom {
                let storyBoard = UIStoryboard(name: "FTCovers", bundle: currentBundle)
                guard let customVc = storyBoard.instantiateViewController(withIdentifier: "FTCustomCoversViewController") as? FTCustomCoversViewController else {
                    fatalError("Programmer error, unable to find FTCustomCoversViewController")
                }
                customVc.viewModel = FTCustomCoversViewModel(with: self.viewModel.delegate)
                customVc.delegate = self.selectionDelegate
                self.navigationController?.pushViewController(customVc, animated: false)
            }
        } else if segue.identifier == "FTCoverStyleVariantsController", let coverStyleVariantsVc = segue.destination as? FTCoverStyleVariantsController, let coversVc = self.coversVc {
            coverStyleVariantsVc.variantsData = self.viewModel.variantsData
            coverStyleVariantsVc.variantDelegate = coversVc
            self.coversVc?.scrollDelegate = coverStyleVariantsVc
        }
    }
}

extension FTCoverStyleViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .left {
            self.selectionDelegate?.didTapCancelbutton()
        } else {
            self.selectionDelegate?.didTapOnDoneButton()
        }
    }
}
