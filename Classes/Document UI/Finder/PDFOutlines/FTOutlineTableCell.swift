//
//  FTOutlineTableCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 28/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTOutlineTableCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var pageNumberLabel: UILabel?
    @IBOutlet weak var expandButton: UIButton?
    
    @IBOutlet weak var indentationConstraint: NSLayoutConstraint?
    
    weak var page: FTThumbnailable?
    fileprivate var observerAdded = false;

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        self.thumbnailImageView?.layer.cornerRadius = 4
        // Initialization code
    }
    func setThumbnailImage(usingPage page: FTThumbnailable?) {
        self.removeObservers();
        self.page = page;
        self.updateThumbnailImage();
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
        self.thumbnailImageView?.contentMode = UIView.ContentMode.scaleAspectFit;
        self.page?.thumbnail()?.thumbnailImage(onUpdate: { [weak self] (image, uuidString) in
            if let currentPage = self?.page , currentPage.uuid == uuidString {
                self?.thumbnailImageView?.image = image;
                if nil == image {
                    self?.thumbnailImageView?.image = UIImage(named: "finder-empty-pdf-page");
                    self?.thumbnailImageView?.contentMode = UIView.ContentMode.scaleToFill;
                }
                if(currentPage.thumbnail()?.shouldGenerateThumbnail ?? false) {
                    self?.addObservers();
                }
            }
        });
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
    
    @objc func pageIsReleased(_ notification: Notification) {
        if let pageReleased = notification.object as? FTThumbnailable, let page = self.page,  pageReleased.uuid == page.uuid {
            self.removeObservers();
        }
    }

    //MARK:- NSObject
    deinit {
        self.removeObservers();
        #if DEBUG
        debugPrint("\(type(of: self)) is deallocated");
        #endif
    }
}
