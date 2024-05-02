//
//  FTFontPickerViewController.swift
//  Noteshelf
//
//  Created by Narayana on 01/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTSystemFontPickerDelegate : AnyObject {
    func didPickFontFromSystemFontPicker(_ viewController : FTFontPickerViewController?, selectedFontDescriptor: UIFontDescriptor, fontStyle: FTTextStyleItem)
    func isFontSelectionInProgress(value: Bool)
}

extension FTSystemFontPickerDelegate {
    func isFontSelectionInProgress(value: Bool) { }
}


public class FTFontPickerViewController: UIViewController, UIFontPickerViewControllerDelegate {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    public weak var delegate : FTSystemFontPickerDelegate?
    var textFontStyle: FTTextStyleItem?
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.isFontSelectionInProgress(value: false)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLbl.text = "texttoolbar.fontselectionTitle".localized
        self.titleLbl.font = .clearFaceFont(for: .medium, with: 20.0)
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
        guard let selectedFontDescriptor = viewController.selectedFontDescriptor else { return }
        if let fontFamily = selectedFontDescriptor.object(forKey: .family) as? String, let displayName = selectedFontDescriptor.object(forKey: .visibleName) as? String, let textFontStyle = self.textFontStyle  {
            if let _ = selectedFontDescriptor.object(forKey: .face) as? String, let fontName = selectedFontDescriptor.object(forKey: .name) as? String {
               textFontStyle.fontName = fontName
               textFontStyle.fontFamily = fontFamily
            } else {
               textFontStyle.fontName = displayName
               textFontStyle.fontFamily = fontFamily
            }
        }
        self.delegate?.didPickFontFromSystemFontPicker(self, selectedFontDescriptor: selectedFontDescriptor, fontStyle: self.textFontStyle ?? FTTextStyleItem())
        self.backButtonTapped(nil)
    }
    
}
