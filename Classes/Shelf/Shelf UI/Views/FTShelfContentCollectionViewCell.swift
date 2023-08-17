//
//  FTShelfContentCollectionViewCell.swift
//  Noteshelf
//
//  Created by Paramasivan on 18/10/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

protocol FTShelfContentCollectionViewCellDelegate: AnyObject {
    func shelfContentCollectionViewCell(shelfContentCollectionViewCell: FTShelfContentCollectionViewCell, didClickRenameWith shelfItem: FTShelfItemProtocol);
}

class FTShelfContentCollectionViewCell: UICollectionViewCell , FTShelfItemCellProgressUpdate {
    var latestPointTimeStamp: TimeInterval = 0.0
    var latestPoint: CGPoint = CGPoint.zero {
        didSet {
            self.latestPointTimeStamp = Date().timeIntervalSinceReferenceDate
            if self.latestPoint.equalTo(CGPoint.zero) {
                self.latestPointTimeStamp = 0.0
            }
        }
    }

    @IBOutlet weak var groupingBackgroundView: UIView?
    @IBOutlet weak var bookOpenSpinner: FTBookOpeningSpinner?
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverImageView2: UIImageView?
    @IBOutlet weak var coverImageView3: UIImageView?
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var selectionBorderImageView: UIImageView!
    @IBOutlet weak var titleLabel: FTStyledLabel!
    @IBOutlet weak var subTitleLabel: FTStyledLabel!
    @IBOutlet weak var bookLocationLabel: UILabel?
    @IBOutlet weak var renameView: UIView?
    @IBOutlet weak var renameButton: UIButton?
    @IBOutlet weak var renameLabel: FTStyledLabel?
    @IBOutlet weak var shadowImageView: FTShelfItemShadowImageView!
    @IBOutlet weak var shadowImageView2: FTShelfItemShadowImageView?
    @IBOutlet weak var shadowImageView3: FTShelfItemShadowImageView?
    
    @IBOutlet weak var booksContainerView: UIView!
    
    @IBOutlet weak var coverImageTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?
    //To avoid UI glitch when opens context menu for group
    @IBOutlet weak var coverImageCenterAdjustConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var pieProgressView: FTRoundProgressView?
    @IBOutlet weak var selectCellImage : UIImageView?
    var progressObserver: NSKeyValueObservation?
    var downloadedStatusObserver: NSKeyValueObservation?
    var uploadingStatusObserver: NSKeyValueObservation?
    var downloadingStatusObserver: NSKeyValueObservation?
    var uploadedStatusObserver: NSKeyValueObservation?
    
    var toolbarMode: FTToolbarMode = .normal {
        didSet{
            self.updateUI();
        }
    };

    var showSelection: Bool = false {
        didSet {
            self.selectionBorderImageView.isHidden = !self.showSelection;
            self.updateUI();
        }
    }
    
    override var description: String {
        return "\(self.shelfItem) -> \(self.shelfItem?.displayTitle)";
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    weak var delegate: FTShelfContentCollectionViewCellDelegate?
    var documentUUID: String?

    var shelfItem: FTShelfItemProtocol?
    var observerAdded = false;
    var animType : FTAnimType = FTAnimType.none;
    
    private var groupIconAttributedString:NSAttributedString!
    private var folderIconAttributedString:NSAttributedString!

    //MARK:- UIView
    override func layoutSubviews() {
        super.layoutSubviews();
       
        var topConstraint: CGFloat;
        if self.isRegularClass() == true {
            topConstraint = 34;
            if self.shelfItem is FTGroupItemProtocol {
                self.shadowImageView3?.isHidden = false
                self.coverImageView3?.isHidden = false
            }
        }
        else {
            topConstraint = 20;
            if self.shelfItem is FTGroupItemProtocol {
                self.shadowImageView3?.isHidden = true
                self.coverImageView3?.isHidden = true
            }
        }
        if UserDefaults.standard.bool(forKey: "Shelf_ShowDate") == false {
            topConstraint += 11;
        }
        self.coverImageTopConstraint?.constant = topConstraint;
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.kernValue = -0.4
        self.subTitleLabel.kernValue = -0.4
        coverImageView.tag = 0
        
        coverImageView2?.tag = 1
        coverImageView3?.tag = 2
        
        self.renameLabel?.style = FTLabelStyle.style4.rawValue
        self.bookOpenSpinner?.isHidden = true
        
        let groupIconWithSpaceAttributedString = NSMutableAttributedString();
        let groupIconAttachment = NSTextAttachment();
        groupIconAttachment.image = UIImage(named: "iconfolder")!;
        groupIconAttachment.bounds = CGRect.init(x: 0, y: -1, width: groupIconAttachment.image!.size.width, height: groupIconAttachment.image!.size.height);
        groupIconWithSpaceAttributedString.append(NSAttributedString(attachment: groupIconAttachment));
        groupIconWithSpaceAttributedString.append(NSAttributedString.init(string: " "));
        self.groupIconAttributedString = groupIconWithSpaceAttributedString
        
        // Folder icon update is seperated to a method to reuse for userinterface style change
        self.updateFolderIconAttributedString()
        self.accessibiltyElemet.isAccessibilityElement = true;
        self.accessibiltyElemet.accessibilityTraits = UIAccessibilityTraits.none;
        self.accessibilityElements = [self.coverImageView,self.renameButton];
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSubtitleLabelColor), name: Notification.Name.FTShelfThemeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeLoader(_:)), name: Notification.Name.shelfItemRemoveLoader, object: nil)
    }
    deinit {
        self.stopObservingProgressUpdates()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.shelfItemRemoveLoader, object: nil)
    }
    
    func didFinishUpdating() {
        if let item = self.shelfItem {
            self.configureView(item: item)
        }
    }
    
    private func updateFolderIconAttributedString() {
        let folderIconWithSpaceAttributedString = NSMutableAttributedString()
        let folderIconAttachment = NSTextAttachment()
        if let bookLocIcon = UIImage(named: "bookLocationIcon") {
            folderIconAttachment.image = bookLocIcon.withTintColor(UIColor.label)
        }
        folderIconAttachment.bounds = CGRect.init(x: 0, y: -2, width: folderIconAttachment.image!.size.width, height: folderIconAttachment.image!.size.height);
        folderIconWithSpaceAttributedString.append(NSAttributedString(attachment: folderIconAttachment));
        folderIconWithSpaceAttributedString.append(NSAttributedString.init(string: " "));
        self.folderIconAttributedString = folderIconWithSpaceAttributedString
    }

    @objc func updateSubtitleLabelColor() {
        if FTShelfThemeStyle.defaultTheme().isMojaveTheme() {
            let color = UIColor.white
            self.subTitleLabel.textColor = color.withAlphaComponent(0.7)
        } else {
            self.subTitleLabel.textColor = UIColor.appColor(.black70)
        }
    }
   
    //MARK:- UICollectionReusableView
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        let shelfCollectionViewLayoutAttributes = layoutAttributes as! FTShelfCollectionViewLayoutAttributes;
        if let _sehlfitme = self.shelfItem,
            shelfCollectionViewLayoutAttributes.focusedUUID == _sehlfitme.uuid {
            self.showGroupingMode();
        }
        else {
            self.hideGroupingMode();
        }
        self.updateAccessories();
    }
    
    //MARK:- Layout
    func updateAccessories() {
        if self.toolbarMode == .edit {
            self.subTitleLabel.isHidden = true;
            self.renameView?.isHidden = false;
        }
        else {
            self.subTitleLabel.isHidden = false;
            self.renameView?.isHidden = true;
        }
    }
    
    private func updateUI() {
        #if targetEnvironment(macCatalyst)
        self.selectCellImage?.isHidden = true
        #else
        if (self.toolbarMode == .normal) {
            self.selectCellImage?.isHidden = true
            return
        }
        
        self.selectCellImage?.isHidden = false
        if(self.showSelection) {
            self.selectCellImage?.image =  UIImage(named: "iconCheckBadge")
        }
        else {
            self.selectCellImage?.image =  UIImage(named: "checkBadgeOff")
        }
        #endif
    }
    
    //MARK:- Grouping
    func showGroupingMode() {
        self.groupingBackgroundView?.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8);
        UIView.animate(withDuration: 0.3) {
            self.groupingBackgroundView?.alpha = 1;
            self.groupingBackgroundView?.transform = CGAffineTransform.identity;
        }
    }
    
    func hideGroupingMode() {
        UIView.animate(withDuration: 0.3) {
            self.groupingBackgroundView?.alpha = 0;
        }
    }
    
    func configureView(item : FTShelfItemProtocol)
    {
        self.updateSubtitleLabelColor();
        self.accessibiltyElemet.accessibilityTraits = UIAccessibilityTraits.none;
        self.titleLabelTopConstraint?.constant = 45
        self.statusImageView?.image = nil;
        if (nil == self.shelfItem) || (self.shelfItem!.URL != item.URL) {
            self.stopAnimation();
            self.observeDownloadedStatusIfNeeded(forShelfItem: item);
        }
        self.shelfItem = item;
        self.startObservingProgressUpdates()
        
        self.shadowImageView2?.isHidden = true;
        self.shadowImageView3?.isHidden = true;
        self.coverImageView2?.isHidden = true;
        self.coverImageView3?.isHidden = true;
        
        let defaultCoverImage = UIImage(named: "covergray");
        self.coverImageView.image = defaultCoverImage;
        self.coverImageView2?.image = defaultCoverImage;
        self.coverImageView3?.image = defaultCoverImage;
        self.updateTextFiledFrame();
        
        self.titleLabel.isHidden = false;
        if let groupShelfItem = item as? FTGroupItemProtocol {
            self.coverImageView2?.isHidden = false;
            self.shadowImageView2?.isHidden = false;
            self.coverImageCenterAdjustConstraint?.constant = (8 * 0.5)
            if self.isRegularClass() {
                self.coverImageCenterAdjustConstraint?.constant = (16 * 0.5)
                self.shadowImageView3?.isHidden = false
                self.coverImageView3?.isHidden = false
            }
            self.updateTextFiledFrame()
            self.accessibiltyElemet.accessibilityLabel = groupShelfItem.displayTitle;
            
            let attributedTitle = NSMutableAttributedString();
            attributedTitle.append(self.groupIconAttributedString);
            attributedTitle.append(NSAttributedString.init(string: item.displayTitle));
            self.titleLabel.styledAttributedText = attributedTitle;
            
            if UserDefaults.standard.bool(forKey: "Shelf_ShowDate") {
                self.subTitleLabel.styleText = item.displayTitle;
            }
            else {
                self.subTitleLabel.styleText = "";
            }
            var currentOrder = FTUserDefaults.sortOrder()
            if let userActivity = self.window?.windowScene?.userActivity {
                currentOrder = userActivity.sortOrder
            }
            if let groupItem = groupShelfItem as? FTGroupItem,
               nil != groupItem.shelfCollection {
                groupItem.fetchTopNotebooks(sortOrder: currentOrder) { top3Children in
                    if !top3Children.isEmpty {
                        let firstGroupMember = top3Children[0]
                        self.updateDownloadStatusFor(item: firstGroupMember)
                        self.readThumbnailForSingle(item: firstGroupMember, imageView: self.coverImageView);
                    }
                    if top3Children.count > 1 {
                        if let imageView = self.coverImageView2 {
                            self.readThumbnailForSingle(item: top3Children[1], imageView: imageView);
                        }
                    }
                    if top3Children.count > 2 {
                        if let imageView = self.coverImageView3 {
                            self.readThumbnailForSingle(item: top3Children[2], imageView: imageView);
                        }
                    }
                    self.updateTextFiledFrame()
                }
                self.updateSubTitleInfo(item: groupShelfItem)

            }
        }
        else {
            self.coverImageCenterAdjustConstraint?.constant = 0
            self.accessibiltyElemet.accessibilityLabel = item.displayTitle;
            self.titleLabel.styleText = item.displayTitle;
            self.updateDownloadStatusFor(item: item);
            self.updateSubTitleInfo(item: item);
            self.readThumbnailForSingle(item: item, imageView: self.coverImageView);
        }
        self.updateBookLocationInfo(item: item)
        self.updateAccessories()
    }
    
    func readThumbnailForSingle(item : FTShelfItemProtocol,imageView : UIImageView) {
        weak var weakimageView = imageView
        var token : String?
        weak var weakSelf = self
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: { (image, imageToken) in
            if token == imageToken {
                weakimageView?.image = (nil == image ? UIImage(named: "covergray") : image)
                weakSelf?.updateTextFiledFrame()
            }
        })
    }
    
    fileprivate func updateTextFiledFrame()
    {
        self.titleLabelTopConstraint?.constant = 45
        self.titleLabel.textColor = UIColor.white
        if let coverImagView = self.coverImageView, let image = coverImagView.image {
            let style = image.coverLabelStyle();
            if style == .bottom || image.coverStyle() == .clearWhite{
                self.titleLabelTopConstraint?.constant = coverImagView.frame.height - 60 + 5
                if image.coverStyle() == .clearWhite {
                    self.titleLabel.textColor = UIColor.black
                }
            }
        }
    }
    //MARK:- Renaming
    @IBAction func renameClicked() {
        if let shelfItem = self.shelfItem {
            self.delegate?.shelfContentCollectionViewCell(shelfContentCollectionViewCell: self, didClickRenameWith: shelfItem);
        }
    }
        
    fileprivate var accessibiltyElemet : UIView
    {
        return self.coverImageView;
    }

    fileprivate func updateSubTitleInfo(item : FTShelfItemProtocol)
    {
        if UserDefaults.standard.bool(forKey: "Shelf_ShowDate") {
            self.subTitleLabel.styleText = item.fileModificationDate.shelfShortStyleFormat()
            if let groupItem = item as? FTGroupItemProtocol {
                self.subTitleLabel.styleText =  groupItem.itemsCountString
            }
        }
        else {
            self.subTitleLabel.styleText = "";
        }
    }
    fileprivate func updateBookLocationInfo(item : FTShelfItemProtocol)
    {
        self.bookLocationLabel?.attributedText = nil
        self.bookLocationLabel?.text = ""
        
        if let userActivity = self.window?.windowScene?.userActivity, userActivity.isAllNotesMode {
            if let collection = item.shelfCollection {
                var bookLocationString = collection.displayTitle
                if let groupItem = item.parent {
                    bookLocationString += (" / " + groupItem.displayTitle)
                }
                if !bookLocationString.isEmpty {
                    let attributedTitle = NSMutableAttributedString()
                    attributedTitle.append(self.folderIconAttributedString)
                    attributedTitle.append(NSAttributedString.init(string: bookLocationString))
                    self.bookLocationLabel?.attributedText = attributedTitle
                }
            }
        }
    }
}
extension FTGroupItemProtocol {
    var itemsCountString: String {
        var countString = String(format: NSLocalizedString("NItems", comment: "%d Items"), self.childrens.count)
        if self.childrens.count == 1 {
            countString = NSLocalizedString("OneItem", comment: "1 Item")
        }
        return countString
    }
}
extension FTShelfContentCollectionViewCell {
    //MARK:- isDownloaded
    
    func removeAllKeyPathObservers()
    {
        self.removeUrlObserversIfNeeded();
    }
    private func observeDownloadedStatusIfNeeded(forShelfItem shelfItem: FTShelfItemProtocol) {
        self.removeUrlObserversIfNeeded();
        self.shelfItem = shelfItem;
        self.addUrlObserversIfNeeded()
    }
    private func addUrlObserversIfNeeded(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didChangeMetadata(_:)),
                                               name: .didChangeURL,
                                               object: self.shelfItem);
    }
    
     func removeUrlObserversIfNeeded(){
        if let curShelfItem = self.shelfItem {
            NotificationCenter.default.removeObserver(self,
                                                      name: .didChangeURL,
                                                      object: curShelfItem);
        }
    }

    @objc func didChangeMetadata(_ notification : NSNotification)
    {
        if notification.name == .didChangeURL {
            if let documentItem = notification.object as? FTShelfItemProtocol{
                runInMainThread {
                    self.configureView(item: documentItem);
                }
            }
            return;
        }
    }
    
    @objc func removeLoader(_ notification : Notification) {
        
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                self.bookOpenSpinner?.stopRotating()
            }
        }
    }

}
