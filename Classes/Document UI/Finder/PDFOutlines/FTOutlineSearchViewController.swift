//
//  FTOutlineSearchViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 11/03/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTOutlineSearchViewController: UIViewController {

    fileprivate var searchResults: [FTPDFOutline] = [FTPDFOutline]()
    var currentDocument: FTNoteshelfDocument?
    weak var delegate: FTOutlinesViewControllerDelegate?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var viewNoResults: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib.init(nibName: "FTOutlineTableCell", bundle: nil), forCellReuseIdentifier: "FTOutlineTableCell")
    }
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    func searchTextDidChange(to key: String){
        self.searchResults.removeAll()
        self.tableView.reloadData()
        self.activityIndicator?.startAnimating()
        self.viewNoResults.isHidden = true
        
        self.currentDocument?.pdfOutliner?.outlinesWithSearchText(key, onCompletion: {[weak self] (result) -> (Void) in
            self?.searchResults.append(contentsOf: result)
            DispatchQueue.main.async {
              self?.viewNoResults.isHidden = self?.searchResults.count ?? 0 > 0
              self?.activityIndicator?.stopAnimating()
              self?.tableView.reloadData()
            }
        })
    }
}
extension FTOutlineSearchViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 71.0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "FTOutlineTableCell", for: indexPath)
        tableCell.selectionStyle = UITableViewCell.SelectionStyle.none
        let outline = self.searchResults[indexPath.row]
        if let cell = tableCell as? FTOutlineTableCell{
            cell.titleLabel?.text = outline.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            cell.pageNumberLabel?.text = outline.pageNumberInNotebook
            if let associatedPage = outline.page as? FTThumbnailable{
                cell.setThumbnailImage(usingPage: associatedPage)
            }
            else{
                cell.thumbnailImageView?.image = UIImage(named: "finder-empty-pdf-page")
            }
            cell.expandButton?.isHidden = true
            let leftPadding: Int = 24
            cell.indentationConstraint?.constant = CGFloat(leftPadding)
            #if !NS2_SIRI_APP && !NOTESHELF_ACTION
            cell.thumbnailImageView?.layer.borderColor = UIColor.appColor(.black50).cgColor
            #endif
            cell.thumbnailImageView?.layer.borderWidth = 1.0
        }
        return tableCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let outline = self.searchResults[indexPath.row]
        self.delegate?.outlinesViewController(didSelectPage: outline.page)
    }
}
