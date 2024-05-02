//
//  FTShelfItemTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 26/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

typealias SubTitleCompletionHandler = ((NSAttributedString) -> Void);

class FTShelfItemTableViewCell: UITableViewCell,FTShelfItemCellProgressUpdate {
    private let buttonWidth: CGFloat = 32.0
    var progressObserver: NSKeyValueObservation?
    var downloadedStatusObserver: NSKeyValueObservation?
    var uploadingStatusObserver: NSKeyValueObservation?
    var downloadingStatusObserver: NSKeyValueObservation?
    var uploadedStatusObserver: NSKeyValueObservation?

    @IBOutlet weak var pieProgressView: FTRoundProgressView?
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var selectionBackgroundView: UIView?
    @IBOutlet weak var leftStackLeadingConstraint: NSLayoutConstraint?

    @IBOutlet weak var accessoryButton: UIButton?
    @IBOutlet weak var accessoryWidthConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageIconLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var checkMarkButton: UIButton?
    
    var animType: FTAnimType = FTAnimType.none;
    
    var cloudImage : UIImage {
        return UIImage(named: "small_badge_cloud")!;
    }
    
    var uploadingImage : UIImage {
        return UIImage(named: "small_badge_upload")!;
    }
    
    @IBOutlet weak var imageViewIcon: UIImageView!
    @IBOutlet weak var imageViewIcon2: UIImageView!
    @IBOutlet weak var imageViewIcon3: UIImageView!
    @IBOutlet weak var labelTitle: FTCustomLabel!
    @IBOutlet weak var labelSubTitle: FTCustomLabel!
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var passcodeLockStatusView: UIView!
    @IBOutlet weak var currentShelfItemIndicator: UIImageView?
    
    @IBOutlet weak var shadowImageView: FTShelfItemShadowImageView!
    @IBOutlet weak var shadowImageView2: FTShelfItemShadowImageView!
    @IBOutlet weak var shadowImageView3: FTShelfItemShadowImageView!
    
    var mode = FTShelfItemsViewMode.picker {
        didSet {
            if mode != .picker && mode != .movePage {
                self.leftStackLeadingConstraint?.constant = 16.0
                self.checkMarkButton?.isHidden = false
            } else {
                self.leftStackLeadingConstraint?.constant = 8.0
                self.checkMarkButton?.isHidden = true
            }
            self.updateConstraintsIfNeeded()
        }
    }
    
    var dataMode = FTShelfItemDataMode.collection(.normal) {
        didSet {
            if dataMode == FTShelfItemDataMode.collection(.normal) {
                self.leftStackLeadingConstraint?.constant = 8.0
                self.checkMarkButton?.isHidden = true
                self.updateConstraintsIfNeeded()
            }
        }
    }
    
    var shelfItem: FTShelfItemProtocol?
    var transientShelfItem: FTCloudBackupStatusInfo? {
        didSet {
            self.addObservers();
        }
    }
    var backUpStatus: FTBackupStatusType?;
    var documentItem: FTDocumentItem!;

    weak var tableView: UITableView!
    var indexPath: IndexPath!
    
    //This is for Recent And Favorite Items management
    var didTapOnMoreOption : ((_ button:UIButton)->Void)?
    
    var cellAccessoryType: UITableViewCell.AccessoryType = .none {
        didSet{
            switch self.cellAccessoryType {
                case .none:
                    self.accessoryWidthConstraint?.constant = 0
                case .disclosureIndicator:
                    self.accessoryWidthConstraint?.constant = buttonWidth
                case .checkmark:
                    self.accessoryWidthConstraint?.constant = buttonWidth
                    self.accessoryButton?.setImage(UIImage(named: "iconCheck"), for: UIControl.State.normal)
                case .detailButton:
                    self.accessoryButton?.isUserInteractionEnabled = true
                    self.accessoryWidthConstraint?.constant = buttonWidth
                    self.accessoryButton?.setImage(UIImage(named: "infomore"), for: UIControl.State.normal)
                    self.accessoryButton?.addTarget(self, action: #selector(moreButtonTapped(_:)), for: .touchUpInside)

                default:
                    break
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryButton?.isUserInteractionEnabled = false
        self.currentShelfItemIndicator?.isHidden = true
        self.selectionBackgroundView?.isHidden = true
    }
    
    func setSelectedBgView(value: Bool){
        if value {
            self.selectionBackgroundView?.backgroundColor = .clear
        }else {
             self.selectionBackgroundView?.layer.cornerRadius = 10
             self.selectionBackgroundView?.backgroundColor = UIColor.appColor(.white90)
        }
    }
    
    func setEnable(_ status: Bool) {
        self.isUserInteractionEnabled = status
        self.enableSubviews(status,forView: self);
    }
    
    fileprivate func enableSubviews(_ status: Bool,forView view:UIView) {
        for eachView in view.subviews {
            if let control = eachView as? UIControl {
                control.isEnabled = status
            }
            else if let label = eachView as? FTStyledLabel {
                label.isEnabled = status
            }
            else {
                self.enableSubviews(status,forView: eachView);
            }
        }
    }
    
    //MARK:- isDownloaded
    private func observeDownloadedStatusIfNeeded(forShelfItem shelfItem: FTShelfItemProtocol) {
        self.stopObservingProgressUpdates()
        self.shelfItem = shelfItem;
        self.startObservingProgressUpdates()
    }
    func didFinishUpdating() {
        if let item = self.shelfItem {
            self.configureView(item: item)
            self.reloadData();
        }
    }
    //MARK:- FTShelfItemsUI methods
    func updateUI(forShelfItem shelfItem: FTShelfItemProtocol) {
        switch self.mode {
        case .dropboxBackUp:
            fallthrough;
        case .onedriveBackUp:
            self.updateDropboxUI();
        case .evernoteSync:
            self.updateEvernoteSyncUI();
        default:
            self.labelSubTitle.text = shelfItem.fileModificationDate.shelfShortStyleFormat();
            if mode == .recent {
                self.cellAccessoryType = .detailButton
            }
        }
    }
    
    @objc private func moreButtonTapped(_ sender:UIButton) {
        didTapOnMoreOption?(sender)
    }
    
    private func updateDropboxUI() {
        
        self.labelSubTitle.text = "";
        
        self.progressView?.isHidden = true;
        self.labelSubTitle.textColor = .gray;
       
        self.cellAccessoryType = .none;

        let documentItem = self.shelfItem as? FTDocumentItemProtocol;
        if(nil != documentItem && documentItem!.isDownloaded) {

            self.progressView?.isHidden = true;
            self.labelSubTitle.textColor = .gray;
            if let documentID = documentItem!.documentUUID, let transientShelfItem = FTCloudBackUpManager.shared.transientBackupItem(forDocumentUUID: documentID) {
                
                if nil != self.transientShelfItem && self.transientShelfItem!.uuid == transientShelfItem.uuid {
                }
                else {
                    self.removeObservers(); //Remove previous observers
                    self.transientShelfItem = transientShelfItem;
                }
                
                self.progressView?.isHidden = !(transientShelfItem.backUpStatus.rawValue == FTBackupStatusType.inProgress.rawValue);
                
                self.cellAccessoryType = .none

                let statusType = transientShelfItem.backUpStatus;
                let progress = transientShelfItem.progress;

                switch statusType {
                case .none:
                    break;
                case .pending:
                    self.labelSubTitle.textColor = .red;
                    break;
                case .inProgress:
                    self.progressView?.isHidden = false;
                    self.progressView?.progress = Float(progress);
                case .error:
                    self.labelSubTitle.textColor = .red;
                    break;
                case .complete:
                    self.labelSubTitle.textColor = UIColor.appColor(.accent)
                    break;
                }

            }
            else {
                self.removeObservers(); //Remove previous observers
            }
            self.subTitle(withCompletionHandler: { [weak self] (subTitle) in
                self?.labelSubTitle.text = subTitle.string;
            });
        }
        else {
            self.removeObservers(); //Remove previous observers
        }
    }
    
    private func updateEvernoteSyncUI() {
        let documentItemProtocol = self.shelfItem as! FTDocumentItemProtocol
        self.progressView?.isHidden = true
        self.cellAccessoryType = .none
        var imageName = "checkBadgeOff"
        if let documentUUID = documentItemProtocol.documentUUID, FTENPublishManager.shared.isSyncEnabled(forDocumentUUID: documentUUID) {
            imageName = "iconCheckBadge"
        }
        self.labelSubTitle.text = ""
        self.checkMarkButton?.setImage(UIImage(named: imageName), for: .normal)
    }
    
    fileprivate func subTitle(withCompletionHandler completionHandler: SubTitleCompletionHandler) {
        let backUpStatus: String
        if let transientShelfItem = FTCloudBackUpManager.shared.transientBackupItem(forDocumentUUID: (self.shelfItem as! FTDocumentItemProtocol).documentUUID) {
            if transientShelfItem.backUpStatus == .inProgress {
                completionHandler(NSAttributedString(string: transientShelfItem.backUpStatusString()))
                return
            }
            else {
                backUpStatus = transientShelfItem.backUpStatusString()
            }
        }
        else {
            backUpStatus = NSLocalizedString("BackupNotSelected", comment: "Not selected for backup")
        }
        completionHandler(self.formattedSubTitle(withSize: "", andBackUpStatusMessage: backUpStatus))
    }
    
    fileprivate func formattedSubTitle(withSize size: String,  andBackUpStatusMessage message: String) -> NSAttributedString {
        let firstLineSubTitle: String = ""
        let attributedSubTitle = NSMutableAttributedString(string: firstLineSubTitle)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1
        attributedSubTitle.setAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSRange.init(location: 0, length: attributedSubTitle.length))
        
        let documentUUID = (self.shelfItem as! FTDocumentItemProtocol).documentUUID
        var imageName = "checkBadgeOff"
        
         if let transientShelfItem = FTCloudBackUpManager.shared.transientBackupItem(forDocumentUUID: documentUUID), (transientShelfItem.backUpStatus.rawValue == FTBackupStatusType.complete.rawValue || transientShelfItem.backUpStatus.rawValue == FTBackupStatusType.pending.rawValue) {
            if transientShelfItem.backUpStatus.rawValue == FTBackupStatusType.complete.rawValue {
                if let ignoreList = FTCloudBackUpManager.shared.activeCloudBackUpManager?.ignoreList, ignoreList.isBackupIgnored(forShelfItemWithUUID: documentUUID!) {
                    imageName = "BackupStatus/Error"
                }
                else if transientShelfItem.lastBackedUpDate >= transientShelfItem.documentLastUpdatedDate {
                    imageName = "iconCheckBadge"
                }
                else {
                    imageName = "BackupStatus/Warning"
                }
            }
            else {
                imageName = "BackupStatus/Warning"
            }
        }
        
        let image = UIImage(named: imageName)
        if !(self.shelfItem is FTGroupItemProtocol) {
            self.checkMarkButton?.setImage(image, for: .normal)
        }
        attributedSubTitle.append(NSAttributedString(string: message))
        return attributedSubTitle
    }
    
    //MARK:- KVO
    func addObservers() {
        if let transientShelfItem = self.transientShelfItem {
            transientShelfItem.addObserver(self, forKeyPath: "backUpStatus", options: .new, context: nil);
            transientShelfItem.addObserver(self, forKeyPath: "progress", options: .new, context: nil);
        }
    }
    
    func removeObservers() {
        if let transientShelfItem = self.transientShelfItem {
            transientShelfItem.removeObserver(self, forKeyPath: "backUpStatus");
            transientShelfItem.removeObserver(self, forKeyPath: "progress");
            self.transientShelfItem = nil;
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let transientShelfItem = self.transientShelfItem {
            
            if transientShelfItem.backUpStatus == .inProgress {
                self.progressView?.progress = Float(transientShelfItem.progress);
            }
            if self.backUpStatus != transientShelfItem.backUpStatus {
                self.reloadData();
            }
            self.backUpStatus = transientShelfItem.backUpStatus;
        }
    }
    
    func isCurrentSelected(_ value: Bool) {
        selectionBackgroundView?.isHidden = !value
        labelTitle.textColor = UIColor.appColor(.black1)
        labelSubTitle.textColor =  UIColor.appColor(.black50)
        accessoryButton?.tintColor = UIColor.appColor(.black50)
    }
    
    func configureView(item : FTShelfItemProtocol)
    {
        self.observeDownloadedStatusIfNeeded(forShelfItem: item);

        self.shadowImageView2.isHidden = true;
        self.shadowImageView3.isHidden = true;
        self.imageViewIcon2.isHidden = true;
        self.imageViewIcon3.isHidden = true;
        
        let defaultCoverImage = UIImage(named: "covergray");
        self.imageViewIcon.image = defaultCoverImage;
        self.imageViewIcon2.image = defaultCoverImage;
        self.imageViewIcon3.image = defaultCoverImage;
        
        if let groupShelfItem = item as? FTGroupItemProtocol {
            self.shadowImageView2.isHidden = false;
            self.shadowImageView3.isHidden = false;
            self.imageViewIcon2.isHidden = false;
            self.imageViewIcon3.isHidden = false;
            
            var currentOrder = FTUserDefaults.sortOrder()
            if let userActivity = self.window?.windowScene?.userActivity{
                currentOrder = userActivity.sortOrder
            }
            if let groupItem = groupShelfItem as? FTGroupItem, nil != groupItem.shelfCollection {
                groupItem.fetchTopNotebooks(sortOrder: currentOrder) { top3Children in
                    if !top3Children.isEmpty {
                        let firstGroupMember = top3Children[0]
                        self.updateDownloadStatusFor(item: firstGroupMember)
                        self.readThumbnailFor(item: firstGroupMember, imageView: self.imageViewIcon);
                    }
                    if top3Children.count > 1 {
                        if let imageView = self.imageViewIcon2 {
                            self.readThumbnailFor(item: top3Children[1], imageView: imageView);
                        }
                    }
                    if top3Children.count > 2 {
                        if let imageView = self.imageViewIcon3 {
                            self.readThumbnailFor(item: top3Children[2], imageView: imageView);
                        }
                    }
                }
            }
        }
        else {
            self.updateDownloadStatusFor(item: item);
            self.readThumbnailFor(item: item, imageView: self.imageViewIcon);
        }
        if let item = self.shelfItem {
            self.passcodeLockStatusView.isHidden = !(item.isPinEnabledForDocument())
        }
    }
    
    fileprivate func readThumbnailFor(item : FTShelfItemProtocol,imageView : UIImageView) {
        weak var weakimageView = imageView;
        var token : String?;
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: { (image, imageToken) in
            if(image != nil && token == imageToken) {
                weakimageView?.image = image;
            }
        });
    }
    
    private func reloadData() {
        runInMainThread {
            UIView.performWithoutAnimation({ [weak self] in
                if let tableView = self?.tableView, let indexPath = self?.indexPath {
                    tableView.reloadRows(at: [indexPath], with: .none);
                }
            });
        }
    }
    
    //MARK:- NSObject
    deinit {
        self.removeObservers();
        self.stopObservingProgressUpdates()
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated")
        #endif
        self.stopAnimation();
    }
}

