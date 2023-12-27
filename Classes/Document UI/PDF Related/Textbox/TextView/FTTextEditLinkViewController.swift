//
//  FTTextEditLinkViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTDocumentSelectionDelegate: AnyObject {
    func didSelect(document: FTShelfItemProtocol)
}

class FTTextEditLinkViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView?
    weak var document: FTDocumentProtocol?
    weak var delegate: FTDocumentSelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.register(FTTextEditLinkTableViewCell.self, forCellReuseIdentifier: FTTextEditLinkTableViewCell.cellIdentifier)
    }
    
    @objc func removeLinkButtonTapped() {
        
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
//            controller.delegate = self
            self.ftPresentFormsheet(vcToPresent: controller, hideNavBar: false)
        } else if option == .page {
            
        } else if option == .linkTo {
            
        }
    }
}

extension FTTextEditLinkViewController: FTDocumentSelectionDelegate {
    func didSelect(document: FTShelfItemProtocol) {
        self.delegate?.didSelect(document: document)
    }
}
