//
//  LoadingReusableView.swift
//  FTAddOperations
//
//  Created by Siva Kumar Reddy on 25/06/20.
//  Copyright © 2020 Siva Kumar Reddy. All rights reserved.
//

import UIKit

class FTLoadingReusableView: UICollectionReusableView {

   @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.color = UIColor.lightGray
    }
}
