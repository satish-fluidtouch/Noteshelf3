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
    @IBOutlet weak var notDownloadStatusView: UIImageView?
    @IBOutlet weak var tagsView: UIStackView!
    @IBOutlet weak var bookTitleLbl: UILabel?
    @IBOutlet weak var selectionBadge: UIImageView?
    @IBOutlet weak var shadowImageView: UIImageView!

    private(set) weak var taggedEntity: FTTaggedEntity?;
    
    private var obsertver: NSKeyValueObservation?
    
    @IBOutlet weak var thumbnailHeightConstraint: NSLayoutConstraint!
    var isItemSelected: Bool = false {
        didSet {
            if let selectionBadge = selectionBadge {
                selectionBadge.image = isItemSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circlebadge")
                selectionBadge.tintColor = isItemSelected ? .appColor(.accent) : .appColor(.black20)
            }
        }
    }
    
    private func updateTagsViewWith(tags: [String]) {
        let padding = 10.0
        let interitemSpace = 5.0
        var xAxis = 0.0
        let totalWidth = self.bookTitleLbl?.frame.width ?? 100
        var availableSpace = totalWidth
        var tagsCount = tags.count
        let countStrWidth = 40.0
        tagsView?.subviews.forEach {$0.removeFromSuperview()}
        for (index, tag) in tags.enumerated() {
            let pageTag = "  #\(tag)  "
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
                tagButton.setTitle("+ \(tagsCount)", for: .normal)
                tagsView?.addArrangedSubview(tagButton)
                return
            }
            tagsView?.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tagsView!.centerXAnchor.constraint(equalTo: self.centerXAnchor)
                ,tagsView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor)
            ])
        }
    }
}

private extension FTShelfTagsPageCell {
    func removeObserver() {
        if let obsertver = self.obsertver {
            obsertver.invalidate();
            self.obsertver = nil;
        }
    }
    
    func downloadStatusDidChange() {
        if !Thread.current.isMainThread {
            runInMainThread { [weak self] in
                self?.downloadStatusDidChange()
            }
            return;
        }
        self.notDownloadStatusView?.isHidden = (self.taggedEntity?.downloadStatus == .downloaded)
    }
    
    func addObserver() {
        self.removeObserver();
        self.obsertver = self.taggedEntity?.observe(\.downloadStatus, options: [.new,.old], changeHandler: { (taggedEntity, _) in
            self.downloadStatusDidChange();
        })
    }
}

extension FTShelfTagsPageCell {
    func updateTaggedEntity(taggedEntity: FTTaggedEntity, isRegular: Bool) {
        if self.taggedEntity?.hash != taggedEntity.hash {
            self.removeObserver();

            self.taggedEntity = taggedEntity;

            if taggedEntity.downloadStatus != .downloaded {
                self.addObserver();
            }
        }
        self.downloadStatusDidChange();
        self.bookTitleLbl?.text = taggedEntity.documentName
        let sortedArray = Array(taggedEntity.tags).sortedTags();
        self.updateTagsViewWith(tags: sortedArray.compactMap{$0.tagName})
        self.thumbnail?.backgroundColor = .clear

        if taggedEntity.tagType == .page {
            self.thumbnail?.layer.cornerRadius = 10
            let image = UIImage(named: "pages_shadow")
            let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
            shadowImageView.image = scalled
            self.shadowImageView.layer.cornerRadius = 10
            
            self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");
            var token: String?;
            token = taggedEntity.thumbnail { [weak self] (image, intoken) in
                if let image, token == intoken {
                    self?.thumbnail?.image = image
                }
            }
        } else if taggedEntity.tagType == .book {
            var token : String?
            self.thumbnail?.contentMode = .scaleAspectFit
            token = taggedEntity.thumbnail { [weak self] (image, intoken) in
//                if intoken == token {
                    if let img = image {
                        var height = FTShelfTagsConstants.Book.potraitSize.height
                        if img.size.width > img.size.height {// Landscape
                            height = FTShelfTagsConstants.Book.landscapeSize.height
                        }
                        self?.thumbnailHeightConstraint.constant = height
                        self?.shadowImageView.layer.cornerRadius = 8
                        self?.thumbnail?.layer.cornerRadius = 8
                        
                        let shadowImage = UIImage(named: "book_shadow")
                        let scalled = shadowImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
                        self?.shadowImageView.image = scalled
                        self?.thumbnail?.image = img
                    } else {
                        self?.shadowImageView.layer.cornerRadius = 8
                        self?.thumbnail?.layer.cornerRadius = 8
                        let shadowImage = UIImage(named: "noCover_shadow")
                        let scalled = shadowImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
                        self?.shadowImageView.image = scalled
                        
                        self?.thumbnail?.image = UIImage(named: "no_cover", in: Bundle(for: FTCreateNotebookViewController.self), with: nil);
                    }
//                }
            }
        }
    }

}
