//
//  FTLinkToSelectViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

class FTLinkToSelectViewController: UIViewController {
    @IBOutlet private weak var segmentControl: UISegmentedControl?
    @IBOutlet private weak var scrollView: UIScrollView?
    @IBOutlet private weak var tableView: UITableView?
    
    weak var document: FTThumbnailableCollection?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()
        self.tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTDocumentPagesController", let docPagesVc = segue.destination as? FTDocumentPagesController {
            docPagesVc.document = self.document
        }
    }
}

private extension FTLinkToSelectViewController {
    func configureNavigationBar() {
        self.title = "Link To"
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs
        let leftNavItem = FTNavBarButtonItem(type: .left, title: "Cancel".localized, delegate: self)
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self)
        self.navigationItem.leftBarButtonItem = leftNavItem
        self.navigationItem.rightBarButtonItem = rightNavItem
    }

    func showDocumentSelectionScreen() {
        let viewModel = FTShelfItemsViewModel(selectedShelfItems: [])
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: viewModel, purpose: .linking, delegate: self)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension FTLinkToSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reqCell = UITableViewCell()
        if indexPath.row == 0 || indexPath.row == 1 {
            let option = FTLinkToOption.allCases[indexPath.row]
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FTLinkTextTableViewCell.linkTextCellId, for: indexPath) as? FTLinkTextTableViewCell else {
                    fatalError("Programmer error, unable to find FTLinkTextTableViewCell")
                }
                cell.configureCell(with: option)
                reqCell = cell
            }
            else if indexPath.row == 1 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FTLinkBookTableViewCell.linkBookCellId, for: indexPath) as? FTLinkBookTableViewCell else {
                    fatalError("Programmer error, unable to find FTLinkBookTableViewCell")
                }
                cell.configureCell(with: option, title: "Notebook Name")
                reqCell = cell
            }
        }
        return reqCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

extension FTLinkToSelectViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        if type == .left {
            self.dismiss(animated: true)
        } else {
            // Done action
        }
    }
}

extension FTLinkToSelectViewController: FTDocumentSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        self.navigationController?.popToViewController(self, animated: true)

    }
}

enum FTLinkToOption: String, CaseIterable {
    case linkText = "Link Text"
    case document = "Notebook"
}
