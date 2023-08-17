//
//  EditImageToolBarViewController.swift
//  EditImage
//
//  Created by Matra on 11/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import UIKit

protocol ToolBarDelegate: AnyObject {
    func didSelectCancel(_viewController : EditImageToolBarViewController)
    func didSelectCrop(_viewController : EditImageToolBarViewController)
    func didSelectErase(_viewController : EditImageToolBarViewController)
    func didSelectLasso(_viewController : EditImageToolBarViewController)
    func didSelectDone(_viewController : EditImageToolBarViewController)
}

class EditImageToolBarViewController: UIViewController {

    weak var delegate: ToolBarDelegate?
    let selectedColor = UIColor.white.withAlphaComponent(0.1)
    var editMode: FTImageEditOperation = .crop {
        didSet{
            configureButtonsForMode()
        }
    }
    
    //MARK:- Outlets
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cropButton: UIButton?
    @IBOutlet weak var eraseButton: UIButton?
    @IBOutlet weak var lassoButton: UIButton?
    @IBOutlet weak var doneButton: UIButton!
    
    class func addToViewController(viewController: UIViewController,  delegate : ToolBarDelegate , containerView: UIView) -> UIViewController{
        let toolBarController = UIStoryboard(name: "EditImage", bundle: nil).instantiateViewController(withIdentifier: "EditImageToolBarViewController") as! EditImageToolBarViewController
        toolBarController.view.frame = containerView.bounds
        toolBarController.delegate = delegate
        containerView.addSubview(toolBarController.view)
        viewController.addChild(toolBarController)
        return toolBarController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
        doneButton.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
        self.cropButton?.layer.cornerRadius = 6
        self.eraseButton?.layer.cornerRadius = 6
        self.lassoButton?.layer.cornerRadius = 6
        configureButtonsForMode()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureButtonsForMode() {
        switch editMode {
        case .crop:
            cropButton?.backgroundColor = selectedColor
            eraseButton?.backgroundColor = .clear
            lassoButton?.backgroundColor = .clear
            cropButton?.isSelected = true
            eraseButton?.isSelected = false
            lassoButton?.isSelected = false
        case .erase:
            eraseButton?.backgroundColor = selectedColor
            cropButton?.backgroundColor = .clear
            lassoButton?.backgroundColor = .clear
            cropButton?.isSelected = false
            eraseButton?.isSelected = true
            lassoButton?.isSelected = false
        case .lasso:
            lassoButton?.backgroundColor = selectedColor
            eraseButton?.backgroundColor = .clear
            cropButton?.backgroundColor = .clear
            cropButton?.isSelected = false
            eraseButton?.isSelected = false
            lassoButton?.isSelected = true
        default:
            break
        }
    }

    //MARK: - Actions
    
    @IBAction func cancelClicked(_ sender: Any) {
        FTCLSLog("Image: Edit Cancel")
        if self.delegate != nil {
            self.delegate?.didSelectCancel(_viewController: self)
        }
    }
    @IBAction func cropClicked(_ sender: Any) {
        FTCLSLog("Image: Edit Crop")
        self.editMode = .crop
        if self.delegate != nil {
            self.delegate?.didSelectCrop(_viewController: self)
        }
    }
    @IBAction func eraseClicked(_ sender: Any) {
        FTCLSLog("Image: Edit Erase")
        self.editMode = .erase
        if self.delegate != nil {
            self.delegate?.didSelectErase(_viewController: self)
        }
    }
    @IBAction func lassoClicked(_ sender: Any) {
        FTCLSLog("Image: Edit Lasso")
        self.editMode = .lasso
        if self.delegate != nil {
            self.delegate?.didSelectLasso(_viewController: self)
        }
    }
    @IBAction func doneClicked(_ sender: Any) {
        FTCLSLog("Image: Edit Done")
        if self.delegate != nil {
            self.delegate?.didSelectDone(_viewController: self)
        }
    }
    
    
}
