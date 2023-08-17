//
//  FTColorPickerViewController.swift
//  Noteshelf
//
//  Created by Mahesh on 07/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol FTColorPickerDelegate: NSObjectProtocol {
    func didSelectColor(_ color: UIColor)
}

class FTColorPickerViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backBtn: FTStaticTextButton!
    weak var delegate: FTColorPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBackButton()
        configureSystemColorPicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.preferredContentSize = CGSize(width: 248, height: 308)
    }
    
    private func configureNavBackButton() {
        if(self.isRegularClass()) {
            self.backBtn.setImage(UIImage(named: "backDark"), for: .normal)
        } else {
            self.backBtn.setImage(UIImage(named: "closeDark"), for: .normal)
        }
    }
    
    private func configureSystemColorPicker() {
        let colorPickerController = UIColorPickerViewController()
        colorPickerController.supportsAlpha = false
        self.addChild(colorPickerController)
        colorPickerController.view.addFullConstraints(self.containerView)
        colorPickerController.didMove(toParent: self)
        colorPickerController.delegate = self
    }
}


extension FTColorPickerViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.delegate?.didSelectColor(viewController.selectedColor)
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        self.delegate?.didSelectColor(color)
    }
}
