//
//  FTStoreHeader.swift
//  TempletesStore
//
//  Created by Siva on 21/02/23.
//

import UIKit
import FTStyles

class FTStoreHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundView = UIView(frame: self.bounds)
        self.backgroundView?.backgroundColor = UIColor.appColor(.secondaryBG)
        self.seeAllButton.configuration?.title = "templatesStore.seeAll".localized
    }
    
}
