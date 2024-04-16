//
//  FTCustomToolbarFooterView.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 15/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol FTCustomToolbarFooterViewProtocal:AnyObject {
    func navigateToContactUsPage()
}

class FTCustomToolbarFooterView : UITableViewHeaderFooterView {
    
    @IBOutlet weak private var topBtn: UIButton!
    @IBOutlet weak private var bgVIew: UIView!
    @IBOutlet weak private var iconsBgView: UIView!
    @IBOutlet weak private var ideaForShortcutLbl: UILabel!
    @IBOutlet weak private var requestLbl: UILabel!
    
   weak var delegate : FTCustomToolbarFooterViewProtocal?
    
    func setUpUi() {
        ideaForShortcutLbl.text = "customizeToolbar.ideaForShortcut".localized
        requestLbl.text = "customizeToolbar.requestForShortcut".localized
    }
    
    @IBAction func topBtnAction(_ sender: Any) {
        self.delegate?.navigateToContactUsPage()
    }
    
}
