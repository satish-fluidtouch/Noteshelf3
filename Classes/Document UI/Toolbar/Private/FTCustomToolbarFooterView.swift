//
//  FTCustomToolbarFooterView.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 15/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTCustomToolbarFooterViewProtocal {
    func navigateToContactUsPage()
}

class FTCustomToolbarFooterView : UITableViewHeaderFooterView {
    
    @IBOutlet weak var topBtn: UIButton!
    @IBOutlet weak var bgVIew: UIView!
    @IBOutlet weak var iconsBgView: UIView!
    @IBOutlet weak var ideaForShortcutLbl: UILabel!
    @IBOutlet weak var requestLbl: UILabel!
    
    var delegate : FTCustomToolbarFooterViewProtocal?
    
    func setUpUi() {
        bgVIew.layer.cornerRadius = 12
        iconsBgView.layer.cornerRadius = 8
        ideaForShortcutLbl.text = "customizeToolbar.ideaForShortcut".localized
        requestLbl.text = "customizeToolbar.requestForShortcut".localized
    }
    
    @IBAction func topBtnAction(_ sender: Any) {
        self.delegate?.navigateToContactUsPage()
    }
    
}
