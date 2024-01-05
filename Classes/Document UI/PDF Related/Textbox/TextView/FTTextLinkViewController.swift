//
//  FTTextLinkViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 26/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

struct FTTextLinkInfo {
    var docUUID: String
    var pageUUID: String
    weak var currentDocument: FTDocumentProtocol?
}

class FTTextLinkViewController: UIViewController, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()
    @IBOutlet private weak var tableView: UITableView?
    private let viewModel = FTTextLinkViewModel()
    weak var delegate: FTTextLinkEditDelegate?
    
    private var linkInfo: FTTextLinkInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Linking"
        self.tableView?.register(FTTextLinkTableViewCell.self, forCellReuseIdentifier: FTTextLinkTableViewCell.cellIdentifier)
    }
    
    @discardableResult
    static func showTextLinkScreen(from controller: UIViewController, source: UIView, with linkInfo: FTTextLinkInfo) -> FTTextLinkViewController? {
        if let textLinkVc = UIStoryboard(name: "FTTextInputUI", bundle: nil).instantiateViewController(withIdentifier: "FTTextLinkViewController") as? FTTextLinkViewController {
            textLinkVc.linkInfo = linkInfo
            textLinkVc.ftPresentationDelegate.source = source
            textLinkVc.ftPresentationDelegate.sourceRect = source.frame
            let contentSize = CGSize(width: 320.0, height: 300.0)
            controller.ftPresentPopover(vcToPresent: textLinkVc, contentSize: contentSize, hideNavBar: false)
            return textLinkVc
        }
        return nil
    }
}

private class FTTextLinkTableViewCell: UITableViewCell {
    static let cellIdentifier = "FTTextLinkTableViewCell"
}

extension FTTextLinkViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int = 0
        if section == 0 {
            count = viewModel.linkSection.options.count
        } else if section == 1 {
            count = viewModel.textSection.options.count
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        if section == 0 {
            title = viewModel.linkSection.header
        } else if section == 1 {
            title = viewModel.textSection.header
        }
        return title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FTTextLinkTableViewCell.cellIdentifier, for: indexPath)
        var config = cell.defaultContentConfiguration()
        let attributes = [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 17.0)]
        if indexPath.section == 0 {
            let option = viewModel.linkSection.options[indexPath.row]
            config.attributedText = NSAttributedString(string: option.rawValue, attributes: attributes)
            config.image = option.image
        } else if indexPath.section == 1 {
            let option = viewModel.textSection.options[indexPath.row]
            config.attributedText = NSAttributedString(string: option.rawValue, attributes: attributes)
            config.image = option.image
        }
        cell.contentConfiguration = config
        cell.backgroundColor = UIColor.appColor(.white60)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = viewModel.linkSection.options[indexPath.row]
        if option == .linkSettings {
            if let editLinkVc = UIStoryboard(name: "FTTextInputUI", bundle: nil).instantiateViewController(withIdentifier: "FTTextEditLinkViewController") as? FTTextEditLinkViewController {
                editLinkVc.viewModel = FTTextEditLinkViewModel(delegate: self)
                self.navigationController?.pushViewController(editLinkVc, animated: true)
            }
        }
    }
}

extension FTTextLinkViewController: FTTextLinkInfoDelegate {
    func getTextLinkInfo() -> FTTextLinkInfo? {
        return self.linkInfo
    }
    
    func updateTextLinkInfo(_ info: FTTextLinkInfo) {
        self.linkInfo = info
        self.delegate?.updateTextLinkInfo(info)
    }
    
    func removeLink() {
        self.dismiss(animated: true) {
            self.delegate?.removeLink()
        }
    }
}
