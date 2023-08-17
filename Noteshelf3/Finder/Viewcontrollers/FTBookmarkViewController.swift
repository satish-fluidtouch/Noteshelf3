//
//  FTBookmarkViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 06/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

protocol FTBookmarkPageViewControllerDelegate: NSObjectProtocol {
    func refreshBookmarkButton(for pages: [FTPageProtocol])
    func removeBookMark(for pages: [FTPageProtocol])
}

class FTBookmarkViewController: UIViewController, FTPopoverPresentable {
    @IBOutlet var headerTitle: UILabel?
    var textField: UITextField?
    @IBOutlet var collectionView: UICollectionView?
    var pages = [FTPageProtocol]()
    weak var delegate:FTBookmarkPageViewControllerDelegate?
    var ftPresentationDelegate = FTPopoverPresentation()

    var bookmarkColors:[String] = ["C69C3C","F22F26","E0AD00","0AAE22","0068ED","9541BF","F629BD", "67666B"]
    var currentBookmarkColor: String = "C69C3C"

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(FTBookmarkColorCell.self, forCellWithReuseIdentifier: "FTBookmarkColorCell")
        headerTitle?.font = UIFont.clearFaceFont(for: .medium, with: 20)
        if let page = pages.first {
            if(!page.bookmarkColor.isEmpty) {
                self.currentBookmarkColor = page.bookmarkColor
            }
        }
        self.collectionView?.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    static  func showBookmarkController(fromSourceView sourceView:UIView, onController controller:UIViewController, pages: [FTPageProtocol]) {
        let bookmarkController = FTBookmarkViewController.instantiate(fromStoryboard: .finder)
        bookmarkController.pages = pages
        bookmarkController.delegate = controller as? any FTBookmarkPageViewControllerDelegate
        bookmarkController.ftPresentationDelegate.source = sourceView
        let contentSize = CGSize(width: 330, height: 336)
        controller.ftPresentPopover(vcToPresent: bookmarkController, contentSize: contentSize, hideNavBar: true)
    }
    
    func saveBookmarkPage() {
        pages.forEach { page in
            page.bookmarkTitle = self.textField?.text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
            page.bookmarkColor = self.currentBookmarkColor
            page.isBookmarked = true
        }
        self.delegate?.refreshBookmarkButton(for: pages)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView?.frame.width ?? .zero, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 26, left: 35, bottom: 26, right: 35)
    }
}

extension FTBookmarkViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  self.bookmarkColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.collectionView(collectionView, colorGrildCellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, colorGrildCellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FTBookmarkColorCell", for: indexPath as IndexPath)
        if let cell = cell as? FTBookmarkColorCell {
            let colorHexString: String = self.bookmarkColors[indexPath.row]
            let color =  UIColor.init(hexString: colorHexString)
            if colorHexString == currentBookmarkColor {
                cell.isSelected = true
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
            cell.configureCellWithColor(color: color)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: (self.collectionView?.frame.size.width)!, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTBookmarkColorSectionHeader", for: indexPath) as? FTBookmarkColorSectionHeader
            headerView?.textField?.delegate = self
            self.textField = headerView?.textField
            if let page = self.pages.first, page.isBookmarked {
                headerView?.textField?.text = page.bookmarkTitle
            }
            return headerView ?? UIView() as! UICollectionReusableView
        }
        if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FTBookmarkColorFooter", for: indexPath) as? FTBookmarkColorFooter
            footerView?.removeBookmarkButton?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            return footerView ?? UIView() as! UICollectionReusableView
        }
        return UICollectionReusableView()
    }
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let colorHexString: String = self.bookmarkColors[indexPath.row]
        currentBookmarkColor = colorHexString
        self.collectionView?.reloadData()
        saveBookmarkPage()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.delegate?.removeBookMark(for: pages)
    }
}

//MARK:- UITextFieldDelegate
extension FTBookmarkViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        saveBookmarkPage()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveBookmarkPage()
    }
}
