
//
//  FTThumbnailsFilterToolbarViewController.swift
//  Noteshelf
//
//  Created by Siva on 31/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTThumbnailsFilterToolbarViewControllerDelegate: NSObjectProtocol {
    var viewControllerForPresentation: UIViewController! {get};
    
    func filterByBookmarkToggled(from thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController);
    func filterByTagToggled(from thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController);
    func filterBySearchToggled(from thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController);
    func clearTagsClicked(from thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController);
    func thumbnailsFilterToolbarViewController(_ thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController, searchKeywordDidChange keyword: String);
    func thumbnailsFilterToolbarViewController(_ thumbnailsFilterToolbarViewController: FTThumbnailsFilterToolbarViewController?, didSelectSegment segmentIndex: Int);
}

class FTThumbnailsFilterToolbarViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var filterStackView: UIStackView!
    @IBOutlet weak var buttonBookmark: UIButton!
    @IBOutlet weak var buttonTag: UIButton!
    @IBOutlet weak var selectedTagsCountLabel: FTStyledLabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var viewBookmarks: UIView!
    @IBOutlet weak var bookmarksViewBackground: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewBackground: UIView!
    @IBOutlet weak var searchTextField: UITextField!

    @IBOutlet weak var viewTags: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewLearnMore: UIView!
    @IBOutlet weak var tagHelpLabel: FTStyledLabel!
    @IBOutlet weak var learnMoreLabel: FTStyledButton!
    @IBOutlet weak var clearTagsView: UIView!
    @IBOutlet weak var clearTagsButton: FTStyledButton!

    @IBOutlet weak var viewTagsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentCenterXConstraint: NSLayoutConstraint!
    weak var delegate: FTThumbnailsFilterToolbarViewControllerDelegate!

    //MARK:- UIViewController
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        
        let layoutRightInset: CGFloat;
        if (self.isIphoneX()) {
            let safeAreaInsets = self.originalSafeAreaInsets();
            
            layoutRightInset = safeAreaInsets.right / 2;
        }
        else {
            layoutRightInset = 0;
        }
        self.contentCenterXConstraint.constant = -layoutRightInset;
        self.view.updateConstraintsIfNeeded();
        self.scrollView.layoutIfNeeded();

        self.searchViewBackground.makeCornersRounded(on: [.topLeft, .bottomLeft, .bottomRight], withRadius: 4);
        self.bookmarksViewBackground.makeCornersRounded(on: [.topRight, .bottomLeft, .bottomRight], withRadius: 4);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentControl.setTitleTextAttributes([NSFontAttributeName : UIFont.applicationDefaultRegularFont(ofSize: 11), NSForegroundColorAttributeName : UIColor.white], for: UIControlState.selected)
        self.segmentControl.setTitleTextAttributes([NSFontAttributeName : UIFont.applicationDefaultRegularFont(ofSize: 11), NSForegroundColorAttributeName : UIColor.white.withAlphaComponent(0.5)], for: UIControlState.normal)
        self.segmentControl.setTitle(NSLocalizedString("Thumbnails", comment: "Thumbnails"), forSegmentAt: 0)
        self.segmentControl.setTitle(NSLocalizedString("List", comment: "List"), forSegmentAt: 1)
//        self.segmentControl.layer.cornerRadius = 15.0
//        self.segmentControl.layer.borderColor = UIColor.white.cgColor

        self.view.layer.zPosition = 1000;
        
        self.buttonTag.makeAllCornersRounded(withRadius: 4);

        self.searchButton.makeAllCornersRounded(withRadius: 4);

        self.searchTextField.setDefaultStyle(.style2);
        self.searchTextField.setStyledPlaceHolder(NSLocalizedString("SearchText", comment: "SearchText"), style: .style3);
        
        let iconClearButton = UIImage(named: "iconclosetab")!;
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: iconClearButton.size.width + 12, height: 15));
        clearButton.setImage(iconClearButton, for: .normal);
        clearButton.addTarget(self, action: #selector(self.clearText), for: .touchUpInside);
        clearButton.contentHorizontalAlignment = .left;
        self.searchTextField.rightView = clearButton;
        self.searchTextField.rightViewMode = .whileEditing;
    }
    
    deinit {
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }

    //MARK:- Actions
    @IBAction func filterByBookmarkClicked() {
        self.delegate.filterByBookmarkToggled(from: self);
    }
    
    @IBAction func filterByTagClicked() {
        self.delegate.filterByTagToggled(from: self);
    }
    
    @IBAction func filterBySearchClicked() {
        self.delegate.filterBySearchToggled(from: self);
    }

    @IBAction func searchKeywordDidChange() {
        self.delegate.thumbnailsFilterToolbarViewController(self, searchKeywordDidChange: self.searchTextField.text ?? "");
    }
    
    @IBAction func learnMoreClicked() {
        FTZenDeskManager.shared().showArticle("360017726533", in: self.delegate.viewControllerForPresentation, completion: nil);
    }
    
    @IBAction func clearTagsClicked() {
        self.delegate.clearTagsClicked(from: self);
    }
    @IBAction func segmentDidChange(_ sender:UISegmentedControl) {
        self.delegate.thumbnailsFilterToolbarViewController(self, didSelectSegment: sender.selectedSegmentIndex)
    }
    //MARK:- Helpers
    @objc fileprivate func clearText() {
        self.searchTextField.text = "";
        self.delegate.thumbnailsFilterToolbarViewController(self, searchKeywordDidChange: "");
    }
    
    //MARK:- UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        self.searchKeywordDidChange();
        return true;
    }
}
