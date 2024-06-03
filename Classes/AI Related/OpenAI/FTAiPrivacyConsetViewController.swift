//
//  FTAiPrivacyConsetViewController.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 03/06/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTAiPrivacyConsetViewController: UIViewController {

    @IBOutlet weak var bgView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bgView?.addShadow(CGSize(width: 0, height: 0), color: UIColor.appColor(.black20), opacity: 0.24 ,radius: 16.0)
    }
    
}
