//
//  FTRecentsHeaderView.swift
//  Noteshelf
//
//  Created by Akshay on 11/10/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRecentsHeaderView: UIView {

    @IBOutlet var titleLabel: FTStyledLabel?
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.style = 3
    }
    
    class func viewfromNib() -> FTRecentsHeaderView? {
        let view = Bundle.main.loadNibNamed(String(describing: FTRecentsHeaderView.self), owner:nil , options: nil)?.first as? FTRecentsHeaderView
        return view
        
    }

}
