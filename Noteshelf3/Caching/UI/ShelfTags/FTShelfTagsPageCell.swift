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

class FTShelfTagsPageCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView?
    @IBOutlet weak var tagsView: UIStackView!
    @IBOutlet weak var bookTitleLbl: UILabel?
    @IBOutlet weak var selectionBadge: UIImageView?
    @IBOutlet weak var shadowImageView: UIImageView!

    override var isSelected: Bool {
        didSet {
            if let selectionBadge = selectionBadge {
                selectionBadge.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circlebadge")
                selectionBadge.tintColor = isSelected ? .appColor(.accent) : .appColor(.black20)
            }
        }
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

        self.bookTitleLbl?.text = tagsItem.shelfItem?.displayTitle
        let tags = Set.init(tagsItem.tags)
        let sortedArray = tags.sorted(by: { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending })
        self.updateTagsViewWith(tags: sortedArray)
        self.thumbnail?.backgroundColor = .clear
//        self.thumbnail?.image = nil

        if tagsItem.type == .page, let docUUID = tagsItem.documentUUID, let pageUUID = tagsItem.pageUUID {
            self.thumbnail?.layer.cornerRadius = 10

            let image = UIImage(named: "pages_shadow")
            let scalled = image?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 20, bottom: 32, right: 20), resizingMode: .stretch)
            shadowImageView.image = scalled
            self.shadowImageView.layer.cornerRadius = 10

            self.thumbnail?.image = UIImage(named: "finder-empty-pdf-page");
            FTTagsProvider.shared.thumbnail(documentUUID: docUUID, pageUUID: pageUUID) { [weak self] image, pageUUID in
                guard let self = self else { return }
                if let image {
                    self.thumbnail?.image = image
                }
            }
        } else if tagsItem.type == .book, let shelfItem = tagsItem.shelfItem {
            var token : String?
            self.thumbnail?.contentMode = .scaleAspectFit

            token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(shelfItem, onCompletion: { [weak self](image, imageToken) in
                if token == imageToken {
                    if let img = image {
                        self?.thumbnail?.contentMode = .scaleAspectFill
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

                        self?.thumbnail?.image = UIImage(named: "no_cover")
                    }
                }
            })
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
