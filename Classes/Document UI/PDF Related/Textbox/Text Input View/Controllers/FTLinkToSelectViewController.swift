//
//  FTLinkToSelectViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 11/01/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import FTCommon
import Reachability

class FTLinkToSelectViewController: UIViewController {
    @IBOutlet private weak var segmentControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView?
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var errorStackView: UIStackView!
    @IBOutlet private weak var dividerView: UIView!

    var viewModel: FTLinkToTextViewModel!
    weak var docPagesController: FTDocumentPagesController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()
        self.configureSegmentControl()
    }

    deinit {
        self.viewModel.closeOpenedDocumentIfExists()
    }

    override var shouldAvoidDismissOnSizeChange: Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "FTDocumentPagesController", let docPagesVc = segue.destination as? FTDocumentPagesController {
            self.docPagesController = docPagesVc
            self.docPagesController?.delegate = self
        }
    }

    static func showTextLinkScreen(from controller: FTTextAnnotationViewController, linkText: String, url: URL?, currentPage: FTPageProtocol) {
        if let linkToVc = UIStoryboard(name: "FTTextInputUI", bundle: nil).instantiateViewController(withIdentifier: "FTLinkToSelectViewController") as? FTLinkToSelectViewController {
            let viewModel = FTLinkToTextViewModel(linkText: linkText, url: url, currentPage: currentPage, delegate: controller)
            linkToVc.viewModel = viewModel
            controller.ftPresentFormsheet(vcToPresent: linkToVc, hideNavBar: false)
        }
    }
}

private extension FTLinkToSelectViewController {
    func configureNavigationBar() {
        self.title = "textLink_linkTo".localized
        let titleAttrs = [NSAttributedString.Key.font: UIFont.clearFaceFont(for: .medium, with: 20.0), NSAttributedString.Key.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.titleTextAttributes = titleAttrs
        let leftNavItem = FTNavBarButtonItem(type: .left, title: "Cancel".localized, delegate: self)
        let rightNavItem = FTNavBarButtonItem(type: .right, title: "Done".localized, delegate: self)
        self.navigationItem.leftBarButtonItem = leftNavItem
        self.navigationItem.rightBarButtonItem = rightNavItem
    }

    func updateDoneEnableStatus() {
        let toEnable: Bool
        if segmentControl.selectedSegmentIndex == 1 {
            toEnable = !self.viewModel.webUrlStr.isEmpty && !self.viewModel.linkText.isEmpty
        } else {
            toEnable = !self.viewModel.linkText.isEmpty
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = toEnable
    }

    func configureSegmentControl() {
        self.segmentControl.setTitle(FTLinkToSegment.page.localizedString, forSegmentAt: 0)
        self.segmentControl.setTitle(FTLinkToSegment.url.localizedString, forSegmentAt: 1)
        self.segmentControl.addTarget(self, action: #selector(segmentTapped), for: .valueChanged)
        if self.viewModel.webUrlStr.isEmpty {
            self.segmentControl.selectedSegmentIndex = 0
        } else {
            self.segmentControl.selectedSegmentIndex = 1
        }
        self.handleSegmentControlSelection()
    }

    func configureDocumentIfNeeded() {
        guard nil == self.docPagesController?.document else {
            return
        }
        self.viewModel?.prepareDocumentDetails(onCompletion: { _ in
            if let doc = self.viewModel.selectedDocument as? FTThumbnailableCollection {
                self.docPagesController?.document = doc
                let indexPath = IndexPath(item: self.viewModel.pageNumber - 1, section: 0)
                self.docPagesController?.updateSelectedIndexPath(indexPath, toScroll: true)
                self.tableView?.reloadData()
            }
        })
    }

     func configWebView(with urlStr: String?) {
         self.webView.navigationDelegate = self
         self.errorStackView.isHidden = true
        if let reqUrlStr = urlStr {
            self.handleWebUrl(text: reqUrlStr)
        }
    }

    func handleSegmentControlSelection() {
        let selSegIndex = segmentControl.selectedSegmentIndex
        if selSegIndex == 1 {
            self.containerView.isHidden = true
            self.configWebView(with: self.viewModel.webUrlStr)
        } else {
            self.containerView.isHidden = false
            self.webView.isHidden = true
            self.errorStackView.isHidden = true
            self.configureDocumentIfNeeded()
        }
        self.updateDoneEnableStatus()
        self.tableView?.reloadData()
    }

    @objc func segmentTapped() {
        self.handleSegmentControlSelection()
        let segmentType = segmentControl.selectedSegmentIndex == 0 ? "page" : "URL"
        FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToSegmentTap, params: ["segment": segmentType])
    }

    func navigateToDocumentSelectionScreen() {
        let viewModel = FTShelfItemsViewModel(selectedShelfItems: [], purpose: .linking)
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: viewModel, delegate: self)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func handleDividerVisibility(with contentOffset: CGPoint) {
        if contentOffset.y <= 0.0 {
            self.dividerView.isHidden = true
        } else {
            self.dividerView.isHidden = false
        }
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

    func handleWebUrl(text: String) {
        guard self.segmentControl.selectedSegmentIndex == 1 else {
            return
        }
        let reachability: Reachability = Reachability.forInternetConnection()
        let status: NetworkStatus = reachability.currentReachabilityStatus()
        if status == NetworkStatus.NotReachable {
            self.webView.isHidden = true
            self.errorStackView.isHidden = false
        } else {
            self.errorStackView.isHidden = true
            if let request = text.getUrlRequestFromString() {
                self.webView.isHidden = false
                self.webView.load(request)
            } else {
                self.webView.isHidden = true
            }
        }
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
            cell.textEntryChangeHandler = {[weak self] (text: String?) -> Void in
                guard let self else { return }
                if let usableText = text?.trimmingCharacters(in: CharacterSet.whitespaces) {
                    self.viewModel.updateLinkText(usableText)
                    self.updateDoneEnableStatus()
                }
            }
            cell.textEntryDoneHandler = {(text: String?) -> Void in
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToLinkTextType)
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
                cell.configureCell(with: option, linkText: self.viewModel.webUrlStr)
                cell.textEntryChangeHandler = {[weak self] (text: String?) -> Void in
                    guard let self else { return }
                    if let usableText = text?.trimmingCharacters(in: CharacterSet.whitespaces) {
                        self.viewModel.updateWebUrlString(usableText)
                        self.updateDoneEnableStatus()
                    }
                }
                cell.textEntryDoneHandler = {[weak self] (text: String?) -> Void in
                    guard let self else { return }
                    FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToURLType)
                    if let usableText = text?.trimmingCharacters(in: CharacterSet.whitespaces) {
                        self.handleWebUrl(text: usableText)
                    }
                }
                reqCell = cell
            }
        }
        return reqCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = linkOptions[indexPath.row]
        if option == .document {
            self.navigateToDocumentSelectionScreen()
            FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToNotebookTap)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
}

extension FTLinkToSelectViewController: FTBarButtonItemDelegate {
    func didTapBarButtonItem(_ type: FTBarButtonItemType) {
        self.viewModel.closeOpenedDocumentIfExists()
        self.dismiss(animated: true) {
            if type == .right { // DONE
                var isWebLink = false
                var linkType = "page"
                if self.segmentControl.selectedSegmentIndex == 1 {
                    isWebLink = true
                    linkType = "URL"
                }
                self.viewModel.saveLinkInfo(isWebLink: isWebLink)
                FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToDoneTap, params: ["link_type": linkType])
            }
        }
    }
}

extension FTLinkToSelectViewController: FTDocumentSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        self.navigationController?.popToViewController(self, animated: true)
        guard self.viewModel.selectedDocument?.URL != document.URL else { // selection is same
            return
        }
        self.viewModel.closeOpenedDocumentIfExists() // to close if any pre-opened document was there
        if let doc = document as? FTDocumentItemProtocol, let docId = doc.documentUUID {
            FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkNotebookSelect)
            self.viewModel.getSelectedDocumentDetails(using: docId) { doc in
                if let selectedDoc = doc {
                    self.viewModel.updateDocumentTitle(document.displayTitle)
                    self.viewModel.updateTextLinkInfo(using: selectedDoc)
                    if let document = doc as? FTThumbnailableCollection {
                        self.tableView?.reloadData()
                        self.docPagesController?.document = document
                        self.docPagesController?.updateSelectedIndexPath(IndexPath(item: 0, section: 0), toScroll: false)
                    }
                }
            }
        }
    }
}

extension FTLinkToSelectViewController: FTPageSelectionDelegate {
    func didSelect(page: FTNoteshelfPage) {
        var info = self.viewModel.info
        if nil != self.viewModel?.selectedDocument {
            self.viewModel.updatePageId(using: page)
            self.tableView?.reloadData()
            FTTextLinkEventTracker.trackEvent(with: TextLinkEvents.linkToPageTap)
        }
    }

    func didScrollPages(contentOffset: CGPoint) {
        self.handleDividerVisibility(with: contentOffset)
    }
}

extension FTLinkToSelectViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let urlStr = webView.url?.absoluteString {
            self.viewModel.updateWebUrlString(urlStr)
        }
    }
}
