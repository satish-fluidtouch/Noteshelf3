//
//  FTLinkToSelectViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon

class FTLinkToSelectViewController: UIViewController {
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView?
    @IBOutlet private weak var containerView: UIView!
    
    var viewModel: FTLinkToTextViewModel!
    weak var docPagesController: FTDocumentPagesController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()
        self.configureSegmentControl()

        self.viewModel?.prepareDocumentDetails(onCompletion: { _ in
            if let doc = self.viewModel.selectedDocument as? FTThumbnailableCollection {
                self.docPagesController?.document = doc
                let indexPath = IndexPath(item: self.viewModel.pageNumber - 1, section: 0)
                self.docPagesController?.updateSelectedIndexPath(indexPath, toScroll: true)
                self.tableView?.reloadData()
            }
        })
    }

    deinit {
        self.viewModel.closeOpenedDocumentIfNeeded()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTDocumentPagesController", let docPagesVc = segue.destination as? FTDocumentPagesController {
            self.docPagesController = docPagesVc
            self.docPagesController?.delegate = self
        }
    }

    static func showTextLinkScreen(from controller: FTTextAnnotationViewController, with linkInfo: FTTextLinkInfo, and linkText: String) {
        if let linkToVc = UIStoryboard(name: "FTTextInputUI", bundle: nil).instantiateViewController(withIdentifier: "FTLinkToSelectViewController") as? FTLinkToSelectViewController {
            let viewModel = FTLinkToTextViewModel(info: linkInfo, linkText: linkText, delegate: controller)
            linkToVc.viewModel = viewModel
            controller.ftPresentFormsheet(vcToPresent: linkToVc, hideNavBar: false)
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

    func configureSegmentControl() {
        self.segmentControl.setTitle(FTLinkToSegment.page.localizedString, forSegmentAt: 0)
        self.segmentControl.setTitle(FTLinkToSegment.url.localizedString, forSegmentAt: 1)
        self.segmentControl.addTarget(self, action: #selector(segmentTapped), for: .valueChanged)
        self.segmentControl.selectedSegmentIndex = 0
        if self.segmentControl.selectedSegmentIndex == 1 {
            self.containerView.isHidden = true
        } else {
            self.containerView.isHidden = false
        }
    }

    func handleSegmentControlSelection() {
        let selSegIndex = segmentControl.selectedSegmentIndex
        if selSegIndex == 1 {
            self.containerView.isHidden = true
        } else {
            self.containerView.isHidden = false
        }
        self.tableView?.reloadData()
    }

    @objc func segmentTapped() {
        self.handleSegmentControlSelection()
    }

    func navigateToDocumentSelectionScreen() {
        let viewModel = FTShelfItemsViewModel(selectedShelfItems: [])
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: viewModel, purpose: .linking, delegate: self)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    var linkOptions: [FTLinkToOption] {
        let options: [FTLinkToOption]
        if self.segmentControl.selectedSegmentIndex == 0 {
            options = FTLinkToSegment.page.options
        } else {
            options = FTLinkToSegment.url.options
        }
        return options
    }
}

extension FTLinkToSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return linkOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = linkOptions[indexPath.row]
        var reqCell = UITableViewCell()
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FTLinkTextTableViewCell.linkTextCellId, for: indexPath) as? FTLinkTextTableViewCell else {
                fatalError("Programmer error, unable to find FTLinkTextTableViewCell")
            }
            cell.configureCell(with: option, linkText: self.viewModel.linkText)
            cell.textEntryDoneHandler = {[weak self] (text: String?) -> Void in
                print("zzzz - \(text)")
            }
            reqCell = cell
        } else {
            if option == .document {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FTLinkBookTableViewCell.linkBookCellId, for: indexPath) as? FTLinkBookTableViewCell else {
                    fatalError("Programmer error, unable to find FTLinkBookTableViewCell")
                }
                cell.configureCell(with: option, title: self.viewModel.docTitle)
                reqCell = cell
            } else if option == .url {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FTLinkTextTableViewCell.linkTextCellId, for: indexPath) as? FTLinkTextTableViewCell else {
                    fatalError("Programmer error, unable to find FTLinkTextTableViewCell")
                }
                cell.configureCell(with: option, linkText: "www.google.com")
                cell.textEntryDoneHandler = {[weak self] (text: String?) -> Void in
                }
                reqCell = cell
            }
        }
        return reqCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            self.navigateToDocumentSelectionScreen()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

extension FTLinkToSelectViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        self.dismiss(animated: true) {
            if type == .right { // DONE
                self.viewModel.saveLinkInfo()
            }
        }
    }
}

extension FTLinkToSelectViewController: FTDocumentSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        self.navigationController?.popToViewController(self, animated: true)
        if let doc = document as? FTDocumentItemProtocol, let docId = doc.documentUUID {
            var exstInfo = self.viewModel.info
            exstInfo.docUUID = docId
            exstInfo.pageUUID = ""
            self.viewModel.updateTextLinkInfo(exstInfo)
            self.viewModel.getSelectedDocumentDetails { doc in
                self.viewModel.updateDocumentTitle(document.displayTitle)
                self.viewModel.updatePageNumber(1)
                if let document = doc as? FTThumbnailableCollection {
                    self.docPagesController?.updateSelectedIndexPath(IndexPath(item: 0, section: 0), toScroll: false)
                    self.docPagesController?.document = document
                    self.tableView?.reloadData()
                }
            }
        }
    }
}

extension FTLinkToSelectViewController: FTPageSelectionDelegate {
    func didSelect(page: FTNoteshelfPage) {
        var info = self.viewModel.info
        if nil != self.viewModel?.selectedDocument {
            info.pageUUID = page.uuid
            self.viewModel.updatePageNumber(page.pageIndex() + 1)
            self.viewModel.closeOpenedDocumentIfNeeded()
            self.viewModel.updateTextLinkInfo(info)
            self.tableView?.reloadData()
        }
    }
}
