//
//  FTShelfItemPreviewViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 22/07/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


private let thumbnailSize: CGSize = CGSize(width: 230, height: 380)
private let thumbnailSizeForPasswordBooks: CGSize = CGSize(width: 180, height: 230)
private let defaultPreferredContentSize: CGSize = CGSize(width: 180, height: 320)
private let defaultSpacing: CGFloat = 24.0
private let charactersLimit = 14
private let resizeWidthRatio: CGFloat = 1.7
private let minContentSize: CGFloat = 200.0

class FTShelfItemPreviewViewController: UIViewController {
    @IBOutlet weak private var lblBookTitle: UILabel?
    @IBOutlet weak private var lblCollectionTitle: UILabel?
    @IBOutlet weak private var lblCreatedDate: UILabel?
    @IBOutlet weak private var lblUpdatedDate: UILabel?
    @IBOutlet weak private var lblBookSizeAndpageCount: UILabel?
    @IBOutlet weak private var imgLastEditedPage: UIImageView?
    @IBOutlet weak private var searchHighLightView: FTSelectionHighlightView?
    
    var searchPageThumbNail : FTThumbnailable? //Used for global search
    
    var shelfItem: FTShelfItemProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePreviewDetails()
    }
    
    deinit {
        debugPrint(self.classForCoder)
    }
    
    private func updateOpacityOflabels() {
        lblCollectionTitle?.textColor = UIColor.headerColor.withAlphaComponent(0.6)
        lblCreatedDate?.textColor = UIColor.headerColor.withAlphaComponent(0.4)
        lblUpdatedDate?.textColor = UIColor.headerColor.withAlphaComponent(0.4)
        lblBookSizeAndpageCount?.textColor = UIColor.headerColor.withAlphaComponent(0.4)
    }
    
    private func updatePreviewDetails() {
        
        updateOpacityOflabels()
        
        if let item = shelfItem {
            
            lblBookTitle?.text = item.displayTitle
            
            var collectionTitle = ""
            if let groupItem = shelfItem?.parent {
                var title = groupItem.displayTitle
                if title.count >= charactersLimit {
                    title = String(title.prefix(charactersLimit))
                    title = title.appending("...")
                }
                collectionTitle = "\(title) / "
            }
            
            lblCollectionTitle?.text = collectionTitle  + item.shelfCollection.displayTitle
            
            let createdDate = item.fileCreationDate.shelfShortStyleFormat()
            lblCreatedDate?.text = NSLocalizedString("Created", comment: "Created Date") + " " + createdDate
            
            let modifiedDate = item.fileModificationDate.shelfShortStyleFormat()
            lblUpdatedDate?.text = NSLocalizedString("Updated", comment: "Updated Date") + " " + modifiedDate
            
            self.preferredContentSize = defaultPreferredContentSize
            
            //Pages count
            if let item = shelfItem as? FTDocumentItemProtocol {
                if !item.isDownloaded {
                    self.lblBookSizeAndpageCount?.text = ""
                    return
                }
            }
            
            if searchPageThumbNail == nil {
                if item.isPinEnabledForDocument() {
                    var token : String?;
                    token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: { [weak self] (image, imageToken) in
                        if let weakSelf = self {
                            if token == imageToken {
                                DispatchQueue.main.async {
                                    if let thumnNailImage = image {
                                        let resizeImage = thumnNailImage.resizedImage(thumbnailSizeForPasswordBooks)
                                        weakSelf.imgLastEditedPage?.image = resizeImage
                                        if let lblPageFrame = weakSelf.lblBookSizeAndpageCount {
                                            weakSelf.preferredContentSize = CGSize(width: resizeImage.size.width + defaultSpacing, height: lblPageFrame.frame.origin.y + defaultSpacing + resizeImage.size.height)
                                        }
                                    }
                                }
                            }
                        }
                    });
                    return
                }
                FTCLSLog("Doc Open - Shelf Preview : \(item.URL.title)")
                let request = FTDocumentOpenRequest(url: item.URL, purpose: .read);
                FTNoteshelfDocumentManager.shared.openDocument(request: request) { [weak self] (token, document, _) in
                    if let doc = document {
                        let pages = doc.pages()
                        self?.lblBookSizeAndpageCount?.text = "\(pages.count) \(NSLocalizedString("Pages", comment: "pages"))"
                        if let thumbNailImage = FTPDFExportView.snapshot(forPage: pages[0], size:thumbnailSize, screenScale: UIScreen.main.scale, shouldRenderBackground: true,offscreenRenderer: nil, with: FTSnapshotPurposeEvernoteSync) {
                            if let lblPageFrame = self?.lblBookSizeAndpageCount {
                                self?.preferredContentSize = CGSize(width: thumbNailImage.size.width + defaultSpacing, height: lblPageFrame.frame.origin.y + defaultSpacing + thumbNailImage.size.height + defaultSpacing)
                            }
                            self?.imgLastEditedPage?.image = thumbNailImage
                        }
                        FTNoteshelfDocumentManager.shared.closeDocument(document: doc, token: token, onCompletion: nil);
                    }
                }
            } else {
                searchPageThumbNail?.thumbnail()?.thumbnailImage(onUpdate: { [weak self] (image, _) in
                    if let weakSelf = self {
                        if let img = image {
                            let ratio = img.size.width/img.size.height
                            var finalSize: CGSize = CGSize(width: img.size.width, height: img.size.height)
                            if finalSize.width > minContentSize {
                                let maxWidth = img.size.width/resizeWidthRatio
                                let resizeImage = img.resizedImage(CGSize(width: maxWidth, height: maxWidth/ratio))
                                weakSelf.imgLastEditedPage?.image = resizeImage
                                finalSize = CGSize(width: resizeImage.size.width, height: resizeImage.size.height)
                            } else {
                                weakSelf.imgLastEditedPage?.image = img
                            }
                            if let lblPageFrame = weakSelf.lblBookSizeAndpageCount {
                                weakSelf.preferredContentSize = CGSize(width: finalSize.width + defaultSpacing, height: lblPageFrame.frame.origin.y + defaultSpacing + finalSize.height)
                                weakSelf.updateSearchResultsHighLight()
                            }
                        }
                    }
                })
            }
        }
    }
    
    private func updateSearchResultsHighLight() {
        if let searchPage = self.searchPageThumbNail as? FTPageSearchProtocol, let localPDFSize = self.imgLastEditedPage?.image?.size {
            let annotationScale = localPDFSize.width/self.searchPageThumbNail!.pdfPageRect.size.width;
            let scale = (searchPageThumbNail as! FTPageProtocol).pdfscale!(inRect: CGRect.init(origin: CGPoint.zero, size: localPDFSize));
            self.searchHighLightView?.renderSearchItems(items: searchPage.searchingInfo?.searchItems,
                                                        pdfScale: scale,
                                                        annotationScale: annotationScale);
        }
    }
}
