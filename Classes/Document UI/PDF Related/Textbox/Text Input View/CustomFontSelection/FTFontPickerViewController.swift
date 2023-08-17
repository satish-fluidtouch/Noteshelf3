//
//  FTFontPickerViewController.swift
//  Noteshelf
//
//  Created by Narayana on 01/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTSystemFontPickerDelegate : AnyObject {
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor)
}

public class FTFontPickerViewController: UIViewController, UIFontPickerViewControllerDelegate {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    public weak var delegate : FTSystemFontPickerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLbl.text = "SELECT FONT"
        self.configureSystemFontPicker()
        if self.navigationController != nil {
            self.closeBtn.isHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            self.backBtn.isHidden = true
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func configureSystemFontPicker() {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true
        let fontPickerController = UIFontPickerViewController(configuration: configuration)
        self.addChild(fontPickerController)
        fontPickerController.view.addFullConstraints(self.containerView)
        fontPickerController.didMove(toParent: self)
        fontPickerController.delegate = self
    }
    
    public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        self.delegate?.didPickFontFromSystemFontPicker(self, selectedFontDescriptor: descriptor)
        self.backButtonTapped(nil)
    }
    
}
