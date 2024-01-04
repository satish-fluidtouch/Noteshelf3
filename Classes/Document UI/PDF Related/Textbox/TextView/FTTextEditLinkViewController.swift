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
    weak var infoDelegate: FTTextLinkInfoDelegate?
    
    private var docTitle: String?
    private var pageNumber: Int?
    
    private var token: FTDocumentOpenToken?
    private weak var selectedDocument: FTDocumentProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(FTTextEditLinkTableViewCell.self, forCellReuseIdentifier: FTTextEditLinkTableViewCell.cellIdentifier)
        if let info = self.infoDelegate?.getTextLinkInfo() {
            self.updateDocumentInfoIfNeeded(for: info, onCompletion: nil)
        }
    }
    
    @objc func removeLinkButtonTapped() {
        self.infoDelegate?.removeLink()
    }

    deinit {
        self.closeOpenedDocumentIfNeeded()
    }
}

private extension FTTextEditLinkViewController {
    func updateDocumentInfoIfNeeded(for info: FTTextLinkInfo, onCompletion: ((Bool) -> Void)?) {
        if let doc = info.currentDocument,  info.docUUID == doc.documentUUID {
            self.selectedDocument = doc
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    self.updateUI(using: doc, shelfItem: shelfItem, info: info, onCompletion: { success in
                        onCompletion?(success)
                    })
                }
            }
        } else {
            FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: info.docUUID) { docItem in
                if let shelfItem = docItem {
                    let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                    FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                        if let doc = document {
                            self.selectedDocument = doc
                            self.token = token
                            self.updateUI(using: doc, shelfItem: shelfItem, info: info, onCompletion: { success in
                                onCompletion?(success)
                            })
                        }
                    }
                }
            }
        }
    }

     func showFinderPagesScreen(doc: FTThumbnailableCollection, onCompletion: ((Bool) -> Void)?) {
        let finderVc = FTFinderViewController.instantiate(fromStoryboard: .finder)
        finderVc.configureData(forDocument: doc, exportInfo: nil, delegate: nil, searchOptions: FTFinderSearchOptions())
        finderVc.mode = .chooseSinglePage
        finderVc.singlePageSelectDelegate = self
        self.present(finderVc, animated: true) {
            onCompletion?(true)
        }
    }
    
    func updateUI(using doc: FTDocumentProtocol, shelfItem: FTShelfItemProtocol, info: FTTextLinkInfo, onCompletion: ((Bool) -> Void)?) {
        self.docTitle = shelfItem.displayTitle
        let pages = doc.pages()
        if let pageIndex = pages.firstIndex(where: { $0.uuid == info.pageUUID }) {
            self.pageNumber = pageIndex + 1
        } else {
            self.pageNumber = 1
            var updatedInfo = info
            updatedInfo.pageUUID = pages.first?.uuid ?? ""
            self.infoDelegate?.updateTextLinkInfo(updatedInfo)
        }
        self.tableView?.reloadData()
        onCompletion?(true)
    }
    
    func closeOpenedDocumentIfNeeded() {
        // should not be closing if selected document and current document are same
        if let info = self.infoDelegate?.getTextLinkInfo(), let currentDoc = info.currentDocument, let selDoc = self.selectedDocument, currentDoc.documentUUID != selDoc.documentUUID, let token = self.token {
            FTNoteshelfDocumentManager.shared.closeDocument(document: selDoc, token: token, onCompletion: nil)
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
        if option == .document, let title = self.docTitle {
            config.secondaryAttributedText = NSAttributedString(string: title, attributes: attributes)
        } else if option == .page, let pageNum = self.pageNumber {
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
            let viewModel = FTShelfItemsViewModel(selectedShelfItems: [])
            let controller = FTShelfItemsViewControllerNew(shelfItemsViewModel: viewModel, purpose: .linking, delegate: self)
            self.ftPresentFormsheet(vcToPresent: controller, hideNavBar: false)
        } else if option == .page, let docId = self.infoDelegate?.getTextLinkInfo()?.docUUID {
            if let info = self.infoDelegate?.getTextLinkInfo(), let document = info.currentDocument,  info.docUUID == document.documentUUID {
                // same document
                self.selectedDocument = document
                if let doc = document as? FTThumbnailableCollection {
                    self.showFinderPagesScreen(doc: doc, onCompletion: nil)
                }
            } else {
                FTNoteshelfDocumentProvider.shared.findDocumentItem(byDocumentId: docId) { docItem in
                    if let shelfItem = docItem {
                        let request = FTDocumentOpenRequest(url: shelfItem.URL, purpose: .read)
                        FTNoteshelfDocumentManager.shared.openDocument(request: request) { token, document, error in
                            if let doc = document as? FTThumbnailableCollection {
                                self.showFinderPagesScreen(doc: doc, onCompletion: {_ in
                                    if let document = doc as? FTDocumentProtocol {
                                        self.selectedDocument = document
                                        self.token = token
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } else if option == .linkTo {
            
        }
    }
}

extension FTTextEditLinkViewController: FTDocumentSelectionDelegate, FTPageSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        if let doc = document as? FTDocumentItemProtocol, let docId = doc.documentUUID {
            if var exstInfo = self.infoDelegate?.getTextLinkInfo() {
                exstInfo.docUUID = docId
                exstInfo.pageUUID = ""
                self.docTitle = document.displayTitle
                self.pageNumber = 1
                self.tableView?.reloadData()
                self.infoDelegate?.updateTextLinkInfo(exstInfo)
            }
        }
    }
    
    func didSelect(page: FTNoteshelfPage) {
        if var info = self.infoDelegate?.getTextLinkInfo(), nil != self.selectedDocument {
            info.pageUUID = page.uuid
            self.pageNumber = page.pageIndex() + 1
            self.closeOpenedDocumentIfNeeded()
            self.tableView?.reloadData()
            self.infoDelegate?.updateTextLinkInfo(info)
        }
    }
}
