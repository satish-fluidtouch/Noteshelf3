//
//  FTSearchResultPageCell.swift
//  Noteshelf
//
//  Created by Simhachalam Naidu on 12/06/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTSearchResultPageCell: UICollectionViewCell {
    @IBOutlet weak var pageLabel: UILabel?
    @IBOutlet weak var imageViewPage: UIImageView?
    @IBOutlet private weak var shadowImgView: UIImageView?

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet weak var searchHighlightView: FTSelectionHighlightView?
    
    @IBOutlet weak var imageViewPageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var imageViewPageWidthConstraint: NSLayoutConstraint?
    
    fileprivate var observerAdded = false;
    
    var pdfSize: CGSize!
    var pageSize: CGSize!
    
    weak var page: FTThumbnailable? {
        willSet{
            self.removeSearchObserver();
        }
        didSet {
            self.addSearchObserver();
        }
    }

    func setThumbnailImage(usingPage page: FTThumbnailable) {
        self.removeObservers();
        self.page = page;
        self.updateThumbnailImage();
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
    
    private func updateThumbnailImage() {
        self.imageViewPage?.image = UIImage(named: "finder-empty-pdf-page")
        self.shadowImgView?.image = nil

        if let pageSize = self.pdfSize {
            self.imageViewPageWidthConstraint?.constant = pageSize.width
            self.imageViewPageHeightConstraint?.constant = pageSize.height
        }

        let blockToExecute: (UIImage?,String) -> Void = { [weak self] (image, uuidString) in
            if let currentPage = self?.page, currentPage.uuid == uuidString {
                self?.imageViewPage?.image = image;
                var isImageLoaded: Bool = false;
                if nil == image {
                    self?.imageViewPage?.image = UIImage(named: "finder-empty-pdf-page")
                }
                else {
                    self?.activityIndicatorView?.stopAnimating();
                    isImageLoaded = true;
                }
                self?.layoutIfNeeded()
                self?.updateShadow()
                if(currentPage.thumbnail()?.shouldGenerateThumbnail ?? false) {
                    self?.addObservers();
                }
                if(isImageLoaded) {
                    self?.didChangeSearchresults(nil);
                }
            }
        }
        self.page?.thumbnail()?.thumbnailImage(onUpdate: blockToExecute);
        
//        self.page?.thumbnail()?.cachedThumbnailInfo(onCompletion: blockToExecute);
    }

    private func updateShadow() {
        self.shadowImgView?.image = UIImage(named: "noCoverNBShadow")
        let capInsets = UIEdgeInsets(top: 5, left: 15, bottom: 25, right: 15)
        let scalled = self.shadowImgView?.image?.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
        self.shadowImgView?.image = scalled
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
    
    fileprivate func addSearchObserver()
    {
        if let pdfPage = self.page {
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
