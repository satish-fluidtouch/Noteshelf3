//
//  FTPasswordTableCell.swift
//  Noteshelf
//
//  Created by Prabhu on 7/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTPassWordNormalCell: UITableViewCell {
    @IBOutlet weak var leftLabel:FTStyledLabel!
    @IBOutlet weak var textFeild:UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textFeild.setDefaultStyle(.defaultStyle);
    }
    
    func configureTextField() {
        self.textFeild.setStyledPlaceHolder("Required".localized.lowercased(), style: .defaultStyle)
        self.textFeild.clearButtonMode = .never
        self.textFeild.textAlignment = .left
        self.textFeild.isSecureTextEntry = true
        self.textFeild.addCharacterSpacing(kernValue: -0.41)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

class FTPasswordHeaderView: UIView {
    
    @IBOutlet weak var lblEnablePassword: UILabel?
    @IBOutlet weak var enableSwitch: UISwitch?
    @IBOutlet weak var enablePasswordView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureHeader() {
        self.enablePasswordView?.layer.cornerRadius = 8.0
        self.lblEnablePassword?.text = "password.enablePassword".localized
        self.lblEnablePassword?.addCharacterSpacing(kernValue: -0.41)
    }
}

class FTPasswordFooterView: UIView {
    @IBOutlet weak var lblInfoMessage : UILabel?
    @IBOutlet weak var lblUseTouchID : UILabel?
    @IBOutlet weak var touchIDSwitch : UISwitch?
    @IBOutlet weak var biometricView: UIView!
    @IBOutlet weak var lockView: UIView!
    @IBOutlet weak var lockSwitch : UISwitch?
    @IBOutlet weak var lockTitleLabel : UILabel?
    @IBOutlet weak var optionsStackView : UIStackView?

    var canShowBiometricOption: Bool = true {
        didSet {
            self.updateBiometricView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateBiometricView()
    }
    
    private func updateBiometricView() {
        if self.canShowBiometricOption {
            self.biometricView.isHidden = false
            var newFrame = self.frame
            if let infoFrame = self.lockSwitch?.superview?.frame {
                newFrame.size.height = infoFrame.maxY + 80.0
            }
            self.frame = newFrame
        }
        else {
            self.biometricView.isHidden = true
            var newFrame = self.frame
            if let infoFrame = self.lblInfoMessage?.frame {
                newFrame.size.height = infoFrame.maxY + 128
            }
            self.frame = newFrame
        }
    }
}
