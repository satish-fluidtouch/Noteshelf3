//
//  FTShelfTagsPageCell.swift
//  Noteshelf3
//
//  Created by Siva on 10/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon
import FTNewNotebook

class FTShelfTagsPageCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var tagsView: UIStackView!
    @IBOutlet weak var bookTitleLbl: UILabel?
    @IBOutlet weak var selectionBadge: UIImageView?
    @IBOutlet weak var shadowImageView: UIImageView!

    @IBOutlet weak var thumbnailHeightConstraint: NSLayoutConstraint!
    override var isSelected: Bool {
        didSet {
            if let selectionBadge = selectionBadge {
                selectionBadge.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circlebadge")
                selectionBadge.tintColor = isSelected ? .appColor(.accent) : .appColor(.black20)
            }
        }
    }

    func addObserverFor(page: FTPageProtocol) {
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didReceiveNotifcationForGenerateThumbnail(_:)),
                                                   name: NSNotification.Name(rawValue: "FTShouldGenerateThumbnail"),
                                                   object: page);
    }

    @objc func didReceiveNotifcationForGenerateThumbnail(_ notification : Notification)
    {
        if(!Thread.current.isMainThread) {
            runInMainThread { [weak self] in
                self?.didReceiveNotifcationForGenerateThumbnail(notification);
            }
            return;
        }
        guard let pageUUID = self.shelfTagItem?.pageUUID else {return}

        if let pageObject = notification.object as? FTPageProtocol
            ,pageObject.uuid == pageUUID {
            self.updateThumbnailImageFor(page: pageObject)
        }
    }

    private func updateThumbnailImageFor(page: FTPageProtocol) {
        self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page")

        let blockToExecute: (UIImage?,String) -> Void = { [weak self] (image, uuidString) in
            if page.uuid == uuidString {
                self?.thumbnail?.image = image;
                if nil == image {
                    self?.thumbnail?.image = UIImage(named: "finder-empty-pdf-page")
                }
                self?.layoutIfNeeded()
                if(page.thumbnail()?.shouldGenerateThumbnail ?? false) {
                    self?.addObserverFor(page: page)
                }
            }
        }
        page.thumbnail()?.thumbnailImage(onUpdate: blockToExecute);
    }

    private var shelfTagItem: FTShelfTagsItem?;
    func updateTagsPills(for shelfItem: FTShelfTagsItem) {
        self.shelfTagItem = shelfItem
        if let tagItems = self.shelfTagItem?.tags {
            let tags = Set.init(tagItems)
            let sortedArray = tags.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
            self.updateTagsViewWith(tags: sortedArray)
        }
    }

    func updateTagsItemCellContent(tagsItem: FTShelfTagsItem, isRegular: Bool) {
        self.shelfTagItem = tagsItem
        self.bookTitleLbl?.text = tagsItem.documentItem?.displayTitle
        let tags = Set.init(tagsItem.tags)
        let sortedArray = tags.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
        self.updateTagsViewWith(tags: sortedArray)
        self.thumbnail?.backgroundColor = .clear

        if tagsItem.type == .page {
            self.thumbnail?.layer.cornerRadius = 10

            let image = UIImage(named: "pages_shadow")
            let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
            shadowImageView.image = scalled
            self.shadowImageView.layer.cornerRadius = 10

        } else if tagsItem.type == .book, let shelfItem = tagsItem.documentItem {
            guard let docUUID = shelfItem.documentUUID else { return }

            FTCacheTagsProcessor.shared.cachedDocumentPlistFor(documentUUID: docUUID) { docPlist in
                let page = docPlist?.pages.first
                FTTagsProvider.shared.thumbnail(documentUUID: docUUID, pageUUID: page!.uuid) { [weak self] image, pageUUID in
                    guard let self = self else { return }
                    if let image, page!.uuid == pageUUID {
                        self.updateThumbnailImage(image, for: tagsItem)
                        self.updateShadow(for: tagsItem)
                    } else {
                        var token : String?
                        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem, onCompletion: { [weak self](image, imageToken) in
                            guard let self = self else { return }
                            if token == imageToken {
                                if let img = image {
                                    self.updateThumbnailImage(img, for: tagsItem)
                                    self.updateShadow(for: tagsItem)
                                } else {
                                    self.shadowImageView.layer.cornerRadius = 8
                                    self.thumbnail?.layer.cornerRadius = 8
                                    let shadowImage = UIImage(named: "noCover_shadow")
                                    let scalled = shadowImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
                                    self.shadowImageView.image = scalled
                                    if let img = UIImage(named: "no_cover", in: Bundle(for: FTCreateNotebookViewController.self), with: nil) {
                                        self.updateThumbnailImage(img, for: tagsItem)
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }

  private  func updateThumbnailImage(_ image: UIImage, for tagItem: FTShelfTagsItem) {
        if tagItem.type == .book {
            self.thumbnail?.image = image
            if image.size.width > image.size.height {// Landscape
                self.thumbnail?.layer.cornerRadius = 8
                let height = FTShelfTagsConstants.Book.landscapeSize.height
                self.thumbnailHeightConstraint.constant = height
            }
            else {
                self.thumbnail?.roundCorners(topLeft: 4.0, topRight: 10.0, bottomLeft: 4.0, bottomRight: 10.0)
                let height = FTShelfTagsConstants.Book.potraitSize.height
                self.thumbnailHeightConstraint.constant = height
            }
        }
    }
    
   private func updateShadow(for tagItem: FTShelfTagsItem) {
        if tagItem.type == .book {
            self.shadowImageView.layer.cornerRadius = 8
            let shadowImage = UIImage(named: "book_shadow")
            let scalled = shadowImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
            self.shadowImageView.image = scalled
        }
    }
    
    func updateTagsViewWith(tags: [FTTagModel]) {
        let padding = 10.0
        let interitemSpace = 5.0
        var xAxis = 0.0
        let totalWidth = self.bookTitleLbl?.frame.width ?? 100
        var availableSpace = totalWidth
        var tagsCount = tags.count
        let countStrWidth = 40.0
        tagsView?.subviews.forEach {$0.removeFromSuperview()}
        for (index, tag) in tags.enumerated() {
            let pageTag = "  #\(tag.text)  "
            let tagButton = UIButton(type: .custom)
            tagButton.layer.cornerRadius = 6
            tagButton.titleLabel?.lineBreakMode  = .byTruncatingMiddle
            tagButton.setTitle(pageTag, for: .normal)
            tagButton.titleLabel?.font = UIFont.appFont(for: .medium, with: 12)
            tagButton.backgroundColor = UIColor.appColor(.accentBg)
            tagButton.setTitleColor(UIColor.appColor(.accent), for: .normal)
            var fittingWidth = tagButton.intrinsicContentSize.width + padding
            if fittingWidth < (availableSpace + interitemSpace) - countStrWidth || index == 0 {
                 availableSpace = totalWidth - (xAxis + fittingWidth + interitemSpace)
                if availableSpace < countStrWidth {
                    fittingWidth = totalWidth - (xAxis + countStrWidth)
                    xAxis += fittingWidth + interitemSpace
                    availableSpace = fittingWidth - xAxis
                } else {
                    xAxis += fittingWidth + interitemSpace
                }
                tagsCount -= 1
                tagsView?.addArrangedSubview(tagButton)
            } else {
                tagButton.setTitle("\(tagsCount)+", for: .normal)
                tagsView?.addArrangedSubview(tagButton)
                return
            }
            tagsView?.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tagsView!.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ])
        }
    }
}
