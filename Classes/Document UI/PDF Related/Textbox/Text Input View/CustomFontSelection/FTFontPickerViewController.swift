//
//  FTFontPickerViewController.swift
//  Noteshelf
//
//  Created by Narayana on 01/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

public protocol FTSystemFontPickerDelegate : AnyObject {
    func didPickFontFromSystemFontPicker(selectedFontDescriptor: UIFontDescriptor, fontStyle: FTTextStyleItem)
    func isFontSelectionInProgress(value: Bool)
}

extension FTSystemFontPickerDelegate {
    func isFontSelectionInProgress(value: Bool) { }
}

class FTFontPickerViewController: UIFontPickerViewController, UIFontPickerViewControllerDelegate {
    public weak var fontPickerdelegate : FTSystemFontPickerDelegate?
    var textFontStyle: FTTextStyleItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backButtonDisplayMode = .minimal
        self.delegate = self
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.fontPickerdelegate?.isFontSelectionInProgress(value: false)
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
        self.fontPickerdelegate?.didPickFontFromSystemFontPicker(selectedFontDescriptor: selectedFontDescriptor, fontStyle: self.textFontStyle ?? FTTextStyleItem())
        self.backButtonTapped(nil)
    }
}
