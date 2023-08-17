//
//  EditImageOptionBarViewController.swift
//  EditImage
//
//  Created by Matra on 28/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit
import FTCommon

protocol OptionBarDelegate: AnyObject {
    func didSelectOptionReset(_viewController : EditImageOptionBarViewController)
    func didSelectOptionCrop(_viewController : EditImageOptionBarViewController)
    func didSelectOptionUndo(_viewController : EditImageOptionBarViewController)
    func didSelectOptionRedo(_viewController : EditImageOptionBarViewController)
    func canUndo() -> Bool
    func canRedo() -> Bool
}

class EditImageOptionBarViewController: UIViewController {
    // Outlets
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var optionStackView: UIStackView!
    
    @IBOutlet weak var stackTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackLeadingConstraint: NSLayoutConstraint!
    // properties
    let minimumPadding : CGFloat = 20.0 // for small size iphone
    weak var delegate : OptionBarDelegate?
    var editMode : FTImageEditOperation = .erase{
        didSet{
            updateOptionsForEditMode()
        }
    }
    var canCrop : Bool = false{
        didSet{
            cropButton.isEnabled = canCrop
            
        }
    }
    var enableReset : Bool = false {
        didSet {
            resetButton.isEnabled = true
        }
    }
    
    class func addToViewController(viewController: UIViewController,  delegate : OptionBarDelegate , containerView: UIView) -> UIViewController{
        let optionBarController = UIStoryboard(name: "EditImage", bundle: nil).instantiateViewController(withIdentifier: "EditImageOptionBarViewController") as! EditImageOptionBarViewController
        optionBarController.view.frame = containerView.bounds
        optionBarController.delegate = delegate
        containerView.addSubview(optionBarController.view)
        viewController.addChild(optionBarController)
        return optionBarController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateOptionsForEditMode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cropButton.isEnabled = false
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        resetButton.isEnabled = false

//        cropButton.setTitle(NSLocalizedString("Apply", comment: "Apply").uppercased(), for: .normal)
//        if FTUtils.currentLanguage() == "en" {
//            undoButton.setTitle(NSLocalizedString("ButtonActionUndo", comment: "Undo").uppercased(), for: .normal)
//            redoButton.setTitle(NSLocalizedString("ButtonActionRedo", comment: "Redo").uppercased(), for: .normal)
//        }else{
//            undoButton.setImage(UIImage.init(named: "naviconUndo"), for: .normal)
//            redoButton.setImage(UIImage.init(named: "naviconRedo"), for: .normal)
//            undoButton.setImage(UIImage.init(named: "naviconUndoDark"), for: .disabled)
//            redoButton.setImage(UIImage.init(named: "naviconRedoDark"), for: .disabled)
//        }
//        resetButton.setTitle(NSLocalizedString("Reset", comment: "Reset").uppercased(), for: .normal)
        // Do any additional setup after loading the view.
    }
    
    func updateUndoRedo() {
        undoButton.isEnabled = self.delegate?.canUndo() ?? false
        redoButton.isEnabled = self.delegate?.canRedo() ?? false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateOptionsForEditMode() {
        if editMode == .erase {
            stackLeadingConstraint.constant = stackPaddingWithCrop(hasCrop: false)
            stackTrailingConstraint.constant = stackPaddingWithCrop(hasCrop: false)
            cropButton.isHidden = true
        }else{
            stackLeadingConstraint.constant = stackPaddingWithCrop(hasCrop: true)
            stackTrailingConstraint.constant = stackPaddingWithCrop(hasCrop: true)
            cropButton.isHidden = false
        }
    }
    
    func stackPaddingWithCrop(hasCrop: Bool) -> CGFloat{
        var numberOfComponent = 3
        if hasCrop { numberOfComponent = 4 }
        let buttonsWidth : CGFloat = CGFloat(56 * numberOfComponent) // 56 is fixed width of button (crop, reset, undo and redo)
        let width = self.view.bounds.width - buttonsWidth - 20
        var inBetweenPadding = width / CGFloat(numberOfComponent)
        if UIDevice.current.isIphone() {
            if inBetweenPadding > 35 { inBetweenPadding = 35} // 35 distance is as par designs
            
        } else {
            if inBetweenPadding > 110 { inBetweenPadding = 110} // 120 distance is as par designs for ipad
            
        }
        let totalInBetweenDistance = inBetweenPadding * CGFloat(numberOfComponent - 1)
        let requiredPadding = (width - totalInBetweenDistance ) / 2
        return requiredPadding
    }
    //MARK: - Actions
    
    @IBAction func undoClicked(_ sender: Any) {
        FTCLSLog("Image: Undo Tap")
        cropButton.isEnabled = false
        self.delegate?.didSelectOptionUndo(_viewController: self)
    }
    @IBAction func redoClicked(_ sender: Any) {
        FTCLSLog("Image: Redo Tap")
        cropButton.isEnabled = false
        self.delegate?.didSelectOptionRedo(_viewController: self)
    }
//    @IBAction func cropClicked(_ sender: Any) {
//        FTCLSLog("Image: Crop Tap")
//        undoButton.isEnabled = true
//        resetButton.isEnabled = true
//        self.delegate?.didSelectOptionCrop(_viewController: self)
//    }
    @IBAction func resetClicked(_ sender: Any) {
        FTCLSLog("Image: Reset Tap")
        cropButton.isEnabled = false
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        resetButton.isEnabled = false
        self.delegate?.didSelectOptionReset(_viewController: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
