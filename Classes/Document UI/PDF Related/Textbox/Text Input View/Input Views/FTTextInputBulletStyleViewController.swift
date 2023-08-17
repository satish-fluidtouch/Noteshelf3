//
//  FTTextInoutBulletStyleViewController.swift
//  Noteshelf
//
//  Created by Amar on 20/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTTextInputBulletStyle : Int
{
    case styleOne
    case numbering
    case check
    case leftIndent
    case rightIndent
}

protocol FTTextInputBulletStyleDelegate : class {
    func textInputBulletStyle(_ viewController : FTTextInputBulletStyleViewController, didTapOnBulletStyle style : FTTextInputBulletStyle);
}

class FTTextInputBulletStyleViewController: UIViewController,FTTextInputValidationProtocol {

    fileprivate weak var delegate : FTTextInputBulletStyleDelegate?;
    
    @IBOutlet weak var bulletOneButton : UIButton?;
    @IBOutlet weak var bulletNumberButton : UIButton?;
    @IBOutlet weak var bulletCheckboxButton : UIButton?;
    @IBOutlet weak var compactPanelLeadingConstraint : NSLayoutConstraint!;
    @IBOutlet weak var compactPanelTrailingConstraint : NSLayoutConstraint!;

    class func viewController(_ delegate : FTTextInputBulletStyleDelegate) -> FTTextInputBulletStyleViewController
    {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        let controller = storyboard.instantiateViewController(withIdentifier: "FTTextInputBulletStyleView") as! FTTextInputBulletStyleViewController;
        controller.delegate = delegate;
        var frame = controller.view.frame;
        frame.size.height = textInputViewHeight;
        controller.view.frame = frame;
        return controller;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if(self.isIphoneX()){
            let safeAreaInsets = self.originalSafeAreaInsets()
            self.compactPanelLeadingConstraint.constant = safeAreaInsets.left;
            self.compactPanelTrailingConstraint.constant = safeAreaInsets.right;
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapOnBulletStyle1(_ sender : UIButton)
    {
        self.delegate?.textInputBulletStyle(self, didTapOnBulletStyle: .styleOne);
    }
    @IBAction func didTapOnBulletNumbering(_ sender : UIButton)
    {
        self.delegate?.textInputBulletStyle(self, didTapOnBulletStyle: .numbering);
    }
    @IBAction func didTapOnBulletCheck(_ sender : UIButton)
    {
        self.delegate?.textInputBulletStyle(self, didTapOnBulletStyle: .check);
    }
    @IBAction func didTapOnLeftIndent(_ sender : UIButton)
    {
        self.delegate?.textInputBulletStyle(self, didTapOnBulletStyle: .leftIndent);
    }
    
    @IBAction func didTapOnRightIndent(_ sender : UIButton)
    {
        self.delegate?.textInputBulletStyle(self, didTapOnBulletStyle: .rightIndent);
    }
    
    func validateKeyboard(attributes : [NSAttributedString.Key:Any],scale : CGFloat) {
        self.bulletOneButton?.backgroundColor = UIColor.clear;
        self.bulletNumberButton?.backgroundColor = UIColor.clear;
        self.bulletCheckboxButton?.backgroundColor = UIColor.clear;

        let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as! NSParagraphStyle;
        let bulletList = paragraphStyle.bulletType(withScale: Float(scale));
        switch bulletList {
        case .one:
            self.bulletOneButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        case .numbers:
            self.bulletNumberButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        case .checkBox:
            self.bulletCheckboxButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        default:
            break;
        }
    }
}
