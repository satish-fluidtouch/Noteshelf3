//
//  FTTextEditLinkViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTPageSelectionDelegate: AnyObject {
    func didSelect(page: FTNoteshelfPage)
}

protocol FTDocumentSelectionDelegate: AnyObject {
    func didSelect(document: FTShelfItemProtocol)
}

protocol FTTextLinkInfoDelegate: FTTextLinkEditDelegate {
    func getTextLinkInfo() -> FTTextLinkInfo?
}

protocol FTTextLinkEditDelegate: AnyObject {
    func updateTextLinkInfo(_ info: FTTextLinkInfo)
    func removeLink()
}

class FTTextEditLinkViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView?
     
    var viewModel: FTTextEditLinkViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(FTTextEditLinkTableViewCell.self, forCellReuseIdentifier: FTTextEditLinkTableViewCell.cellIdentifier)
        self.viewModel?.prepareDocumentDetails(onCompletion: { _ in
            self.tableView?.reloadData()
        })
    }
    
    @objc func removeLinkButtonTapped() {
        self.viewModel?.removeLink()
    }

    deinit {
        self.viewModel?.closeOpenedDocumentIfNeeded()
    }
}

private extension FTTextEditLinkViewController {
    func showDocumentSelectionScreen() {
        let viewModel = FTShelfItemsViewModel(selectedShelfItems: [])
        let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: viewModel, purpose: .linking, delegate: self)
        self.ftPresentFormsheet(vcToPresent: controller, hideNavBar: false)
    }
    
    func showFinderPagesScreen(doc: FTThumbnailableCollection, onCompletion: ((Bool) -> Void)?) {
        if let linkToVc = UIStoryboard(name: "FTTextInputUI", bundle: nil).instantiateViewController(withIdentifier: "FTLinkToSelectViewController") as? FTLinkToSelectViewController {
            linkToVc.document = doc
            let navVc = UINavigationController(rootViewController: linkToVc)
            self.present(navVc, animated: true) {
                onCompletion?(true)
            }
        }
    }
}

private class FTTextEditLinkTableViewCell: UITableViewCell {
    static let cellIdentifier = "FTTextEditLinkTableViewCell"
}

extension FTTextEditLinkViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return FTLinkSettingsOptions.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FTTextEditLinkTableViewCell.cellIdentifier, for: indexPath)
        var config = cell.defaultContentConfiguration()
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17.0)]
        let option = FTLinkSettingsOptions.allCases[indexPath.row]
        config.attributedText = NSAttributedString(string: option.rawValue, attributes: attributes)
        if option == .document, let title = self.viewModel?.docTitle {
            config.secondaryAttributedText = NSAttributedString(string: title, attributes: attributes)
        } else if option == .page, let pageNum = self.viewModel?.pageNumber {
            config.secondaryAttributedText = NSAttributedString(string:  String(pageNum), attributes: attributes)
        }
        config.prefersSideBySideTextAndSecondaryText = true
        config.textToSecondaryTextHorizontalPadding = 8.0
        cell.contentConfiguration = config
        cell.backgroundColor = UIColor.appColor(.white60)
        return cell
    }
    
     func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let footerView = UIView()
            footerView.frame.size = CGSize(width: tableView.frame.width, height: 44.0)
            footerView.backgroundColor = .clear
            let removeLinkButton = UIButton(type: .system)
            removeLinkButton.setTitle("Remove Link", for: .normal)
            removeLinkButton.addTarget(self, action: #selector(removeLinkButtonTapped), for: .touchUpInside)
            footerView.addSubview(removeLinkButton)

            // Set constraints for your button within the footer view (adjust as needed)
            removeLinkButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                removeLinkButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor, constant: 0),
                removeLinkButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor, constant: 0),
            ])
            return footerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = FTLinkSettingsOptions.allCases[indexPath.row]
        if option == .document {
            self.showDocumentSelectionScreen()
        } else if option == .page {
            self.viewModel?.getDocumentDetails(onCompletion: { document in
                if let doc = document as? FTThumbnailableCollection {
                    self.showFinderPagesScreen(doc: doc, onCompletion: nil)
                }
            })
        } else if option == .linkTo {
            
        }
    }
}

extension FTTextEditLinkViewController: FTDocumentSelectionDelegate, FTPageSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        if let doc = document as? FTDocumentItemProtocol, let docId = doc.documentUUID {
            if var exstInfo = self.viewModel?.getExistingTextLinkInfo() {
                exstInfo.docUUID = docId
                exstInfo.pageUUID = ""
                self.viewModel?.updateDocumentTitle(document.displayTitle)
                self.viewModel?.updatePageNumber(1)
                self.tableView?.reloadData()
                self.viewModel?.updateTextLinkInfo(exstInfo)
            }
        }
    }
    
    func didSelect(page: FTNoteshelfPage) {
        if var info = self.viewModel?.getExistingTextLinkInfo(), nil != self.viewModel?.selectedDocument {
            info.pageUUID = page.uuid
            self.viewModel?.updatePageNumber(page.pageIndex() + 1)
            self.viewModel?.closeOpenedDocumentIfNeeded()
            self.tableView?.reloadData()
            self.viewModel?.updateTextLinkInfo(info)
        }
    }
}
