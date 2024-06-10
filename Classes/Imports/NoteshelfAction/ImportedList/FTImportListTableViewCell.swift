//
//  FTImportListTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 19/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

class FTImportListTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView:UIImageView?
    @IBOutlet weak var lblFileName:UILabel?
    @IBOutlet weak var categoryNameLbl: UILabel?
    @IBOutlet weak var spinnerImage:FTSpinnerView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.spinnerImage?.image = UIImage.init(named: "spinner")
        iconImageView?.addShadow(color: .black.withAlphaComponent(0.2), offset: CGSize(width: 0, height: 4), opacity: 1, shadowRadius: 4)
    }

    func configureCell(_ actionModel: FTSharedAction) {
        lblFileName?.text = actionModel.fileName;
        let docHash = actionModel.documentUrlHash;
        
        var attrs : [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.appFont(for: .regular, with: 15)
                                                      ,NSAttributedString.Key.foregroundColor : UIColor.appColor(.black50)
        ];
        var stringToSet = NSMutableAttributedString();
        if !docHash.isEmpty, let urlString = docHash.removingPercentEncoding {
            
            stringToSet = NSMutableAttributedString(string: NSLocalizedString("importedTo", comment: "ImportTo"), attributes: attrs)
            stringToSet.append(NSAttributedString(string: " "))
            let url = URL(fileURLWithPath: urlString)
            let categoryName = url.deletingLastPathComponent().displayRelativePathWRTCollection();
            attrs[.foregroundColor] = UIColor.appColor(.accent);
            let categoryString = NSAttributedString(string: categoryName,
                                                         attributes: attrs
            );
            stringToSet.append(categoryString);
        }
        else if(actionModel.importStatus == .downloading) {
            stringToSet = NSMutableAttributedString(string: NSLocalizedString("Downloading", comment: "Downloading"),
                                                    attributes: attrs)
        }
        else if(actionModel.importStatus == .importFailed || actionModel.importStatus == .downloadFailed) {
            stringToSet = NSMutableAttributedString(string: NSLocalizedString("FailedToImport", comment: "Failed To Import"),
                                                    attributes: attrs);
        }
        categoryNameLbl?.attributedText = stringToSet;
        let relativePath = URL(fileURLWithPath: docHash).relativePathWRTCollection()
        if let iconImageView {
            FTNoteshelfDocumentProvider.shared.getShelfItemDetails(relativePath: relativePath, igrnoreIfNotDownloaded: true) { shelfItemColleciton, groupItem, shelfItem in
                if let shelfItem {
                    self.readThumbnailFor(item: shelfItem, imageView: iconImageView)
                } else {
                    iconImageView.image = UIImage(named: "doc-icon-unknown");
                }
            }
        }
        
        self.spinnerImage?.image = UIImage(named: actionModel.importStatus.statusImage());
        if(actionModel.importStatus == .importSuccess) {
            self.spinnerImage?.stopAnimation()
        }
        else if(actionModel.importStatus == .importFailed || actionModel.importStatus == .downloadFailed) {
            self.spinnerImage?.stopAnimation()
        }
        else {
            self.spinnerImage?.startAnimation()
        }
    }
    
    fileprivate func readThumbnailFor(item : FTShelfItemProtocol,imageView : UIImageView) {
        weak var weakimageView = imageView;
        var token : String?;
        token = FTURLReadThumbnailManager.sharedInstance.thumnailForItem(item, onCompletion: { (image, imageToken) in
            if(image != nil && token == imageToken) {
                weakimageView?.image = image;
            } else {
                weakimageView?.image = UIImage(named: "doc-icon-unknown");
            }
        });
    }
}
