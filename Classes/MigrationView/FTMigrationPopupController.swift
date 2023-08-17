//
//  FTMigrationViewController.swift
//  Noteshelf
//
//  Created by Naidu on 12/9/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTMigrationPopupController: UIViewController {
     @IBOutlet weak var overlayView:UIView!
     @IBOutlet weak var centerContentView:UIView!
    
     @IBOutlet weak var indicatorView:FTIndicatorView!
     @IBOutlet weak var titleLabel:FTStyledLabel!
     @IBOutlet weak var messageLabel:FTStyledLabel!
     @IBOutlet weak var okButton:FTStyledButton!
     var indicatorFrame:CGRect!
     var sourceView:UIView! //TODO:: set oval frame as per source view
    
    /*
     Usage::
     
     let migrationController = FTMigrationPopupController.init(nibName: "FTMigrationPopupController", bundle: nil)
     migrationController.indicatorFrame=CGRect.init(x: 200, y: 20, width: 350, height: 50) //Oval Indicator Frame
     migrationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
     
     self.present(migrationController, animated: true) {
     
     }
    */
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel!.style=FTLabelStyle.defaultStyle.rawValue
        self.titleLabel!.text=NSLocalizedString("DataMigrationComplete", comment: "Data Migration Complete!")
        
        self.messageLabel!.style=FTLabelStyle.defaultStyle.rawValue
        let messageString:String=NSLocalizedString("DataMigrationCompleteMessage", comment: "Data Migration Complete!")
        let attributedString = NSMutableAttributedString.init(string: messageString, attributes: [NSAttributedString.Key.font:UIFont.appFont(for: .light, with: 16.0),NSAttributedString.Key.foregroundColor:UIColor.label])
        attributedString.setAttributes([NSAttributedString.Key.font:UIFont.appFont(for: .semibold, with: 16.0)], range: (messageString as NSString).range(of: "Noteshelf 1 Data"))
        self.messageLabel!.styledAttributedText=attributedString
        
        self.okButton.style=FTButtonStyle.style9.rawValue
        self.okButton.setTitle(NSLocalizedString("OK", comment: "OK"), for: UIControl.State.normal)
        
        self.indicatorView.ovalRect = self.indicatorFrame
        self.overlayView.alpha=0.0;
        self.centerContentView.layer.cornerRadius=10.0;
        self.centerContentView.layer.masksToBounds=true;
        self.centerContentView.layer.shadowOpacity = 0.1;
        self.centerContentView.layer.shadowRadius = 20;
        self.centerContentView.layer.shadowColor = UIColor.black.cgColor;
        self.centerContentView.layer.shadowOffset = CGSize.init(width: 0, height: 4);
        
        self.okButton.layer.cornerRadius=7.0;
    }
    
    @IBAction func btnOKClicked(_ sender:UIButton){
        self.indicatorView.manageVisibility(false)
        UIView.animate(withDuration: 0.5, animations: {
            self.overlayView.alpha=0.0;

        }) { (success) in
            self.dismiss(animated: true) {
                
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        self.indicatorView.manageVisibility(true)
        UIView.animate(withDuration: 0.5) {
            self.overlayView.alpha=0.3;
        }
        setScreenName("MigrationPopup", screenClass: String(describing: type(of: self)));
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.indicatorView.arrowHeight=self.centerContentView.frame.origin.y-20-self.indicatorFrame.size.height-self.indicatorFrame.origin.y //20=Padding at bottom of arrow
        self.indicatorView.refreshIndicators()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
