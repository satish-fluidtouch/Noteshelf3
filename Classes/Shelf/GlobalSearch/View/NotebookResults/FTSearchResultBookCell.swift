//
//  FTSearchResultBookCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon
import FTNewNotebook

class FTGroupCoverInfo {
    var image: UIImage?
    var size: CGSize

    init(image: UIImage?, size: CGSize) {
        self.image = image
        self.size = size
    }
}

class FTSearchResultBookCell: FTTraitCollectionViewCell, FTShelfItemCellProgressUpdate {
    @IBOutlet weak var coverPreviewContainer: UIView?
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: FTStyledLabel?
    @IBOutlet weak var categoryTitleLabel: UILabel?
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var pieProgressView: FTRoundProgressView?
    @IBOutlet weak var shadowImageView: UIImageView?
    @IBOutlet private weak var favoriteView: UIImageView!
    
    @IBOutlet private weak var cover1WidthConstraint: NSLayoutConstraint?
    @IBOutlet private weak var cover1HeightConstraint: NSLayoutConstraint?

    @IBOutlet private weak var titleLabelHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var categoryTitleHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var categoryTitleBottomConstraint: NSLayoutConstraint?
    
    var shelfItem: FTShelfItemProtocol?
    var animType : FTAnimType = FTAnimType.none;

    var progressObserver: NSKeyValueObservation?
    var downloadedStatusObserver: NSKeyValueObservation?
    var uploadingStatusObserver: NSKeyValueObservation?
    var downloadingStatusObserver: NSKeyValueObservation?
    var uploadedStatusObserver: NSKeyValueObservation?

    private(set) var toShowEqualCorners: Bool = false {
        didSet {
            if toShowEqualCorners {
                self.coverImageView?.layer.cornerRadius = GlobalSearchConstants.BookCoverThumbnailRadius.equiRadius
                self.shadowImageView?.image = UIImage(named: "noCoverNBShadow")
                let scalled = self.shadowImageView?.image?.resizableImage(withCapInsets: UIEdgeInsets(top: 12, left: 20, bottom: 60, right: 20), resizingMode: .stretch)
                self.shadowImageView?.image = scalled
            } else {
                let leftRadius = GlobalSearchConstants.BookCoverThumbnailRadius.left
                let rightRadius = GlobalSearchConstants.BookCoverThumbnailRadius.right
                self.coverImageView?.roundCorners(topLeft: leftRadius, topRight: rightRadius, bottomLeft: leftRadius, bottomRight: rightRadius)
                self.shadowImageView?.image = UIImage(named: "searchResultBook_shadow")
                let scalled = self.shadowImageView?.image?.resizableImage(withCapInsets: UIEdgeInsets(top: 6, left: 18, bottom: 30, right: 18), resizingMode: .stretch)
                self.shadowImageView?.image = scalled
            }
        }
    }

    private var shouldShowFavorite: Bool = false {
        didSet {
            self.favoriteView.isHidden = !shouldShowFavorite
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel?.textColor = UIColor.label
        self.titleLabel?.font = UIFont.appFont(for: .regular, with: 15)
        self.statusImageView?.image = UIImage(systemName: "icloud.and.arrow.down")?.withRenderingMode(.alwaysTemplate).withConfiguration(UIImage.SymbolConfiguration(font: UIFont.appFont(for: .medium, with: 12))).withTintColor(.black.withAlphaComponent(0.2))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let reqSize = self.isRegular ? GlobalSearchConstants.BookThumbnailSize.regular : GlobalSearchConstants.BookThumbnailSize.compact
        self.cover1WidthConstraint?.constant = reqSize.width
        self.cover1HeightConstraint?.constant = reqSize.height
    }

    fileprivate func configureView(item : FTShelfItemProtocol) {
        var token: String?
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: {(image, imageToken) in
            if let img = image, token == imageToken {
                self.coverImageView?.image = img
                let reqSize = self.isRegular ? GlobalSearchConstants.BookThumbnailSize.regular : GlobalSearchConstants.BookThumbnailSize.compact
                self.cover1WidthConstraint?.constant = reqSize.width
                self.cover1HeightConstraint?.constant = reqSize.height
                self.layoutIfNeeded()
                if img.isDefaultCover || img.hasNoCover {
                    self.toShowEqualCorners = true
                } else {
                    self.toShowEqualCorners = false
                }
            } else {
                self.toShowEqualCorners = true
            }
        })
        self.shouldShowFavorite = FTRecentEntries.isFavorited(item.URL)
        self.updateDownloadStatusFor(item: item)
        NotificationCenter.default.addObserver(self, selector: #selector(self.makeFavorite(_:)), name: Notification.Name.shelfItemMakeFavorite, object: nil)
    }

    @objc func makeFavorite(_ notification : Notification){
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                self.shouldShowFavorite = FTRecentEntries.isFavorited(item.URL)
            }
        }
    }

    deinit {
        self.stopObservingProgressUpdates()
        NotificationCenter.default.removeObserver(self, name: .shelfItemMakeFavorite, object: nil)
    }
    
    func configureCellWithItem(_ searchItem: FTSearchResultBookProtocol,
                                 searchKey: String){
        self.statusImageView?.image = nil
        if let item = searchItem.shelfItem {
            self.stopObservingProgressUpdates()
            self.shelfItem = item
            self.startObservingProgressUpdates()
            self.coverImageView.image = UIImage(named: "shelfDefaultNoCover")
            self.shadowImageView?.image = nil
            self.coverImageView?.layer.cornerRadius = 0.0
            self.configureView(item: item)
            self.titleLabel?.setTitle(title: searchItem.title, highlight: searchKey)
            self.categoryTitleLabel?.text = item.shelfCollection.displayTitle
        }
    }

    func didFinishUpdating() {
        if let item = self.shelfItem {
            self.configureView(item: item)
        }
    }
}

extension UILabel{
    func setTitle(title: String, highlight: String) {
    let attributedText = NSMutableAttributedString(string: title)
#if !targetEnvironment(macCatalyst)
   let range = (title as NSString).range(of: highlight, options: .caseInsensitive)
    if range.location != NSNotFound {
        let strokeTextAttributes: [NSAttributedString.Key: Any] = [
            .font: self.font.boldFont()
        ]
        attributedText.addAttributes(strokeTextAttributes, range: range)
    }
#endif
    self.attributedText = attributedText
  }
}
