//
//  FTFinderThumbnailViewCell.swift
//  Noteshelf
//
//  Created by Siva on 06/01/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTFinderThumbnailViewCell: UICollectionViewCell {
    @IBOutlet weak var compactModeDividerView: UIView!
    @IBOutlet weak var imageViewPage: UIImageView?
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var selectionBadge: UIImageView?
    @IBOutlet weak var imageViewPageCurrent: UIImageView?
    @IBOutlet weak var buttonBookmark: UIButton?
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var regularModeDividerView: UIView!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var tagsLabelView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet weak var tagsCounButton: UIButton!
    @IBOutlet weak var searchHighlightView: FTSelectionHighlightView?
    @IBOutlet weak var labelPageNumber: FTCustomLabel!
    var shouldShowVerticalDivider = false
    @IBOutlet weak var searchHighlightViewWidthConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var imageViewPageSelectionWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewPageWidthConstraint: NSLayoutConstraint!
    
    fileprivate var observerAdded = false;

    var pdfSize: CGSize! {
        didSet {
            self.searchHighlightViewWidthConstraint?.constant = self.pdfSize.width;
            self.updateConstraintsIfNeeded()
        }
    }
    var pageSize: CGSize!
    var selectedTab = FTFinderSelectedTab.thumnails

    weak var page: FTThumbnailable? {
        willSet{
            self.removeSearchObserver();
        }
        didSet {
            self.addSearchObserver();
        }
    }

    override var canBecomeFocused: Bool {
        return false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let dividerView = shouldShowVerticalDivider ? compactModeDividerView : regularModeDividerView
        if let shelfCollectionViewLayoutAttributes = layoutAttributes as? FTFinderCollectionViewLayoutAttributes {
            if let uuid = page?.uuid , shelfCollectionViewLayoutAttributes.focusedUUID == uuid {
                dividerView?.isHidden = false
            }
            else {
                dividerView?.isHidden = true
            }
        } else {
            dividerView?.isHidden = true
        }
    }
    
    //MARK:- Custom
    func setAsCurrentVisiblePage() {
        self.imageViewPageCurrent?.isHidden = false
        self.imageViewPageCurrent?.layer.borderColor = UIColor.appColor(.accent).cgColor
        self.imageViewPageCurrent?.layer.borderWidth = 2.0
        self.imageViewPageCurrent?.layer.cornerRadius = 10
    }
    
    func setIsSelected(_ selected : Bool) {
        self.imageViewPageCurrent?.isHidden = true
        if let selectionBadge = selectionBadge {
            selectionBadge.image = selected ? UIImage(named: "selection_checkMark") : UIImage(named: "shelfItemSelectionMode")
            selectionBadge.tintColor = selected ? UIColor.appColor(.accent) : .white
        }
    }
    
    func updateTagsPill() {
        if let page {
            if page.tags().isEmpty {
                stackView.arrangedSubviews.forEach { subview in
                    subview.isHidden = true
                }
            } else {
                stackView.arrangedSubviews.forEach { subview in
                    subview.isHidden = false
                }
                let tags = page.tags()
                let count = tags.count
                tagsCounButton.isHidden = (count == 1)
                if let firstTag = page.tags().first {
                    tagsLabel.text = "# \(firstTag)"
                }
                tagsCounButton.setTitle("+ \(count - 1)", for: .normal)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageViewPage?.isAccessibilityElement = true;
        configure()
        tagsLabelView.layer.cornerRadius = 6
        tagsCounButton.layer.cornerRadius = 6
        tagsCounButton.isUserInteractionEnabled = false
    }

    private func configure() {
        if let selectionBadge = selectionBadge {
            selectionBadge.layer.masksToBounds = false
            selectionBadge.layer.shadowColor = UIColor.black.cgColor
            selectionBadge.layer.shadowOpacity = 0.2
            selectionBadge.layer.shadowOffset = CGSize(width: 1, height: 1)
            selectionBadge.layer.shadowRadius = 4
            
            self.layer.masksToBounds = false
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = 0.08
            self.layer.shadowOffset = CGSize(width: 0, height: 12)
            self.layer.shadowRadius = 20
            self.imageViewPage?.layer.cornerRadius = 0 
        }
    }
    
    var editing = false {
        didSet {
            if !self.editing {
                //self.setIsSelected(false);
            }
        }
    };
    
    func setThumbnailImage(usingPage page: FTThumbnailable) {
        self.removeObservers();
        self.page = page;
        self.addObservers()
        self.imageViewPage?.layer.cornerRadius = 10
        self.updateThumbnailImage();

        if let pageText = self.labelPageNumber?.text {
            self.imageViewPage?.accessibilityLabel = "Page ".appending(pageText);
        }
    }
    
    //MARK:- KVO
    private func addObservers() {
        if let page = self.page {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didReceiveNotifcationForGenerateThumbnail(_:)),
                                                   name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                   object: page);
        }
    }

    private func removeObservers() {
        if let page = self.page {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                      object: page);
        }
    }

    @objc func didReceiveNotifcationForGenerateThumbnail(_ notification : Notification)
    {
        if(!Thread.current.isMainThread) {
            runInMainThread { [weak self] in
                self?.didReceiveNotifcationForGenerateThumbnail(notification);
            }
            return;
        }
        
        if let pageObject = notification.object as? FTPageProtocol
            ,let curPage = self.page
            ,pageObject.uuid == curPage.uuid {
            self.updateThumbnailImage();
        }
    }
    
    private func updateThumbnailImage()
    {
        self.imageViewPage?.contentMode = UIView.ContentMode.scaleAspectFit;
        self.page?.thumbnail()?.thumbnailImage(onUpdate: { [weak self] (image, uuidString) in
            if let currentPage = self?.page, currentPage.uuid == uuidString {
                self?.imageViewPage?.image = image;
                var isImageLoaded: Bool = false;
                self?.imageViewPage?.contentMode = UIView.ContentMode.scaleToFill;
                if nil == image {
                    self?.imageViewPage?.image = UIImage(named: "finder-empty-pdf-page");
                    self?.imageViewPage?.contentMode = UIView.ContentMode.scaleToFill;
                }
                else {
                    self?.activityIndicatorView?.stopAnimating();
                    isImageLoaded = true;
                }
                if(currentPage.thumbnail()?.shouldGenerateThumbnail ?? false) {
//                    self?.addObservers();
                }
                self?.updateBookmarkButtonTrailing(withImageLoadedStatus: isImageLoaded);
                if(isImageLoaded) {
                    self?.didChangeSearchresults(nil);
                }
            }
        });
    }

    @objc func pageIsReleased(_ notification: Notification) {
        if let pageReleased = notification.object as? FTThumbnailable, let page = self.page,  pageReleased.uuid == page.uuid {
            self.removeObservers();
        }
    }
    
    private func updateBookmarkButtonTrailing(withImageLoadedStatus status: Bool) {
        if status {
            self.imageViewPageWidthConstraint.constant = self.pdfSize.width;
            self.imageViewHeightConstraint.constant = self.pdfSize.height
        }
        else {
            self.imageViewPageWidthConstraint.constant = self.pdfSize.width;
            self.imageViewHeightConstraint.constant = self.pdfSize.height
        }
    }
    
    //MARK:- NSObject
    deinit {
        self.removeObservers();
        #if DEBUG
       // debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
    
    fileprivate func addSearchObserver()
    {
        if let pdfPage = self.page, selectedTab == .search {
            let notificationName = "DidChangeSearchResults_".appending(pdfPage.uuid);
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(FTFinderThumbnailViewCell.didChangeSearchresults(_:)),
                                                   name: NSNotification.Name(rawValue: notificationName),
                                                   object: nil);
        }
    }
    
    fileprivate func removeSearchObserver()
    {
        if let pdfPage = self.page {
            let notificationName = "DidChangeSearchResults_".appending(pdfPage.uuid);
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name(rawValue: notificationName),
                                                      object: nil);
        }
    }
    
    @objc func didChangeSearchresults(_ notification : Notification?)
    {
        if let searchPage = self.page as? FTPageSearchProtocol, let localPDFSize = self.pdfSize {
            let annotationScale = localPDFSize.width/self.page!.pdfPageRect.size.width;
            let scale = (page as! FTPageProtocol).pdfscale!(inRect: CGRect.init(origin: CGPoint.zero, size: self.pdfSize));
            self.searchHighlightView?.renderSearchItems(items: searchPage.searchingInfo?.searchItems,
                                                        pdfScale: scale,
                                                        annotationScale: annotationScale);
        }
    }
}
