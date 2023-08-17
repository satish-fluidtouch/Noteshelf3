//
//  FTShelfCategoryTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 04/05/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

let kShelfCollectionItemsCountNotification = "FTShelfCollectionItemsCountNotification"

enum FTShelfCategoryCellType : Int {
    case normal
    case trash
    case addNew
}

private extension String {
    var shelfDisplayTitle : NSAttributedString {
        var attrs : [NSAttributedString.Key : Any] =  [NSAttributedString.Key : Any]()
        attrs[.font] = UIFont.appFont(for: .regular, with: 16)
        attrs[.foregroundColor] = UIColor.headerColor
        attrs[.kern] = NSNumber(value: -0.32)
        return  NSAttributedString.init(string: self,
                                        attributes: attrs)
    }
}

protocol FTDropFocusProtocol : AnyObject
{
    func setFocusForDropAccept(_ shouldFocus : Bool);
}

class FTShelfCategoryTableViewCell: UITableViewCell,FTDropFocusProtocol {
    @IBOutlet weak var imageViewIcon: UIImageView?
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var separatorView: UIView?
    @IBOutlet weak var accessoryImage: UIImageView?
    @IBOutlet weak var titleLabel: FTCustomLabel!
    @IBOutlet weak var textFieldLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var textFieldTrailingConstraint: NSLayoutConstraint?
    @IBOutlet weak var accessoryViewWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var itemCountLabel: UILabel?
    @IBOutlet weak var selectionBackgroundView: UIView?
    @IBOutlet weak var itemCountLableWidthConstraint: NSLayoutConstraint?
    var cellType = FTShelfCategoryCellType.normal;
    
    override func awakeFromNib() {
        super.awakeFromNib();
        self.imageViewIcon?.alpha = 0.9;
        self.textField?.autocapitalizationType = UITextAutocapitalizationType.words;
        self.selectionBackgroundView?.layer.cornerRadius = 10.0
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCountIfRequired(_:)), name: NSNotification.Name(rawValue: kShelfCollectionItemsCountNotification), object: nil)
    }
        
    #if targetEnvironment(macCatalyst)
    override var canBecomeFocused: Bool {
        return false;
    }
    #endif

    override var isEditing: Bool {
        didSet {
            self.updateUI();
            if(self.isEditing) {
                self.textField?.isUserInteractionEnabled = true
                self.textField?.becomeFirstResponder();
            }
        }
    }
        
    var isCategorySelected: Bool = false {
        didSet {
            if cellType != .addNew {
                self.selectionBackgroundView?.isHidden = !self.isCategorySelected
                self.itemCountLabel?.isHidden = !self.isCategorySelected
                self.selectionBackgroundView?.backgroundColor = UIColor.appColor(.white90)
            }
        }
    }
    
    @objc func updateCountIfRequired(_ notification : Notification) {
        if let userInfo = notification.userInfo {
            if let count = userInfo["shelfItemsCount"] as? String, self.isCategorySelected {
                if count == "0" || !self.isCategorySelected || self.cellType == .addNew {
                    self.itemCountLabel?.isHidden = true
                } else {
                    self.itemCountLabel?.isHidden = false
                    runInMainThread {
                        self.itemCountLabel?.text = count
                        self.itemCountLableWidthConstraint?.constant = count.sizeWithFont(self.itemCountLabel?.font ?? UIFont.appFont(for: .regular, with: 16)).width + 5.0
                    }
                }
            }
        }

    }
    
    func setFocusForDropAccept(_ shouldFocus: Bool) {
        self.contentView.layer.borderWidth = shouldFocus ? 2 : 0;
        self.contentView.layer.borderColor = shouldFocus ? UIColor.appColor(.accent).cgColor : nil;
    }
    
    func configUI(_ collection : FTShelfItemCollection?) //pass nil for addnew
    {
        let iconName: String
        if let shelfItemCollection = collection {
            titleLabel.text = shelfItemCollection.displayTitle
            iconName = shelfItemCollection.iconFileName;

            if shelfItemCollection.collectionType == .system ||
                shelfItemCollection.collectionType == .recent ||
                shelfItemCollection.collectionType == .allNotes
                {
                self.cellType = .trash;
            }
            else {
                self.cellType = .normal;
            }
            if let image = UIImage(systemName: iconName) {
                self.imageViewIcon?.image = image
            } else {
                self.imageViewIcon?.image = UIImage(named: iconName)
            }
        }
        else {
            self.isSelected = false
            self.cellType = .addNew;
            iconName = "plus.circle"
            self.accessoryImage?.isHidden = true
            self.itemCountLabel?.isHidden = true
            self.selectionBackgroundView?.isHidden = true
            let textStr = NSLocalizedString("NewCategory", comment: "New Category");
            self.titleLabel.text = textStr
            self.imageViewIcon?.image = UIImage(systemName: iconName)
            self.imageViewIcon?.tintColor = UIColor.init(hexString: "#344455")
        }
        self.updateUI()
    }
    
    fileprivate func updateUI()
    {
        if(self.cellType == .addNew || self.cellType == .trash || !self.isEditing) {
            self.textField?.leftView = nil;
            self.textField?.layer.borderWidth = 0;
            self.textField?.isUserInteractionEnabled = false
            self.textField?.backgroundColor = UIColor.clear;
        }
        else if(self.isEditing) {
                self.textField?.layer.borderWidth = 1;
                self.textField?.layer.borderColor = UIColor.appColor(.black10).cgColor;
                self.textField?.isUserInteractionEnabled =  true;
            self.textField?.backgroundColor = self.isCategorySelected ? UIColor.appColor(.accent) : UIColor.appColor(.secondaryBG);
                self.textField?.tintColor = self.isCategorySelected ? UIColor.white : UIColor.appColor(.accent)
        }
    }
}

extension FTShelfCategoryTableViewCell : UISpringLoadedInteractionBehavior {
    func shouldAllow(_ interaction: UISpringLoadedInteraction,
                     with context: UISpringLoadedInteractionContext) -> Bool {
        return true
    }
}

class FTShelfCategoryRecentEntryTableViewCell : UITableViewCell, FTDropFocusProtocol, FTShelfItemCellProgressUpdate
{
    @IBOutlet weak var imageViewIcon: UIImageView?
    @IBOutlet weak var titleLabel: FTCustomLabel!
    @IBOutlet weak var infoLabel: FTCustomLabel!
    @IBOutlet weak var textField: UITextField?
    var shelfItem : FTShelfItemProtocol?
    @IBOutlet weak var selectionBackgroundView: UIView?
    @IBOutlet weak var bookOpenSpinner : FTBookOpeningSpinner?

    var progressObserver: NSKeyValueObservation?
    var downloadedStatusObserver: NSKeyValueObservation?
    var uploadingStatusObserver: NSKeyValueObservation?
    var downloadingStatusObserver: NSKeyValueObservation?
    var uploadedStatusObserver: NSKeyValueObservation?
 
    @IBOutlet weak var pieProgressView: FTRoundProgressView?
    @IBOutlet weak var statusImageView: UIImageView?
    var animType: FTAnimType = FTAnimType.none;
    
    var cloudImage : UIImage {
        return UIImage(named: "small_badge_cloud")!;
    }
    
    var uploadingImage : UIImage {
        return UIImage(named: "small_badge_upload")!;
    }
    
    #if targetEnvironment(macCatalyst)
    override var canBecomeFocused: Bool {
        return false;
    }
    #endif
    
    private func observeDownloadedStatusIfNeeded(forShelfItem shelfItem: FTShelfItemProtocol) {
        self.stopObservingProgressUpdates()
        self.shelfItem = shelfItem;
        self.startObservingProgressUpdates()
    }
    func didFinishUpdating() {
        if let item = self.shelfItem {
            self.configUI(item)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib();
        self.imageViewIcon?.alpha = 0.9;
        #if !targetEnvironment(macCatalyst)
        self.textField?.font = UIFont.appFont(for: .regular, with: 16)
        #endif
        self.bookOpenSpinner?.isHidden = true
        self.selectionBackgroundView?.layer.cornerRadius = 10.0
        self.selectionBackgroundView?.backgroundColor = UIColor.appColor(.white90)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeLoader(_:)), name: Notification.Name.shelfItemRemoveLoader, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.shelfItemRemoveLoader, object: nil)
    }
    
    override var isSelected: Bool {
        didSet {
            self.selectionBackgroundView?.isHidden = !self.isSelected;
        }
    }
    func configUI(_ item : FTShelfItemProtocol) //pass nil for addnew
    {
        self.textField?.attributedText = item.displayTitle.shelfDisplayTitle;
        titleLabel.text = item.displayTitle
        infoLabel.text = item.fileModificationDate.shelfShortStyleFormat()
        let defaultCoverImage = UIImage(named: "covergray");
        let shouldLoadImage = (shelfItem?.uuid != item.uuid)
        self.updateDownloadStatusFor(item: item);
        self.observeDownloadedStatusIfNeeded(forShelfItem: item)

        if(shouldLoadImage) {
            self.imageViewIcon?.image = defaultCoverImage;
            var taskID : String?;
            taskID = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item,
                                                                              onCompletion:
                {  (img, inTaskID) in
                    if let imageToSet = img, (inTaskID == taskID) {
                        self.imageViewIcon?.image = imageToSet;
                    }
            });
        }
    }
    
    func setFocusForDropAccept(_ shouldFocus: Bool) {
        self.contentView.layer.borderWidth = shouldFocus ? 2 : 0;
        self.contentView.layer.borderColor = shouldFocus ? UIColor.appColor(.accent).cgColor : nil;
    }
    
    @objc func removeLoader(_ notification : Notification) {
        
        if let item = notification.object as? FTShelfItemProtocol {
            if item.uuid == self.shelfItem?.uuid {
                self.bookOpenSpinner?.stopRotating()
            } else {
                self.bookOpenSpinner?.isHidden = true
            }
           // self.isSelected = false
        }
    }
}

fileprivate extension FTShelfItemCollection {
    var iconFileName : String {
        let iconFileName : String;
        if(self.isTrash) {
            iconFileName = trashIcon;
        }
        else if self.collectionType == .default {
            if self.isUnfiledNotesShelfItemCollection {
                iconFileName = self.systemUnfiledIcon;
            }
            else {
                iconFileName = self.defaultShelfIcon;
            }
        } else if self.collectionType == .migrated {
            iconFileName = self.migratedShelfIcon
        }
        else if self.isAllNotesShelfItemCollection {
            iconFileName = self.systemAllIcon;
        } else if self.collectionType == .starred {
            iconFileName = self.favoriteIcon
        }
        else {
            iconFileName = self.systemShelfIcon;
        }
        return iconFileName;
    }
    
    var trashIcon : String {
        let iconFileName : String;
        #if targetEnvironment(macCatalyst)
        iconFileName = "category_trash";
        #else
        iconFileName = "category_trash"
        #endif
        return iconFileName;
    }
    var systemAllIcon : String {
        return "doc.on.doc";
    }
    var systemUnfiledIcon : String {
        return "tray";
    }
    
    var favoriteIcon : String {
        return "star";
    }
    
    

    var systemShelfIcon : String {
        let iconFileName : String;
        #if targetEnvironment(macCatalyst)
        iconFileName = "folder";
        #else
        iconFileName =  "folder"
        #endif
        return iconFileName;
    }
    
    var defaultShelfIcon : String {
        let iconFileName : String;
        #if targetEnvironment(macCatalyst)
        iconFileName = "folder";
        #else
        iconFileName = "folder"
        #endif
        return iconFileName;
    }
    
    var migratedShelfIcon : String {
        let iconFileName : String;
        #if targetEnvironment(macCatalyst)
        iconFileName = "folder";
        #else
        iconFileName = "folder"
        #endif
        return iconFileName;
    }

}


class PaddingTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
