//
//  FTOutlinesViewController.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTOutlinesViewControllerDelegate: NSObjectProtocol {
    func outlinesViewController(didSelectPage selectedPage: FTPageProtocol?)
    func outlinesViewController(showPlaceHolder: Bool)
}

class FTOutlinesViewController: UIViewController {
    @IBOutlet weak var treeView: CITreeView!
    @IBOutlet weak var searchContainer: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    weak var delegate: FTOutlinesViewControllerDelegate?
    var outlinesList: [FTPDFOutline] = [FTPDFOutline]()
    weak var currentDocument: FTNoteshelfDocument?
    weak var searchController: FTOutlineSearchViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchContainer?.isHidden = true
        self.treeView.register(UINib.init(nibName: "FTOutlineTableCell", bundle: nil), forCellReuseIdentifier: "FTOutlineTableCell")
        self.treeView.isScrollEnabled = false
    }
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    func refreshOutlines(with searchText: String){
        if !self.outlinesList.isEmpty {
            self.treeView.reloadDataWithoutChangingRowStates()
            self.searchText(didChangeTo: searchText)
            self.delegate?.outlinesViewController(showPlaceHolder: false)
            return
        }
        self.treeView.isHidden = true
        self.activityIndicator?.startAnimating()
        
        self.currentDocument?.pdfOutliner?.outlinesWithSearchText(searchText, onCompletion: {[weak self] (result) -> (Void) in
            self?.outlinesList.append(contentsOf: result)
            DispatchQueue.main.async {
                self?.activityIndicator?.stopAnimating()
                self?.treeView.isHidden = (self?.outlinesList.count ?? 0 == 0)
                self?.treeView.reloadData()
                self?.treeView.expandAllRows()
                if !searchText.isEmpty{
                    self?.searchText(didChangeTo: searchText)
                }
                self?.delegate?.outlinesViewController(showPlaceHolder: result.isEmpty)
            }
        })
    }
}

extension FTOutlinesViewController : CITreeViewDelegate {
    func treeView(_ treeView: CITreeView, heightForRowAt indexPath: IndexPath, with treeViewNode: CITreeViewNode) -> CGFloat {
        return 84
    }
    
    func treeViewNode(_ treeViewNode: CITreeViewNode, willExpandAt indexPath: IndexPath) {
        if let selectedCell = self.treeView.cellForRow(at: indexPath) as? FTOutlineTableCell{
            selectedCell.expandButton!.isSelected = true
        }
    }
    
    func treeViewNode(_ treeViewNode: CITreeViewNode, didExpandAt indexPath: IndexPath) {
        (treeViewNode.item as? FTPDFOutline)?.isOpen = true
        self.treeView.scrollRectToVisible(self.treeView.rectForRow(at: IndexPath.init(row: indexPath.row + 1, section: indexPath.section)), animated: true)
        self.delegate?.outlinesViewController(showPlaceHolder: false)
    }
    
    func treeViewNode(_ treeViewNode: CITreeViewNode, willCollapseAt indexPath: IndexPath) {
        if let selectedCell = self.treeView.cellForRow(at: indexPath) as? FTOutlineTableCell{
            selectedCell.expandButton!.isSelected = false
        }
    }
    
    func treeViewNode(_ treeViewNode: CITreeViewNode, didCollapseAt indexPath: IndexPath) {
        (treeViewNode.item as? FTPDFOutline)?.isOpen = false
        self.delegate?.outlinesViewController(showPlaceHolder: false)
    }

    func treeView(_ treeView: CITreeView, didSelectRowAt treeViewNode: CITreeViewNode, at indexPath: IndexPath) {
        if let outline = treeViewNode.item as? FTPDFOutline {
            self.delegate?.outlinesViewController(didSelectPage: outline.page)
        }
    }
    
    func treeView(_ treeView: CITreeView, didDeselectRowAt treeViewNode: CITreeViewNode, at indexPath: IndexPath) {
        if let parentNode = treeViewNode.parentNode{
            #if DEBUG
            print(parentNode.item)
            #endif            
        }
    }
    
    func willExpandTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    func didExpandTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {
    }
    
    func willCollapseTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {}
    
    func didCollapseTreeViewNode(treeViewNode: CITreeViewNode, atIndexPath: IndexPath) {
    }
}

extension FTOutlinesViewController : CITreeViewDataSource {
    func treeViewSelectedNodeChildren(for treeViewNodeItem: Any) -> [Any] {
        if let dataObj = treeViewNodeItem as? FTPDFOutline {
            return dataObj.children
        }
        return []
    }
    
    func treeViewDataArray() -> [Any] {
        return self.outlinesList
    }
    
    func treeView(_ treeView: CITreeView, cellForRowAt indexPath: IndexPath, with treeViewNode: CITreeViewNode) -> UITableViewCell {
        let cell = treeView.dequeueReusableCell(withIdentifier: "FTOutlineTableCell") as! FTOutlineTableCell
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        guard let outline = treeViewNode.item as? FTPDFOutline else{
            return cell
        }
        
        cell.titleLabel?.text = outline.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        cell.pageNumberLabel?.text = outline.pageNumberInNotebook
        if let associatedPage = outline.page as? FTThumbnailable{
            cell.setThumbnailImage(usingPage: associatedPage)
        }
        else{
           cell.thumbnailImageView?.image = UIImage(named: "finder-empty-pdf-page")
        }
        cell.expandButton?.isSelected = treeViewNode.expand
        cell.expandButton?.isHidden = !outline.hasChildren
        cell.expandButton?.tag = indexPath.row
        cell.expandButton?.addTarget(self, action: #selector(FTOutlinesViewController.expandButtonClicked(_:)), for: UIControl.Event.touchUpInside)
        
        let leftPadding: Int =  20
        cell.indentationConstraint?.constant = CGFloat(leftPadding + (treeViewNode.level * 10))
        #if !NS2_SIRI_APP
        cell.thumbnailImageView?.layer.borderColor = UIColor.appColor(.black20).cgColor
        #endif
        cell.thumbnailImageView?.layer.borderWidth = 1.0
        return cell
    }
    @objc func expandButtonClicked(_ sender: UIButton){
        
        var cell: FTOutlineTableCell? // sender.tag is not upfdating due to reloading issues in treeview, so workaround for getting right cell and indexPath
        var superView = sender.superview
        while(cell == nil){
            if(superView is FTOutlineTableCell){
                cell = superView as? FTOutlineTableCell
                break
            }
            else{
                superView = superView?.superview
            }
        }
        if let selectedCell = cell{
            if let indexPath = self.treeView.indexPath(for: selectedCell){
                self.treeView.expandCollapseRow(at: indexPath)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchController = segue.destination as? FTOutlineSearchViewController {
            self.searchController = searchController
            self.searchController?.delegate = self.delegate
            self.searchController?.currentDocument = self.currentDocument
        }
    }
}

extension FTOutlinesViewController {
    func searchText(didChangeTo searchKey: String) {
        self.searchController?.searchTextDidChange(to: searchKey)

        if !searchKey.isEmpty{
            self.searchContainer?.isHidden = false
        }
        else{
            self.searchContainer?.isHidden = true
        }
    }
}
