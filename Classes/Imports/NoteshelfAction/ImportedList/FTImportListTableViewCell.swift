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
        // Initialization code
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

        let urlString = actionModel.fileURL
        if !urlString.isEmpty {
            let type = MIMETypeFileAtPath(urlString)
            var image = UIImage(named: "doc-icon-unknown")
            if (type?.contains("application/pdf"))! {
                image = UIImage(named: "iconPdf")
            } else if (type?.contains("audio"))! {
                image = UIImage(named: "welcome_popoverAudio")
            }
            else if (type?.contains("pdf"))! {
                image = UIImage(named: "iconImage")
            }
            else if (type?.contains(UTI_TYPE_NOTESHELF_BOOK))! {
                image = UIImage(named: "doc-icon-noteshelffile")
            }
            
            iconImageView?.image = image
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
}
