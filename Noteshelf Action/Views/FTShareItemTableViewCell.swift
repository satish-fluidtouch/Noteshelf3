//
//  FTShareItemTableViewCell.swift
//  Noteshelf Action
//
//  Created by Sameer on 15/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
enum FTShareItemType {
    case category
    case group
    case noteBook
    case none
}

class FTShareItemTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var subTitleLabel: UILabel?

    @IBOutlet var iconView: UIImageView?
    @IBOutlet var thumbnailImageView: UIImageView!
    var type: FTShareItemType = .category
    @IBOutlet weak var accessoryImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(item: FTShareItem?, indexPath: IndexPath) {
        if let item = item {
            titleLabel?.text = item.title
            if let groupItem = item.shelfItem as? FTGroupItem, groupItem.shelfCollection != nil {
                accessoryImageView.isHidden = false
                var countString = String(format: NSLocalizedString("NItems", comment: "%d Items"), groupItem.childrens.count)
                if groupItem.childrens.count == 1 {
                    countString = NSLocalizedString("OneItem", comment: "1 Item")
                }
                self.subTitleLabel?.text = countString
                groupItem.fetchTopNotebooks(sortOrder: .byModifiedDate) { top3Children in
                    if !top3Children.isEmpty {
                        let firstGroupMember = top3Children[0]
                        self.readThumbnailFor(item: firstGroupMember, imageView: self.thumbnailImageView);
                    }
                }
            } else if let shelfItem = item.shelfItem {
                self.subTitleLabel?.text = item.shelfItem?.fileModificationDate.shelfShortStyleFormat()
                accessoryImageView.isHidden = true
                self.readThumbnailFor(item: shelfItem, imageView: thumbnailImageView)
            }
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
}
